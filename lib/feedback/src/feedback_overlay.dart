import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:perfect/feedback/src/feedback_controller.dart';
import 'package:perfect/feedback/src/feedback_exporter.dart';
import 'package:perfect/feedback/src/feedback_models.dart';
import 'package:perfect/feedback/src/feedback_repository.dart';
import 'package:perfect/presentation/perfect_local_time.dart';
import 'package:perfect/presentation/perfect_motion.dart';
import 'package:perfect/presentation/perfect_theme.dart';

typedef ReadyFeedbackScreenshotProvider =
    Future<ReadyFeedbackScreenshotCapture> Function();

/// Lets a host expose feedback from an intentional, contextual command rather
/// than keeping a draggable affordance over everyday content. The overlay
/// owns the actual capture flow so screenshots still omit the launcher.
class ReadyFeedbackOverlayController extends ChangeNotifier {
  Future<void> Function()? _open;

  bool get isAttached => _open != null;

  Future<void> open() async {
    final callback = _open;
    if (callback != null) await callback();
  }

  void _attach(Future<void> Function() callback) {
    if (identical(_open, callback)) return;
    _open = callback;
    notifyListeners();
  }

  void _detach(Future<void> Function() callback) {
    if (!identical(_open, callback)) return;
    _open = null;
    notifyListeners();
  }
}

class ReadyFeedbackOverlay extends StatefulWidget {
  const ReadyFeedbackOverlay({
    super.key,
    required this.controller,
    required this.routeName,
    required this.child,
    this.screenshotProvider,
    this.launcherVisible = true,
    this.launcherController,
  });

  final ReadyFeedbackController controller;
  final String routeName;
  final Widget child;
  final ReadyFeedbackScreenshotProvider? screenshotProvider;

  /// A host can temporarily remove the edge tab while an owned, focused
  /// workspace surface (for example an editor or AI dock) is open. Feedback
  /// remains enabled and available again as soon as that surface closes; this
  /// only prevents a nonessential control from competing with the active task.
  final bool launcherVisible;

  /// Optional bridge for a host-owned menu or settings command. It can expose
  /// the same private capture flow with no persistent overlay on primary UI.
  final ReadyFeedbackOverlayController? launcherController;

  @override
  State<ReadyFeedbackOverlay> createState() => _ReadyFeedbackOverlayState();
}

class _ReadyFeedbackOverlayState extends State<ReadyFeedbackOverlay> {
  final GlobalKey _captureBoundaryKey = GlobalKey();
  Offset? _position;
  bool _capturing = false;
  late final Future<void> Function() _openCallback;

  @override
  void initState() {
    super.initState();
    _openCallback = _showMenu;
    widget.launcherController?._attach(_openCallback);
  }

  @override
  void didUpdateWidget(covariant ReadyFeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.launcherController == widget.launcherController) return;
    oldWidget.launcherController?._detach(_openCallback);
    widget.launcherController?._attach(_openCallback);
  }

  @override
  void dispose() {
    widget.launcherController?._detach(_openCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      const buttonExtent = 48.0;
      final maxX = constraints.maxWidth - buttonExtent - media.padding.right;
      final fallback = Offset(
        Directionality.of(context) == TextDirection.rtl
            ? media.padding.left
            : maxX,
        (constraints.maxHeight * .62) - (buttonExtent / 2),
      );
      final position = _clampPosition(
        _position ?? fallback,
        constraints.biggest,
        media.padding,
        buttonExtent,
      );
      final attachedEdge = _attachedEdge(
        position,
        constraints.biggest,
        media.padding,
        buttonExtent,
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(key: _captureBoundaryKey, child: widget.child),
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              if (!widget.controller.initialized ||
                  !widget.controller.enabled ||
                  _capturing ||
                  !widget.launcherVisible) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: position.dx,
                top: position.dy,
                width: buttonExtent,
                height: buttonExtent,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    setState(() {
                      _position = _clampPosition(
                        position + details.delta,
                        constraints.biggest,
                        media.padding,
                        buttonExtent,
                      );
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _position = _snapToEdge(
                        _position ?? position,
                        constraints.biggest,
                        media.padding,
                        buttonExtent,
                      );
                    });
                  },
                  child: _FeedbackEdgeTab(
                    edge: attachedEdge,
                    busy: widget.controller.busy,
                    onPressed: widget.controller.busy ? null : _showMenu,
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );

  Offset _clampPosition(
    Offset value,
    Size size,
    EdgeInsets padding,
    double extent,
  ) {
    final minX = padding.left;
    final maxX = size.width - extent - padding.right;
    final minY = padding.top + 8;
    final maxY = size.height - extent - padding.bottom - 8;
    return Offset(
      _clampAxis(value.dx, minX, maxX, size.width - extent),
      _clampAxis(value.dy, minY, maxY, size.height - extent),
    );
  }

  Offset _snapToEdge(
    Offset value,
    Size size,
    EdgeInsets padding,
    double extent,
  ) {
    final clamped = _clampPosition(value, size, padding, extent);
    final minX = padding.left;
    final maxX = size.width - extent - padding.right;
    final x = clamped.dx <= (minX + maxX) / 2 ? minX : maxX;
    return Offset(x, clamped.dy);
  }

  _FeedbackEdge _attachedEdge(
    Offset value,
    Size size,
    EdgeInsets padding,
    double extent,
  ) {
    final minX = padding.left;
    final maxX = size.width - extent - padding.right;
    if ((value.dx - minX).abs() < 1) return _FeedbackEdge.left;
    if ((value.dx - maxX).abs() < 1) return _FeedbackEdge.right;
    return _FeedbackEdge.floating;
  }

  double _clampAxis(
    double value,
    double minimum,
    double maximum,
    double available,
  ) {
    if (maximum < minimum) return available > 0 ? available / 2 : 0;
    return value.clamp(minimum, maximum).toDouble();
  }

  Future<void> _showMenu() async {
    final action = await showModalBottomSheet<_FeedbackMenuAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      sheetAnimationStyle: PerfectMotion.modalSheetStyle(context),
      builder: (context) => const _FeedbackMenuSheet(),
    );
    if (!mounted || action == null) return;
    if (action == _FeedbackMenuAction.entries) {
      await ReadyFeedbackEntriesSheet.show(context, widget.controller);
      return;
    }
    ReadyFeedbackScreenshotCapture? screenshot;
    if (action == _FeedbackMenuAction.screenshotAndNote) {
      try {
        screenshot = await _captureScreenshot();
      } on Object catch (error, stackTrace) {
        widget.controller.logger.error(
          error,
          stackTrace: stackTrace,
          context: 'Capturing feedback screenshot',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot failed. The note was not saved yet.'),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    final draft = await showPerfectDialog<_ReadyFeedbackDraft>(
      context: context,
      builder: (context) => _FeedbackDraftDialog(screenshot: screenshot),
    );
    if (!mounted || draft == null) return;

    try {
      await widget.controller.addEntry(
        route: widget.routeName,
        note: draft.note,
        kind: draft.kind,
        screenshot: draft.screenshot,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.screenshot != null
                ? 'Private note and screenshot saved.'
                : 'Private note saved.',
          ),
          action: SnackBarAction(
            label: 'Review',
            onPressed: () =>
                ReadyFeedbackEntriesSheet.show(context, widget.controller),
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Saving feedback entry',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this feedback entry.')),
      );
    }
  }

  Future<ReadyFeedbackScreenshotCapture> _captureScreenshot() async {
    final deviceRatio = MediaQuery.devicePixelRatioOf(context);
    setState(() => _capturing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final provided = widget.screenshotProvider;
      if (provided != null) return await provided();
      final boundary = _captureBoundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Feedback capture boundary is unavailable.');
      }
      final ratio = deviceRatio
          .clamp(1.0, widget.controller.config.maxScreenshotPixelRatio)
          .toDouble();
      final image = await boundary.toImage(pixelRatio: ratio);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Screenshot encoding failed.');
        return ReadyFeedbackScreenshotCapture(
          bytes: Uint8List.fromList(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          ),
          pixelRatio: ratio,
        );
      } finally {
        image.dispose();
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }
}

enum _FeedbackEdge { left, right, floating }

class _FeedbackEdgeTab extends StatefulWidget {
  const _FeedbackEdgeTab({
    required this.edge,
    required this.busy,
    required this.onPressed,
  });

  final _FeedbackEdge edge;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_FeedbackEdgeTab> createState() => _FeedbackEdgeTabState();
}

class _FeedbackEdgeTabState extends State<_FeedbackEdgeTab> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Perfect private feedback shortcut',
  );
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = PerfectMotion.responsive(context, PerfectMotion.quick);
    final visualWidth = widget.edge == _FeedbackEdge.floating ? 40.0 : 34.0;
    final alignment = switch (widget.edge) {
      _FeedbackEdge.left => Alignment.centerLeft,
      _FeedbackEdge.right => Alignment.centerRight,
      _FeedbackEdge.floating => Alignment.center,
    };
    final radius = switch (widget.edge) {
      _FeedbackEdge.left => const BorderRadius.horizontal(
        left: Radius.circular(8),
        right: Radius.circular(15),
      ),
      _FeedbackEdge.right => const BorderRadius.horizontal(
        left: Radius.circular(15),
        right: Radius.circular(8),
      ),
      _FeedbackEdge.floating => BorderRadius.circular(15),
    };
    final borderColor = _focused
        ? scheme.primary
        : _hovered
        ? scheme.outline
        : scheme.outlineVariant.withValues(alpha: .68);
    final surfaceColor = Color.alphaBlend(
      scheme.primary.withValues(
        alpha: _pressed
            ? .10
            : _hovered
            ? .055
            : .02,
      ),
      scheme.surface.withValues(alpha: .86),
    );
    final translation = reduceMotion
        ? Offset.zero
        : switch (widget.edge) {
            _FeedbackEdge.left when _hovered => const Offset(2, 0),
            _FeedbackEdge.right when _hovered => const Offset(-2, 0),
            _FeedbackEdge.floating when _hovered => const Offset(0, -1),
            _ => Offset.zero,
          };
    final scale = reduceMotion || !_pressed ? 1.0 : .96;

    return Tooltip(
      message: 'Capture feedback',
      child: Semantics(
        button: true,
        enabled: widget.onPressed != null,
        label: 'Capture private feedback',
        hint:
            'Drag along the screen edge, or activate to add a private note, screenshot, or review saved entries.',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('ready-feedback-affordance'),
            focusNode: _focusNode,
            canRequestFocus: widget.onPressed != null,
            mouseCursor: widget.onPressed == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onPressed,
            onHover: (value) => _setState(hovered: value),
            onFocusChange: (value) => _setState(focused: value),
            onHighlightChanged: (value) => _setState(pressed: value),
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: scheme.primary.withValues(alpha: .10),
            child: TweenAnimationBuilder<double>(
              duration: duration,
              curve: PerfectMotion.productive,
              tween: Tween<double>(end: scale),
              builder: (context, value, child) => Transform.translate(
                offset: translation,
                child: Transform.scale(scale: value, child: child),
              ),
              child: Align(
                alignment: alignment,
                child: AnimatedContainer(
                  key: const ValueKey<String>('ready-feedback-edge-tab'),
                  duration: duration,
                  curve: PerfectMotion.productive,
                  width: visualWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: radius,
                    border: Border.all(color: borderColor),
                    boxShadow: (_hovered || _focused) && !reduceMotion
                        ? <BoxShadow>[
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: .08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: widget.busy
                          ? SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                color: scheme.onSurfaceVariant,
                                strokeWidth: 1.8,
                              ),
                            )
                          : Icon(
                              Icons.feedback_outlined,
                              color: scheme.onSurfaceVariant,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setState({bool? hovered, bool? focused, bool? pressed}) {
    final nextHovered = hovered ?? _hovered;
    final nextFocused = focused ?? _focused;
    final nextPressed = pressed ?? _pressed;
    if (nextHovered == _hovered &&
        nextFocused == _focused &&
        nextPressed == _pressed) {
      return;
    }
    setState(() {
      _hovered = nextHovered;
      _focused = nextFocused;
      _pressed = nextPressed;
    });
  }
}

enum _FeedbackMenuAction { screenshotAndNote, noteOnly, entries }

class _FeedbackMenuSheet extends StatelessWidget {
  const _FeedbackMenuSheet();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Private feedback capture',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Everything stays on this device until you export it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _FeedbackActionTile(
            icon: Icons.photo_camera_outlined,
            title: 'Screenshot + note',
            subtitle: 'Capture the current app surface without this button.',
            onTap: () =>
                Navigator.pop(context, _FeedbackMenuAction.screenshotAndNote),
          ),
          _FeedbackActionTile(
            icon: Icons.edit_note_rounded,
            title: 'Note only',
            subtitle: 'Record an error, suggestion, criticism, or thought.',
            onTap: () => Navigator.pop(context, _FeedbackMenuAction.noteOnly),
          ),
          _FeedbackActionTile(
            icon: Icons.folder_copy_outlined,
            title: 'Captured entries',
            subtitle: 'Review, remove, clear, or export your private bundle.',
            onTap: () => Navigator.pop(context, _FeedbackMenuAction.entries),
          ),
        ],
      ),
    ),
  );
}

class _FeedbackActionTile extends StatelessWidget {
  const _FeedbackActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_rounded),
      onTap: onTap,
    ),
  );
}

class _ReadyFeedbackDraft {
  const _ReadyFeedbackDraft({
    required this.note,
    required this.kind,
    required this.screenshot,
  });

  final String note;
  final ReadyFeedbackKind kind;
  final ReadyFeedbackScreenshotCapture? screenshot;
}

class _FeedbackDraftDialog extends StatefulWidget {
  const _FeedbackDraftDialog({required this.screenshot});

  final ReadyFeedbackScreenshotCapture? screenshot;

  @override
  State<_FeedbackDraftDialog> createState() => _FeedbackDraftDialogState();
}

class _FeedbackDraftDialogState extends State<_FeedbackDraftDialog> {
  final TextEditingController _controller = TextEditingController();
  ReadyFeedbackKind _kind = ReadyFeedbackKind.error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Icon(
      widget.screenshot != null
          ? Icons.photo_camera_outlined
          : Icons.edit_note_rounded,
    ),
    title: Text(widget.screenshot != null ? 'Screenshot + note' : 'New note'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.screenshot case final screenshot?) ...[
              _ScreenshotPreview(bytes: screenshot.bytes, maxHeight: 220),
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.visibility_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Review this image now. Text credentials are redacted, '
                      'but screenshot pixels are saved exactly as shown.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<ReadyFeedbackKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ReadyFeedbackKind.values
                  .map(
                    (kind) =>
                        DropdownMenuItem(value: kind, child: Text(kind.label)),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _kind = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'What happened or what should change?',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final note = _controller.text.trim();
          if (note.isEmpty && widget.screenshot == null) return;
          Navigator.pop(
            context,
            _ReadyFeedbackDraft(
              note: note,
              kind: _kind,
              screenshot: widget.screenshot,
            ),
          );
        },
        child: const Text('Save privately'),
      ),
    ],
  );
}

class _ScreenshotPreview extends StatelessWidget {
  const _ScreenshotPreview({required this.bytes, required this.maxHeight});

  final Uint8List bytes;
  final double maxHeight;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Captured app screenshot preview',
    image: true,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 120,
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
      ),
    ),
  );
}

abstract final class ReadyFeedbackEntriesSheet {
  static Future<void> show(
    BuildContext context,
    ReadyFeedbackController controller,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    sheetAnimationStyle: PerfectMotion.modalSheetStyle(context),
    builder: (context) => FractionallySizedBox(
      heightFactor: .82,
      child: _FeedbackEntriesBody(controller: controller),
    ),
  );
}

class _FeedbackEntriesBody extends StatefulWidget {
  const _FeedbackEntriesBody({required this.controller});

  final ReadyFeedbackController controller;

  @override
  State<_FeedbackEntriesBody> createState() => _FeedbackEntriesBodyState();
}

class _FeedbackEntriesBodyState extends State<_FeedbackEntriesBody> {
  late Future<List<ReadyFeedbackEntry>> _entries = widget.controller
      .readEntries();

  void _reload() {
    setState(() {
      _entries = widget.controller.readEntries();
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Captured entries',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('Local until you explicitly export them.'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Export private bundle',
              onPressed: _confirmAndExport,
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton(
              tooltip: 'Clear all entries and logs',
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<ReadyFeedbackEntry>>(
            future: _entries,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final recoveryRequired =
                    snapshot.error is ReadyFeedbackIndexRecoveryException;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          recoveryRequired
                              ? Icons.health_and_safety_outlined
                              : Icons.folder_off_outlined,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          recoveryRequired
                              ? 'The feedback index needs recovery. Private '
                                    'screenshots were preserved and no '
                                    'automatic cleanup was attempted.'
                              : 'Could not read the private feedback folder.',
                          textAlign: TextAlign.center,
                        ),
                        if (recoveryRequired) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: widget.controller.busy
                                ? null
                                : _confirmRecovery,
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('Recover safely'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              final entries = snapshot.data ?? const <ReadyFeedbackEntry>[];
              if (entries.isEmpty) {
                return const Center(child: Text('No captured entries yet.'));
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: entry.hasScreenshot
                        ? _FeedbackThumbnail(
                            key: ValueKey<String>(entry.id),
                            controller: widget.controller,
                            entry: entry,
                          )
                        : SizedBox.square(
                            dimension: 52,
                            child: Icon(_kindIcon(entry.kind)),
                          ),
                    title: Text(
                      entry.note.isEmpty
                          ? '${entry.kind.label} capture'
                          : entry.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${entry.route} · ${_formatDate(entry.createdAt.toLocal())}'
                      '${entry.hasScreenshot ? ' · screenshot' : ''}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete entry',
                      onPressed: () async {
                        try {
                          await widget.controller.deleteEntry(entry.id);
                        } on Object catch (error, stackTrace) {
                          widget.controller.logger.error(
                            error,
                            stackTrace: stackTrace,
                            context: 'Deleting private feedback entry',
                          );
                          if (mounted) {
                            _showStorageFailure(error, action: 'delete');
                          }
                        } finally {
                          if (mounted) _reload();
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    onTap: () => showPerfectDialog<void>(
                      context: context,
                      builder: (context) => _FeedbackEntryDetailsDialog(
                        controller: widget.controller,
                        entry: entry,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmAndExport() async {
    ReadyFeedbackExportPreview preview;
    try {
      preview = await widget.controller.exportPreview();
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Preparing private feedback export',
      );
      if (mounted) _showStorageFailure(error, action: 'read');
      return;
    }
    if (!mounted) return;
    final approved = await showPerfectDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Review private export'),
        content: Text(
          'The ZIP will include ${preview.entryCount} entries, '
          '${preview.screenshotCount} screenshots, and ${preview.logCount} '
          'recent diagnostic logs. Common credentials in saved text and logs '
          'are redacted. Screenshot pixels are not redacted at all, so review '
          'every image before sharing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.lock_outline_rounded),
            label: const Text('Export ZIP'),
          ),
        ],
      ),
    );
    if (approved != true) {
      widget.controller.discardExportPreview(preview);
      return;
    }
    ReadyFeedbackExportResult result;
    try {
      result = await widget.controller.export(preview: preview);
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Exporting private feedback bundle',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ReadyFeedbackExportChangedException
                ? 'Private feedback changed after review. Review the updated '
                      'counts before exporting.'
                : 'Could not export the private ZIP.',
          ),
        ),
      );
      return;
    }
    if (!mounted || result.status == ReadyFeedbackExportStatus.cancelled) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.status == ReadyFeedbackExportStatus.saved
              ? 'Private feedback ZIP saved.'
              : 'Private feedback ZIP opened in the share sheet.',
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final approved = await showPerfectDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear private feedback?'),
        content: const Text(
          'This permanently removes every captured note, screenshot, and '
          'stored diagnostic log from this device, including any private '
          'recovery copies and temporary share ZIPs managed by Perfect. '
          'ZIPs you explicitly saved or shared outside Perfect remain; '
          'delete those copies separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep them'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    try {
      await widget.controller.clearAll();
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Clearing private feedback',
      );
      if (mounted) _showStorageFailure(error, action: 'clear');
    } finally {
      if (mounted) _reload();
    }
  }

  Future<void> _confirmRecovery() async {
    final approved = await showPerfectDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.health_and_safety_outlined),
        title: const Text('Recover private feedback?'),
        content: const Text(
          'Perfect! will move every corrupt index, saved screenshot, log, and '
          'raw feedback artifact into a timestamped recovery folder on this '
          'device. It will then create a fresh empty feedback store. Nothing '
          'is shared or silently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Preserve & recover'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    try {
      final result = await widget.controller.recoverCorruptStore(
        ownerConfirmed: true,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recovery copy preserved locally: ${result.artifactCount} '
            'artifacts and ${result.screenshotCount} screenshots. Feedback '
            'capture is ready again.',
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        error,
        stackTrace: stackTrace,
        context: 'Recovering private feedback store',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recovery could not finish. Existing artifacts were preserved.',
          ),
        ),
      );
    }
  }

  void _showStorageFailure(Object error, {required String action}) {
    final recoveryRequired = error is ReadyFeedbackIndexRecoveryException;
    final partialCleanup =
        error is ReadyFeedbackCleanupException && error.recordsRemoved;
    final message = recoveryRequired
        ? 'The feedback index needs recovery. Private screenshots were '
              'preserved and no automatic cleanup was attempted.'
        : partialCleanup
        ? 'Active records were removed, but a private recovery artifact or '
              'Perfect-managed temporary export could not be deleted yet. '
              'Use Clear all again to retry. Saved or shared ZIPs outside '
              'Perfect remain under your control.'
        : switch (action) {
            'delete' => 'Could not delete this private feedback entry.',
            'clear' => 'Could not clear the private feedback folder.',
            _ => 'Could not read the private feedback folder. Try again.',
          };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: recoveryRequired
            ? SnackBarAction(label: 'Recover', onPressed: _confirmRecovery)
            : null,
      ),
    );
  }

  IconData _kindIcon(ReadyFeedbackKind kind) => switch (kind) {
    ReadyFeedbackKind.error => Icons.error_outline_rounded,
    ReadyFeedbackKind.suggestion => Icons.lightbulb_outline_rounded,
    ReadyFeedbackKind.criticism => Icons.rate_review_outlined,
    ReadyFeedbackKind.note => Icons.sticky_note_2_outlined,
  };

  String _formatDate(DateTime value) => PerfectLocalTime.inspector(value);
}

class _FeedbackThumbnail extends StatefulWidget {
  const _FeedbackThumbnail({
    super.key,
    required this.controller,
    required this.entry,
  });

  final ReadyFeedbackController controller;
  final ReadyFeedbackEntry entry;

  @override
  State<_FeedbackThumbnail> createState() => _FeedbackThumbnailState();
}

class _FeedbackThumbnailState extends State<_FeedbackThumbnail> {
  late final Future<Uint8List?> _bytes = widget.controller.readScreenshot(
    widget.entry,
  );

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 52,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder<Uint8List?>(
        future: _bytes,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) {
            return ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                snapshot.connectionState == ConnectionState.done
                    ? Icons.broken_image_outlined
                    : Icons.image_outlined,
                size: 22,
              ),
            );
          }
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 22),
            ),
          );
        },
      ),
    ),
  );
}

class _FeedbackEntryDetailsDialog extends StatefulWidget {
  const _FeedbackEntryDetailsDialog({
    required this.controller,
    required this.entry,
  });

  final ReadyFeedbackController controller;
  final ReadyFeedbackEntry entry;

  @override
  State<_FeedbackEntryDetailsDialog> createState() =>
      _FeedbackEntryDetailsDialogState();
}

class _FeedbackEntryDetailsDialogState
    extends State<_FeedbackEntryDetailsDialog> {
  late final Future<Uint8List?> _screenshot = widget.entry.hasScreenshot
      ? widget.controller.readScreenshot(widget.entry)
      : Future<Uint8List?>.value();

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final media = MediaQuery.of(context);
    return AlertDialog(
      icon: Icon(_kindIcon(entry.kind)),
      title: Text(entry.kind.label),
      content: SizedBox(
        width: 680,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * .68),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${entry.route} · ${_formatDate(entry.createdAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SelectableText(entry.note),
                ],
                if (entry.hasScreenshot) ...[
                  const SizedBox(height: 16),
                  FutureBuilder<Uint8List?>(
                    future: _screenshot,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 160,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final bytes = snapshot.data;
                      if (bytes == null) {
                        return const SizedBox(
                          height: 120,
                          child: Center(
                            child: Text('Screenshot file is unavailable.'),
                          ),
                        );
                      }
                      return _ScreenshotPreview(
                        bytes: bytes,
                        maxHeight: (media.size.height * .42)
                            .clamp(180, 440)
                            .toDouble(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _screenshotMetadata(entry),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Screenshot pixels are stored exactly as captured and '
                    'are not redacted.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  IconData _kindIcon(ReadyFeedbackKind kind) => switch (kind) {
    ReadyFeedbackKind.error => Icons.error_outline_rounded,
    ReadyFeedbackKind.suggestion => Icons.lightbulb_outline_rounded,
    ReadyFeedbackKind.criticism => Icons.rate_review_outlined,
    ReadyFeedbackKind.note => Icons.sticky_note_2_outlined,
  };

  String _formatDate(DateTime value) => PerfectLocalTime.inspector(value);

  String _screenshotMetadata(ReadyFeedbackEntry entry) {
    final dimensions =
        entry.screenshotWidthPx == null || entry.screenshotHeightPx == null
        ? 'Unknown dimensions'
        : '${entry.screenshotWidthPx} × ${entry.screenshotHeightPx} px';
    final size = entry.screenshotByteLength == null
        ? 'unknown size'
        : '${(entry.screenshotByteLength! / 1024).toStringAsFixed(1)} KB';
    return '$dimensions · $size';
  }
}

class ReadyFeedbackSettingsTile extends StatelessWidget {
  const ReadyFeedbackSettingsTile({
    super.key,
    required this.controller,
    this.onCapture,
  });

  final ReadyFeedbackController controller;
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.feedback_outlined),
          title: const Text('Feedback capture'),
          subtitle: const Text(
            'Private screenshots, notes, suggestions, and criticism.',
          ),
          value: controller.enabled,
          onChanged: controller.initialized && !controller.busy
              ? (value) async {
                  try {
                    await controller.setEnabled(value);
                  } on Object {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not save this setting.'),
                      ),
                    );
                  }
                }
              : null,
        ),
        if (onCapture != null) ...[
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.add_comment_outlined),
            title: const Text('Capture feedback now'),
            subtitle: const Text(
              'Open the private note and screenshot capture flow.',
            ),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap:
                controller.initialized && controller.enabled && !controller.busy
                ? onCapture
                : null,
          ),
        ],
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.folder_copy_outlined),
          title: const Text('Captured feedback & logs'),
          subtitle: Text(
            '${controller.entryCount} entries · stored only on this device',
          ),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: controller.initialized
              ? () => ReadyFeedbackEntriesSheet.show(context, controller)
              : null,
        ),
      ],
    ),
  );
}
