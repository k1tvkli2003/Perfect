import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// Content-driven size classes for Perfect surfaces.
///
/// The thresholds describe when the layout can hold useful content, rather
/// than mirroring a particular phone, tablet, or monitor resolution.
enum PerfectWindowClass { compact, medium, expanded }

/// The small, repeatable transition vocabulary used across Perfect!.
///
/// These are continuity patterns, not decorative animation presets. A caller
/// chooses the relationship between two states and the component supplies the
/// timing, curve and reduced-motion fallback.
enum PerfectTransitionKind {
  fade,
  fadeScale,
  sharedAxisHorizontal,
  sharedAxisVertical,
}

enum PerfectGlassStrength { soft, strong }

enum PerfectInteractiveTone { neutral, primary, secondary, tertiary, danger }

/// A mixed, constraint-driven geometry model.
///
/// Fixed values below are semantic bounds (touch target, readable line length,
/// rhythm and pane minimums). Flow and distribution still derive from the
/// actual parent constraints, safe area, orientation and text scale.
@immutable
class PerfectResponsiveGeometry {
  const PerfectResponsiveGeometry._({
    required this.windowClass,
    required this.availableSize,
    required this.textScale,
    required this.horizontalGutter,
    required this.verticalGutter,
    required this.contentWidth,
    required this.isShortLandscape,
  });

  /// Two comfortable 280dp content tracks, one 24dp gap and outer rhythm.
  static const mediumContentThreshold = 680.0;

  /// Three useful planner tracks or a primary pane plus an inspector.
  static const expandedContentThreshold = 1040.0;

  /// Semantic bounds, not target-device coordinates.
  static const minHitTarget = 48.0;
  static const minReadablePane = 280.0;
  static const maxReadableLine = 720.0;
  static const maxWorkspaceWidth = 1440.0;
  static const minGutter = PerfectSpace.md;
  static const maxGutter = PerfectSpace.xxl;

  final PerfectWindowClass windowClass;
  final Size availableSize;
  final double textScale;
  final double horizontalGutter;
  final double verticalGutter;
  final double contentWidth;
  final bool isShortLandscape;

  bool get isCompact => windowClass == PerfectWindowClass.compact;
  bool get isMedium => windowClass == PerfectWindowClass.medium;
  bool get isExpanded => windowClass == PerfectWindowClass.expanded;
  bool get prefersDialog => !isCompact;

  /// A bounded sheet ratio leaves route context visible without starving a
  /// short landscape editor.
  double get editorSheetHeightFactor => isShortLandscape ? .98 : .94;

  double get editorMaxWidth => math.min(maxReadableLine, contentWidth);

  double editorMaxHeight(double requestedMax) {
    final usable = math.max(
      minHitTarget * 4,
      availableSize.height - (verticalGutter * 2),
    );
    return math.min(requestedMax, usable);
  }

  /// Resolves a fractional pane inside semantic min/max bounds.
  ///
  /// If the container is smaller than the requested minimum, it yields the
  /// available width rather than overflowing. This is intentionally not a raw
  /// percentage contract.
  double boundedPaneWidth({
    required double fraction,
    double minWidth = minReadablePane,
    double maxWidth = maxReadableLine,
  }) {
    assert(fraction > 0 && fraction <= 1);
    assert(minWidth > 0 && maxWidth >= minWidth);
    if (contentWidth <= minWidth) return contentWidth;
    return (contentWidth * fraction).clamp(minWidth, maxWidth).toDouble();
  }

  /// Calculates useful tracks from an intrinsic minimum and a semantic gap.
  int columnsFor({
    required double minItemWidth,
    double gap = PerfectSpace.md,
    int maxColumns = 4,
  }) {
    assert(minItemWidth > 0);
    assert(gap >= 0);
    assert(maxColumns > 0);
    final count = ((contentWidth + gap) / (minItemWidth + gap)).floor();
    return count.clamp(1, maxColumns);
  }

  factory PerfectResponsiveGeometry.fromConstraints(
    BoxConstraints constraints, {
    required Size fallbackSize,
    required double textScale,
  }) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : fallbackSize.width;
    final height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : fallbackSize.height;
    return PerfectResponsiveGeometry.fromSize(
      Size(
        math.max(0, width.isFinite ? width : fallbackSize.width),
        math.max(0, height.isFinite ? height : fallbackSize.height),
      ),
      textScale: textScale,
    );
  }

  factory PerfectResponsiveGeometry.fromSize(
    Size availableSize, {
    required double textScale,
  }) {
    final safeScale = textScale.clamp(1.0, 2.0);
    final isShortLandscape =
        availableSize.width > availableSize.height &&
        availableSize.height < 560;

    // Larger text consumes track width. Shift the composition threshold
    // gradually instead of shrinking type or enforcing a device label.
    final scaleAllowance = 1 + ((safeScale - 1) * .18);
    final effectiveMedium = mediumContentThreshold * scaleAllowance;
    final effectiveExpanded = expandedContentThreshold * scaleAllowance;
    final windowClass = switch (availableSize.width) {
      final width when width >= effectiveExpanded =>
        PerfectWindowClass.expanded,
      final width when width >= effectiveMedium => PerfectWindowClass.medium,
      _ => PerfectWindowClass.compact,
    };

    final normalizedWidth = ((availableSize.width - 320) / (1280 - 320)).clamp(
      0.0,
      1.0,
    );
    final horizontalGutter =
        minGutter + ((maxGutter - minGutter) * normalizedWidth);
    final verticalGutter = isShortLandscape
        ? PerfectSpace.sm
        : switch (windowClass) {
            PerfectWindowClass.compact => PerfectSpace.md,
            PerfectWindowClass.medium => PerfectSpace.lg,
            PerfectWindowClass.expanded => PerfectSpace.xl,
          };
    final contentWidth = math.min(
      maxWorkspaceWidth,
      math.max(0.0, availableSize.width - (horizontalGutter * 2)),
    );

    return PerfectResponsiveGeometry._(
      windowClass: windowClass,
      availableSize: availableSize,
      textScale: safeScale,
      horizontalGutter: horizontalGutter,
      verticalGutter: verticalGutter,
      contentWidth: contentWidth,
      isShortLandscape: isShortLandscape,
    );
  }
}

typedef PerfectGeometryWidgetBuilder =
    Widget Function(BuildContext context, PerfectResponsiveGeometry geometry);

/// Makes constraint-derived geometry available without coupling a component to
/// global screen coordinates.
class PerfectGeometryBuilder extends StatelessWidget {
  const PerfectGeometryBuilder({super.key, required this.builder});

  final PerfectGeometryWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fallbackSize = MediaQuery.sizeOf(context);
      final textScaler = MediaQuery.textScalerOf(context);
      final geometry = PerfectResponsiveGeometry.fromConstraints(
        constraints,
        fallbackSize: fallbackSize,
        // Query at the body-text size so nonlinear platform scaling remains
        // representative of the content that drives the layout.
        textScale: textScaler.scale(16) / 16,
      );
      return builder(context, geometry);
    },
  );
}

/// A single transition primitive for page sections, wizard steps and panels.
///
/// Replacing scattered AnimatedSwitcher transition builders with this widget
/// keeps duration, easing, direction, and accessibility behavior consistent.
class PerfectMotionSwitcher extends StatelessWidget {
  const PerfectMotionSwitcher({
    super.key,
    required this.child,
    this.kind = PerfectTransitionKind.fadeScale,
    this.direction = 1,
    this.duration = PerfectMotion.emphasized,
    this.reverseDuration = PerfectMotion.standard,
    this.alignment = Alignment.center,
    this.layoutBuilder,
  }) : assert(direction != 0);

  final Widget child;
  final PerfectTransitionKind kind;
  final int direction;
  final Duration duration;
  final Duration reverseDuration;
  final Alignment alignment;
  final AnimatedSwitcherLayoutBuilder? layoutBuilder;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = PerfectMotion.reduced(context);
    final transitionDuration = PerfectMotion.responsive(context, duration);
    final outgoingDuration = PerfectMotion.responsive(context, reverseDuration);

    return AnimatedSwitcher(
      duration: transitionDuration,
      reverseDuration: outgoingDuration,
      switchInCurve: PerfectMotion.enter,
      switchOutCurve: PerfectMotion.exit,
      layoutBuilder:
          layoutBuilder ??
          (currentChild, previousChildren) => Stack(
            alignment: alignment,
            children: <Widget>[...previousChildren, ?currentChild],
          ),
      transitionBuilder: (transitionChild, animation) {
        if (reduceMotion) return transitionChild;
        final fade = FadeTransition(opacity: animation, child: transitionChild);
        return switch (kind) {
          PerfectTransitionKind.fade => fade,
          PerfectTransitionKind.fadeScale => ScaleTransition(
            alignment: alignment,
            scale: Tween<double>(begin: .962, end: 1).animate(animation),
            child: fade,
          ),
          PerfectTransitionKind.sharedAxisHorizontal => SlideTransition(
            position: Tween<Offset>(
              begin: Offset(.042 * direction, 0),
              end: Offset.zero,
            ).animate(animation),
            child: fade,
          ),
          PerfectTransitionKind.sharedAxisVertical => SlideTransition(
            position: Tween<Offset>(
              // Keep route continuity perceptible without hauling the entire
              // workspace through a large percentage of the viewport. Local
              // headings can carry a stronger staged rise while the page
              // surface itself moves only a restrained optical distance.
              begin: const Offset(0, .018),
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              alignment: Alignment.topCenter,
              scale: Tween<double>(begin: .994, end: 1).animate(animation),
              child: fade,
            ),
          ),
        };
      },
      child: child,
    );
  }
}

/// A short staged rise for the distinct regions of a freshly selected page.
///
/// It deliberately moves only opacity, scale and a small vertical offset. A
/// page's keyed boundary mounts this once on entry, so sync updates, scrolls,
/// and text edits never replay the choreography.
class PerfectStagedEntrance extends StatefulWidget {
  const PerfectStagedEntrance({
    super.key,
    required this.child,
    this.order = 0,
    this.duration = PerfectMotion.emphasized,
    this.rise = 16,
    this.scaleBegin = .985,
  }) : assert(order >= 0),
       assert(rise >= 0),
       assert(scaleBegin > 0 && scaleBegin <= 1);

  final Widget child;
  final int order;
  final Duration duration;
  final double rise;
  final double scaleBegin;

  @override
  State<PerfectStagedEntrance> createState() => _PerfectStagedEntranceState();
}

class _PerfectStagedEntranceState extends State<PerfectStagedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PerfectMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    final delay = Duration(milliseconds: widget.order * 56);
    Future<void>.delayed(delay, () {
      if (mounted && !_controller.isAnimating && _controller.value < 1) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PerfectMotion.reduced(context)) return widget.child;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: PerfectMotion.modalEnter,
      reverseCurve: PerfectMotion.exit,
    );
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curve.value) * widget.rise),
          child: Transform.scale(
            alignment: Alignment.topCenter,
            scale: widget.scaleBegin + ((1 - widget.scaleBegin) * curve.value),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// One composited glass layer for floating navigation, capture and AI docks.
///
/// The high-contrast fallback is opaque and blur-free. This preserves the
/// hierarchy without sacrificing edge contrast or spending GPU work on an
/// effect the user explicitly asked to strengthen.
class PerfectGlassSurface extends StatelessWidget {
  const PerfectGlassSurface({
    super.key,
    required this.child,
    this.surfaceKey,
    this.strength = PerfectGlassStrength.soft,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(PerfectRadius.panel),
    ),
    this.padding = EdgeInsets.zero,
    this.tint,
    this.borderColor,
    this.blur,
    this.castShadow = true,
    this.enableBlur = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final Key? surfaceKey;
  final PerfectGlassStrength strength;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final Color? borderColor;
  final double? blur;
  final bool castShadow;
  final bool enableBlur;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final tokens = PerfectSurfaceTheme.of(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));
    final strong = strength == PerfectGlassStrength.strong;
    final resolvedTint =
        tint ??
        (highContrast
            ? tokens.surfaceRaised
            : strong
            ? tokens.glassStrong
            : tokens.glass);
    final resolvedBlur = highContrast || !enableBlur
        ? 0.0
        : blur ?? (strong ? tokens.glassBlurStrong : tokens.glassBlur);
    final decorated = DecoratedBox(
      key: surfaceKey,
      decoration: BoxDecoration(
        color: resolvedTint,
        borderRadius: resolvedRadius,
        border: Border.all(
          color:
              borderColor ??
              (highContrast ? tokens.strokeStrong : tokens.stroke),
          width: highContrast ? 2 : 1,
        ),
        boxShadow: castShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: tokens.ambientShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: tokens.keyShadow,
                  blurRadius: strong ? 34 : 24,
                  offset: Offset(0, strong ? 14 : 9),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Padding(padding: padding, child: child),
    );
    final filtered = resolvedBlur == 0
        ? decorated
        : BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: resolvedBlur,
              sigmaY: resolvedBlur,
            ),
            child: decorated,
          );
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: resolvedRadius,
        clipBehavior: clipBehavior,
        child: filtered,
      ),
    );
  }
}

/// A stable-geometry interactive surface for mouse, keyboard and touch.
///
/// Hover, focus and press alter paint/transform only. Padding, border width and
/// hit target stay constant, so state changes never push surrounding content.
class PerfectInteractiveSurface extends StatefulWidget {
  const PerfectInteractiveSurface({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PerfectSpace.md,
      vertical: PerfectSpace.sm,
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.backgroundColor,
    this.foregroundColor,
    this.tone = PerfectInteractiveTone.neutral,
    this.selected = false,
    this.elevated = true,
    this.liftOnHover = true,
    this.pressScale = .985,
    this.autofocus = false,
    this.focusNode,
    this.statesController,
    this.onHoverChanged,
    this.onFocusChanged,
    this.onPressedChanged,
  }) : assert(pressScale > 0 && pressScale <= 1);

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PerfectInteractiveTone tone;
  final bool selected;
  final bool elevated;
  final bool liftOnHover;
  final double pressScale;
  final bool autofocus;
  final FocusNode? focusNode;
  final WidgetStatesController? statesController;
  final ValueChanged<bool>? onHoverChanged;
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<bool>? onPressedChanged;

  @override
  State<PerfectInteractiveSurface> createState() =>
      _PerfectInteractiveSurfaceState();
}

class _PerfectInteractiveSurfaceState extends State<PerfectInteractiveSurface> {
  late WidgetStatesController _statesController;
  late bool _ownsStatesController;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  void initState() {
    super.initState();
    _attachStatesController(widget.statesController);
  }

  @override
  void didUpdateWidget(covariant PerfectInteractiveSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      if (_ownsStatesController) _statesController.dispose();
      _attachStatesController(widget.statesController);
    }
    _statesController.update(WidgetState.disabled, !_enabled);
    _statesController.update(WidgetState.selected, widget.selected);
  }

  void _attachStatesController(WidgetStatesController? external) {
    _ownsStatesController = external == null;
    _statesController = external ?? WidgetStatesController();
    _statesController.update(WidgetState.disabled, !_enabled);
    _statesController.update(WidgetState.selected, widget.selected);
  }

  @override
  void dispose() {
    if (_ownsStatesController) _statesController.dispose();
    super.dispose();
  }

  void _update(WidgetState state, bool active) {
    if (!mounted) return;
    _statesController.update(state, active);
    switch (state) {
      case WidgetState.hovered:
        widget.onHoverChanged?.call(active);
      case WidgetState.focused:
        widget.onFocusChanged?.call(active);
      case WidgetState.pressed:
        widget.onPressedChanged?.call(active);
      default:
        break;
    }
  }

  Color _toneContainer(ColorScheme scheme) => switch (widget.tone) {
    PerfectInteractiveTone.neutral => scheme.surfaceContainerHigh,
    PerfectInteractiveTone.primary => scheme.primaryContainer,
    PerfectInteractiveTone.secondary => scheme.secondaryContainer,
    PerfectInteractiveTone.tertiary => scheme.tertiaryContainer,
    PerfectInteractiveTone.danger => scheme.errorContainer,
  };

  Color _toneStroke(ColorScheme scheme) => switch (widget.tone) {
    PerfectInteractiveTone.neutral => scheme.outline,
    PerfectInteractiveTone.primary => scheme.primary,
    PerfectInteractiveTone.secondary => scheme.secondary,
    PerfectInteractiveTone.tertiary => scheme.tertiary,
    PerfectInteractiveTone.danger => scheme.error,
  };

  Color _toneForeground(ColorScheme scheme) => switch (widget.tone) {
    PerfectInteractiveTone.neutral => scheme.onSurface,
    PerfectInteractiveTone.primary => scheme.onPrimaryContainer,
    PerfectInteractiveTone.secondary => scheme.onSecondaryContainer,
    PerfectInteractiveTone.tertiary => scheme.onTertiaryContainer,
    PerfectInteractiveTone.danger => scheme.onErrorContainer,
  };

  @override
  Widget build(BuildContext context) {
    final interactive = ListenableBuilder(
      listenable: _statesController,
      builder: (context, child) {
        final states = _statesController.value;
        final scheme = Theme.of(context).colorScheme;
        final tokens = PerfectSurfaceTheme.of(context);
        final highContrast = MediaQuery.highContrastOf(context);
        final disabled = states.contains(WidgetState.disabled);
        final selected = states.contains(WidgetState.selected);
        final hovered = states.contains(WidgetState.hovered);
        final focused = states.contains(WidgetState.focused);
        final pressed = states.contains(WidgetState.pressed);
        final duration = PerfectMotion.responsive(
          context,
          pressed ? PerfectMotion.micro : PerfectMotion.quick,
        );

        final base = widget.backgroundColor ?? tokens.surface;
        var targetColor = selected ? _toneContainer(scheme) : base;
        if (disabled) {
          targetColor = Color.lerp(
            targetColor,
            scheme.surfaceContainerHighest,
            .56,
          )!;
        } else if (pressed) {
          targetColor = Color.alphaBlend(tokens.pressedLayer, targetColor);
        } else if (focused) {
          targetColor = Color.alphaBlend(tokens.focusLayer, targetColor);
        } else if (hovered) {
          targetColor = Color.alphaBlend(tokens.hoverLayer, targetColor);
        }
        final borderColor = focused
            ? tokens.focusRing
            : selected
            ? _toneStroke(scheme).withValues(alpha: .72)
            : highContrast
            ? tokens.strokeStrong
            : tokens.stroke;
        final targetForeground = disabled
            ? scheme.onSurface.withValues(alpha: tokens.disabledOpacity)
            : widget.foregroundColor ??
                  (selected ? _toneForeground(scheme) : scheme.onSurface);
        final scale = PerfectMotion.responsiveScale(
          context,
          pressed ? widget.pressScale : 1,
        );
        final lift = PerfectMotion.responsiveOffset(
          context,
          Offset(
            0,
            pressed
                ? .75
                : hovered && widget.liftOnHover && _enabled
                ? -1
                : 0,
          ),
        );
        final shadows = <BoxShadow>[
          if (focused)
            BoxShadow(
              color: tokens.focusRing.withValues(
                alpha: highContrast ? .72 : .26,
              ),
              blurRadius: highContrast ? 0 : 1,
              spreadRadius: highContrast ? 2 : 3,
            ),
          if (widget.elevated && hovered && !pressed && !disabled) ...[
            BoxShadow(
              color: tokens.ambientShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: tokens.keyShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ];

        return TweenAnimationBuilder<_PerfectInteractiveTransform>(
          key: const ValueKey<String>('perfect-interaction-scale'),
          duration: duration,
          curve: PerfectMotion.productive,
          tween: _PerfectInteractiveTransformTween(
            end: _PerfectInteractiveTransform(scale: scale, offset: lift),
          ),
          builder: (context, value, child) => Transform.scale(
            scale: value.scale,
            alignment: Alignment.center,
            child: FractionalTranslation(
              // A tiny optical lift, expressed against the semantic control
              // target so it does not need a second transform/clock.
              translation:
                  value.offset / PerfectResponsiveGeometry.minHitTarget,
              child: child,
            ),
          ),
          child: AnimatedContainer(
            key: const ValueKey<String>('perfect-interaction-surface'),
            duration: duration,
            curve: PerfectMotion.productive,
            constraints: const BoxConstraints(
              minHeight: PerfectResponsiveGeometry.minHitTarget,
              minWidth: PerfectResponsiveGeometry.minHitTarget,
            ),
            decoration: BoxDecoration(
              color: targetColor,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: borderColor,
                width: highContrast ? 2 : 1.5,
              ),
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                autofocus: widget.autofocus,
                canRequestFocus: _enabled,
                focusNode: widget.focusNode,
                borderRadius: widget.borderRadius,
                mouseCursor: _enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                enableFeedback: true,
                hoverDuration: duration,
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                onHover: (value) => _update(WidgetState.hovered, value),
                onFocusChange: (value) => _update(WidgetState.focused, value),
                onHighlightChanged: (value) =>
                    _update(WidgetState.pressed, value),
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: PerfectMotion.productive,
                  style: DefaultTextStyle.of(
                    context,
                  ).style.copyWith(color: targetForeground),
                  child: IconTheme(
                    data: IconTheme.of(
                      context,
                    ).copyWith(color: targetForeground),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final semantic = Semantics(
      label: widget.semanticLabel,
      button: _enabled,
      enabled: _enabled,
      focusable: _enabled,
      child: interactive,
    );
    final tooltip = widget.tooltip;
    return tooltip == null || tooltip.isEmpty
        ? semantic
        : Tooltip(message: tooltip, child: semantic);
  }
}

@immutable
class _PerfectInteractiveTransform {
  const _PerfectInteractiveTransform({
    required this.scale,
    required this.offset,
  });

  final double scale;
  final Offset offset;

  static _PerfectInteractiveTransform lerp(
    _PerfectInteractiveTransform a,
    _PerfectInteractiveTransform b,
    double t,
  ) => _PerfectInteractiveTransform(
    scale: a.scale + ((b.scale - a.scale) * t),
    offset: Offset.lerp(a.offset, b.offset, t)!,
  );
}

class _PerfectInteractiveTransformTween
    extends Tween<_PerfectInteractiveTransform> {
  _PerfectInteractiveTransformTween({super.end});

  @override
  _PerfectInteractiveTransform lerp(
    double t,
  ) => _PerfectInteractiveTransform.lerp(
    begin ?? const _PerfectInteractiveTransform(scale: 1, offset: Offset.zero),
    end ?? const _PerfectInteractiveTransform(scale: 1, offset: Offset.zero),
    t,
  );
}
