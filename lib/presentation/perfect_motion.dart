import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:perfect/presentation/perfect_theme.dart';

/// Content-driven size classes for Perfect surfaces.
///
/// The thresholds describe when the layout can hold useful content, rather
/// than mirroring a particular phone, tablet, or monitor resolution.
enum PerfectWindowClass { compact, medium, expanded }

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
      final media = MediaQuery.of(context);
      final geometry = PerfectResponsiveGeometry.fromConstraints(
        constraints,
        fallbackSize: media.size,
        textScale: media.textScaler.scale(1),
      );
      return builder(context, geometry);
    },
  );
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
    this.selected = false,
    this.autofocus = false,
    this.focusNode,
    this.statesController,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final bool selected;
  final bool autofocus;
  final FocusNode? focusNode;
  final WidgetStatesController? statesController;

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
  }

  @override
  Widget build(BuildContext context) {
    final interactive = ListenableBuilder(
      listenable: _statesController,
      builder: (context, child) {
        final states = _statesController.value;
        final scheme = Theme.of(context).colorScheme;
        final disabled = states.contains(WidgetState.disabled);
        final selected = states.contains(WidgetState.selected);
        final hovered = states.contains(WidgetState.hovered);
        final focused = states.contains(WidgetState.focused);
        final pressed = states.contains(WidgetState.pressed);
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        final duration = PerfectMotion.responsive(
          context,
          pressed ? PerfectMotion.quick : PerfectMotion.standard,
        );

        final base = widget.backgroundColor ?? scheme.surfaceContainerLow;
        final targetColor = disabled
            ? Color.lerp(base, scheme.surface, .45)!
            : pressed
            ? Color.lerp(base, scheme.primaryContainer, .48)!
            : selected
            ? Color.lerp(base, scheme.primaryContainer, .34)!
            : hovered
            ? Color.lerp(base, scheme.primaryContainer, .18)!
            : base;
        final borderColor = focused
            ? scheme.primary
            : selected
            ? scheme.primary.withValues(alpha: .68)
            : scheme.outlineVariant;
        final scale = reduceMotion || !pressed ? 1.0 : .985;

        return TweenAnimationBuilder<double>(
          key: const ValueKey<String>('perfect-interaction-scale'),
          duration: duration,
          curve: PerfectMotion.productive,
          tween: Tween<double>(end: scale),
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
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
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: hovered && !disabled
                  ? [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: .10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                autofocus: widget.autofocus,
                focusNode: widget.focusNode,
                borderRadius: widget.borderRadius,
                mouseCursor: _enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                enableFeedback: true,
                hoverDuration: duration,
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return scheme.primary.withValues(alpha: .12);
                  }
                  return Colors.transparent;
                }),
                onHover: (value) => _update(WidgetState.hovered, value),
                onFocusChange: (value) => _update(WidgetState.focused, value),
                onHighlightChanged: (value) =>
                    _update(WidgetState.pressed, value),
                child: Padding(padding: widget.padding, child: widget.child),
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
