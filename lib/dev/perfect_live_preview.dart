import 'dart:async';
import 'dart:ui' show FrameTiming;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:perfect/ai/perfect_ai_client.dart';
import 'package:perfect/ai/perfect_ai_contract.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/app/perfect_system_appearance.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';
import 'package:perfect/planner/data/planner_database.dart';
import 'package:perfect/planner/data/planner_local_store.dart';
import 'package:perfect/planner/domain/planner_entity.dart';
import 'package:perfect/planner/sync/planner_sync_repository.dart';
import 'package:perfect/presentation/perfect_theme.dart';
import 'package:perfect/presentation/perfect_workspace_page.dart';
import 'package:perfect/presentation/planner_workspace_controller.dart';

/// Secret-free Android/Windows design runtime used only by local development.
///
/// It boots the real workspace, Drift store, sync queue, planner editor, and
/// AI dock against deterministic local adapters. Release builds keep using
/// `lib/main.dart`; this entrypoint never bypasses production authentication.
void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (kProfileMode) _PerfectPreviewFrameProbe.install(binding);
  ReadyFeedbackLogger.instance.installGlobalErrorCapture();
  runApp(const PerfectLivePreviewApp());
}

/// Emits raw Flutter build/raster timings only from the disposable profile
/// preview. Android's `dumpsys gfxinfo` sees the host SurfaceView rather than
/// Flutter's rendered frames, so those two ViewRoot samples are not accepted
/// as motion-performance evidence.
class _PerfectPreviewFrameProbe with WidgetsBindingObserver {
  _PerfectPreviewFrameProbe._();

  static void install(WidgetsBinding binding) {
    final probe = _PerfectPreviewFrameProbe._();
    binding
      ..addObserver(probe)
      ..addTimingsCallback(probe._capture);
    Timer.periodic(const Duration(seconds: 1), (_) => probe._flush());
  }

  final List<FrameTiming> _pending = <FrameTiming>[];

  void _capture(List<FrameTiming> timings) => _pending.addAll(timings);

  void _flush() {
    if (_pending.isEmpty) return;
    final batch = List<FrameTiming>.of(_pending);
    _pending.clear();
    final payload = batch
        .map(
          (timing) =>
              '${timing.buildDuration.inMicroseconds}:'
              '${timing.rasterDuration.inMicroseconds}:'
              '${timing.totalSpan.inMicroseconds}',
        )
        .join(',');
    // ignore: avoid_print
    print('PERFECT_FRAME_TIMINGS_V1 $payload');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flush();
    }
  }
}

class PerfectLivePreviewApp extends StatefulWidget {
  const PerfectLivePreviewApp({super.key});

  @override
  State<PerfectLivePreviewApp> createState() => _PerfectLivePreviewAppState();
}

class _PerfectLivePreviewAppState extends State<PerfectLivePreviewApp> {
  ThemeMode _themeMode = ThemeMode.light;
  PerfectContrastMode _contrastMode = PerfectContrastMode.system;

  @override
  Widget build(BuildContext context) {
    final forcedHighContrast = _contrastMode == PerfectContrastMode.high;
    return MaterialApp(
      title: 'Perfect!',
      debugShowCheckedModeBanner: false,
      theme: forcedHighContrast
          ? PerfectTheme.highContrastLight()
          : PerfectTheme.light(),
      darkTheme: forcedHighContrast
          ? PerfectTheme.highContrastDark()
          : PerfectTheme.dark(),
      highContrastTheme: PerfectTheme.highContrastLight(),
      highContrastDarkTheme: PerfectTheme.highContrastDark(),
      themeMode: _themeMode,
      themeAnimationDuration: PerfectMotion.standard,
      themeAnimationCurve: PerfectMotion.productive,
      builder: (context, child) => PerfectSystemAppearanceProjection(
        themeMode: _themeMode,
        contrastMode: _contrastMode,
        child: child ?? const SizedBox.shrink(),
      ),
      home: _PerfectLivePreviewWorkspace(
        themeMode: _themeMode,
        contrastMode: _contrastMode,
        onThemeModeChanged: (value) => setState(() => _themeMode = value),
        onContrastModeChanged: (value) => setState(() => _contrastMode = value),
      ),
    );
  }
}

class _PerfectLivePreviewWorkspace extends StatefulWidget {
  const _PerfectLivePreviewWorkspace({
    required this.themeMode,
    required this.contrastMode,
    required this.onThemeModeChanged,
    required this.onContrastModeChanged,
  });

  final ThemeMode themeMode;
  final PerfectContrastMode contrastMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<PerfectContrastMode> onContrastModeChanged;

  @override
  State<_PerfectLivePreviewWorkspace> createState() =>
      _PerfectLivePreviewWorkspaceState();
}

class _PerfectLivePreviewWorkspaceState
    extends State<_PerfectLivePreviewWorkspace> {
  late final ReadyFeedbackController _feedbackController =
      ReadyFeedbackController(
        config: const ReadyFeedbackConfig(
          applicationName: 'Perfect!',
          storageNamespace: 'perfect-live-preview-feedback',
          settingsKey: 'perfect.live_preview.feedback_enabled',
        ),
      );
  late final Future<PlannerWorkspaceController> _controllerFuture =
      _createController();
  PlannerWorkspaceController? _controller;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_feedbackController.initialize());
  }

  Future<PlannerWorkspaceController> _createController() async {
    final database = PlannerDatabase(NativeDatabase.memory());
    final local = PlannerLocalStore(database);
    final sync = PlannerSyncRepository(
      local,
      _LivePreviewGateway(),
      ownerId: _previewOwnerId,
      deviceId: _previewDeviceId,
      retryBaseDelay: const Duration(milliseconds: 250),
      retryMaxDelay: const Duration(seconds: 2),
    );
    final controller = PlannerWorkspaceController(
      local,
      sync,
      ownerId: _previewOwnerId,
      // A frozen local instant makes reference comparisons repeatable. This is
      // only the private design entrypoint; the released workspace keeps its
      // live clock and real device timezone.
      now: () => _previewReferenceNow,
    );
    _controller = controller;
    try {
      await controller.start();
      await _seedPreview(controller, local);
      await controller.refresh();
      if (_disposed) {
        controller.requestShutdown();
        await controller.disposeAsync();
      }
      return controller;
    } on Object {
      controller.requestShutdown();
      await controller.disposeAsync();
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _feedbackController.dispose();
    final controller = _controller;
    controller?.requestShutdown();
    unawaited(
      _controllerFuture.then(
        (value) => value.disposeAsync(),
        onError: (Object _, StackTrace _) {},
      ),
    );
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<PlannerWorkspaceController>(
    future: _controllerFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Perfect! preview could not open its local workspace.\n\n'
                    '${snapshot.error}',
                  ),
                ),
              ),
            ),
          ),
        );
      }
      final controller = snapshot.data;
      if (controller == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return PerfectWorkspacePage(
        controller: controller,
        feedbackController: _feedbackController,
        aiClient: const _LivePreviewAiClient(),
        now: () => _previewReferenceNow,
        ownerDisplayName: 'Alex',
        themeMode: widget.themeMode,
        contrastMode: widget.contrastMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onContrastModeChanged: widget.onContrastModeChanged,
        onSignOut: () async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Live Preview has no account session to sign out from.',
              ),
            ),
          );
        },
      );
    },
  );
}

const _previewOwnerId = 'perfect-live-preview-owner';
const _previewDeviceId = '11111111-1111-4111-8111-111111111111';
final _previewReferenceNow = DateTime(2025, 5, 12, 19, 42);

Future<void> _seedPreview(
  PlannerWorkspaceController controller,
  PlannerLocalStore local,
) async {
  if ((await local.readActiveEntities(_previewOwnerId)).isNotEmpty) return;

  final now = _previewReferenceNow;
  final reviewStart = DateTime(now.year, now.month, now.day, 19, 15);
  final focusStart = DateTime(now.year, now.month, now.day, 20);
  final callStart = DateTime(now.year, now.month, now.day, 21, 30);

  await controller.saveEntity(
    kind: PlannerEntityKind.oneOffTask,
    payload: <String, dynamic>{
      ...defaultPlannerPayload(title: 'Review project brief'),
      PlannerPayloadKeys.note: 'Mark the draft against today’s decision.',
      PlannerPayloadKeys.timing: <String, dynamic>{
        'scheduled_at': reviewStart.toUtc().toIso8601String(),
        PlannerTaskMetadataKeys.timeBlockEndAt: reviewStart
            .add(const Duration(minutes: 45))
            .toUtc()
            .toIso8601String(),
      },
      'priority': 'normal',
      'category': 'Work',
      PlannerTaskMetadataKeys.labels: <String>['Review'],
      PlannerTaskMetadataKeys.estimateMinutes: 45,
      PlannerTaskMetadataKeys.energy: 'medium',
      PlannerTaskMetadataKeys.color: 'mint',
      PlannerPayloadKeys.taskProgressState: 'partial',
      PlannerPayloadKeys.taskProgressPercent: 60,
    },
  );
  await controller.saveEntity(
    kind: PlannerEntityKind.oneOffTask,
    payload: <String, dynamic>{
      ...defaultPlannerPayload(title: 'Focus deep work'),
      PlannerPayloadKeys.timing: <String, dynamic>{
        'scheduled_at': focusStart.toUtc().toIso8601String(),
        PlannerTaskMetadataKeys.timeBlockEndAt: focusStart
            .add(const Duration(hours: 2))
            .toUtc()
            .toIso8601String(),
      },
      'priority': 'normal',
      'category': 'Work',
      PlannerTaskMetadataKeys.labels: <String>['Deep work'],
      PlannerTaskMetadataKeys.estimateMinutes: 120,
      PlannerTaskMetadataKeys.energy: 'high',
      PlannerTaskMetadataKeys.color: 'apricot',
    },
  );
  await controller.saveEntity(
    kind: PlannerEntityKind.oneOffTask,
    payload: <String, dynamic>{
      ...defaultPlannerPayload(title: 'Call Mom'),
      PlannerPayloadKeys.timing: <String, dynamic>{
        'scheduled_at': callStart.toUtc().toIso8601String(),
      },
      'priority': 'normal',
      'category': 'Personal',
      PlannerTaskMetadataKeys.labels: <String>['Personal'],
      PlannerTaskMetadataKeys.estimateMinutes: 20,
      PlannerTaskMetadataKeys.energy: 'low',
      PlannerTaskMetadataKeys.color: 'rose',
      PlannerPayloadKeys.taskProgressState: 'missed',
      PlannerPayloadKeys.taskProgressPercent: 0,
    },
  );
  await controller.saveEntity(
    kind: PlannerEntityKind.habit,
    payload: <String, dynamic>{
      ...defaultPlannerPayload(title: 'Drink water'),
      PlannerPayloadKeys.note: 'Eight calm check-ins across the day.',
      PlannerPayloadKeys.tracking: <String, dynamic>{
        'method': 'count',
        'target': 8,
        'unit': 'glasses',
      },
      PlannerPayloadKeys.recurrence: <String, dynamic>{
        PlannerRecurrenceKeys.rule: 'daily',
        PlannerRecurrenceKeys.interval: 1,
      },
    },
  );
}

class _LivePreviewGateway implements PlannerRemoteGateway {
  final Map<String, Map<String, dynamic>> _payloads =
      <String, Map<String, dynamic>>{};

  @override
  Future<PlannerRemoteMutationResult> apply(
    PlannerRemoteMutation mutation,
  ) async {
    final key = '${mutation.entityKind}:${mutation.entityId}';
    final payload = _mergePayload(
      _payloads[key] ?? const <String, dynamic>{},
      safeJsonMap(mutation.patch['payload']),
    );
    final explicitTitle = mutation.patch['title']?.toString().trim();
    if (explicitTitle != null && explicitTitle.isNotEmpty) {
      payload[PlannerPayloadKeys.title] = explicitTitle;
    }
    _payloads[key] = payload;
    final timestamp = DateTime.now().toUtc().toIso8601String();
    return PlannerRemoteMutationResult.fromJson(<String, dynamic>{
      'status': 'acknowledged',
      'entity': <String, dynamic>{
        'id': mutation.entityId,
        'owner_id': _previewOwnerId,
        'kind': mutation.entityKind,
        'title': safeJsonString(
          payload[PlannerPayloadKeys.title],
          fallback: 'Perfect! preview item',
        ),
        'lifecycle_state': mutation.operationType == 'soft_delete'
            ? 'archived'
            : mutation.patch['lifecycle_state']?.toString() ?? 'active',
        'payload': payload,
        'revision': mutation.baseRevision + 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'deleted_at': mutation.operationType == 'soft_delete'
            ? timestamp
            : null,
      },
    });
  }

  @override
  Future<PlannerRemoteChangePage> pull({
    required int afterChangeId,
    required int limit,
  }) async => PlannerRemoteChangePage(
    changes: const <PlannerRemoteChange>[],
    requestedLimit: limit,
  );

  @override
  Future<List<Map<String, dynamic>>> readLegacyItems() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<void> subscribe(void Function() onChangeHint) async {}

  @override
  Future<void> dispose() async {}
}

Map<String, dynamic> _mergePayload(
  Map<String, dynamic> previous,
  Map<String, dynamic> patch,
) {
  final merged = <String, dynamic>{...previous};
  for (final entry in patch.entries) {
    final oldValue = merged[entry.key];
    final newValue = entry.value;
    merged[entry.key] = oldValue is Map && newValue is Map
        ? _mergePayload(safeJsonMap(oldValue), safeJsonMap(newValue))
        : newValue;
  }
  return merged;
}

class _LivePreviewAiClient implements PerfectAiClient {
  const _LivePreviewAiClient();

  @override
  Future<PerfectAiTurnResult> chat(
    PerfectAiRequest request, {
    PerfectAiCancellation? cancellation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (cancellation?.isCancelled == true) {
      throw const PerfectAiException(
        code: PerfectAiErrorCode.cancelled,
        message: 'Preview request cancelled.',
        retryable: false,
      );
    }
    final now = DateTime.now().toUtc();
    return PerfectAiTurnResult(
      operationId: request.operationId,
      conversationId: request.conversationId ?? 'perfect-preview-conversation',
      message: PerfectAiMessage(
        id: 'preview-${now.microsecondsSinceEpoch}',
        role: PerfectAiRole.assistant,
        text:
            'I can shape that into a clear plan. In the private build, every '
            'write stays reviewable before it enters your synced workspace.',
        createdAt: now,
      ),
      telemetry: const PerfectAiTelemetry(
        model: 'gemini-flash-lite-latest',
        promptVersion: 'live-preview',
        schemaVersion: '1',
      ),
    );
  }

  @override
  Future<PerfectAiApplyResult> applyProposal({
    required String operationId,
    required String? conversationId,
    required PerfectAiProposal proposal,
    PerfectAiCancellation? cancellation,
  }) async => PerfectAiApplyResult(
    operationId: operationId,
    conversationId: conversationId ?? 'perfect-preview-conversation',
    appliedCount: proposal.items.length,
    message: null,
  );
}
