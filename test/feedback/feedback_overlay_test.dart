import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';

void main() {
  testWidgets(
    'feedback shortcut is a compact accessible edge tab instead of a FAB',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-overlay-affordance-test',
        settingsKey: 'feedback.enabled',
      );
      final controller = ReadyFeedbackController(
        config: config,
        repository: _MemoryRepository(config: config),
        settingsStore: _MemorySettings(),
        logger: ReadyFeedbackLogger(memoryLimit: 20),
      );
      addTearDown(controller.dispose);
      await tester.runAsync(controller.initialize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadyFeedbackOverlay(
              controller: controller,
              routeName: 'Synthetic edge route',
              child: const ColoredBox(color: Color(0xFFF6F1EA)),
            ),
          ),
        ),
      );
      await _settle(tester);

      final affordance = find.byKey(
        const ValueKey<String>('ready-feedback-affordance'),
      );
      final visualTab = find.byKey(
        const ValueKey<String>('ready-feedback-edge-tab'),
      );
      final surfaceSize = tester.getSize(find.byType(Scaffold));
      expect(tester.getSize(affordance), const Size.square(48));
      expect(tester.getSize(visualTab), const Size(34, 40));
      expect(tester.getTopRight(affordance).dx, surfaceSize.width);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
      final node = tester.getSemantics(affordance);
      expect(node.label, contains('Capture private feedback'));
      expect(node.hint, contains('Drag along the screen edge'));

      final control = tester.widget<InkWell>(affordance);
      expect(control.canRequestFocus, isTrue);
      control.focusNode!.requestFocus();
      await tester.pump(const Duration(milliseconds: 150));
      final decoration = tester
          .widget<AnimatedContainer>(visualTab)
          .decoration!;
      expect(
        ((decoration as BoxDecoration).border! as Border).top.color,
        Theme.of(tester.element(affordance)).colorScheme.primary,
      );

      await tester.drag(affordance, Offset(-surfaceSize.width, 20));
      await _settle(tester);
      expect(tester.getTopLeft(affordance).dx, 0);
      semantics.dispose();
    },
  );

  testWidgets('feedback edge tab yields to an active owned workspace surface', (
    tester,
  ) async {
    const config = ReadyFeedbackConfig(
      applicationName: 'Perfect!',
      storageNamespace: 'feedback-overlay-suppression-test',
      settingsKey: 'feedback.suppression.enabled',
    );
    final controller = ReadyFeedbackController(
      config: config,
      repository: _MemoryRepository(config: config),
      settingsStore: _MemorySettings(),
      logger: ReadyFeedbackLogger(memoryLimit: 20),
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadyFeedbackOverlay(
            controller: controller,
            routeName: 'Focused surface',
            launcherVisible: false,
            child: const ColoredBox(color: Color(0xFFF6F1EA)),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('ready-feedback-affordance')),
      findsNothing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadyFeedbackOverlay(
            controller: controller,
            routeName: 'Focused surface',
            child: const ColoredBox(color: Color(0xFFF6F1EA)),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('ready-feedback-affordance')),
      findsOneWidget,
    );
  });

  testWidgets(
    'screenshot is previewed before save and review stays privacy-explicit',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const config = ReadyFeedbackConfig(
        applicationName: 'Perfect!',
        storageNamespace: 'feedback-overlay-test',
        settingsKey: 'feedback.enabled',
      );
      final repository = _MemoryRepository(config: config);
      final controller = ReadyFeedbackController(
        config: config,
        repository: repository,
        settingsStore: _MemorySettings(),
        logger: ReadyFeedbackLogger(memoryLimit: 20),
        idFactory: () => 'synthetic-capture-id',
      );
      addTearDown(controller.dispose);
      await tester.runAsync(controller.initialize);
      var captureCount = 0;
      var captureSawFloatingButton = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadyFeedbackOverlay(
              controller: controller,
              routeName: 'Synthetic test route',
              screenshotProvider: () async {
                captureCount++;
                captureSawFloatingButton = find
                    .byTooltip('Capture feedback')
                    .evaluate()
                    .isNotEmpty;
                return ReadyFeedbackScreenshotCapture(
                  bytes: base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
                    'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                  ),
                  pixelRatio: 1,
                );
              },
              child: const ColoredBox(
                color: Color(0xFFF6F1EA),
                child: Center(child: Text('Private planner surface')),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      await _openScreenshotDraft(tester);
      expect(captureCount, 1);
      expect(captureSawFloatingButton, isFalse);
      expect(
        find.bySemanticsLabel('Captured app screenshot preview'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Review this image now. Text credentials are redacted, '
          'but screenshot pixels are saved exactly as shown.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(controller.entryCount, 0);
      expect(repository.addCalls, 0);

      await _openScreenshotDraft(tester);
      expect(captureCount, 2);
      await tester.enterText(
        find.byType(TextField),
        'Synthetic screenshot feedback',
      );
      await tester.tap(find.text('Save privately'));
      await _settle(tester);
      expect(controller.entryCount, 1);
      expect(repository.addCalls, 1);

      await tester.tap(find.byTooltip('Capture feedback'));
      await _settle(tester);
      await tester.ensureVisible(find.text('Captured entries'));
      await tester.tap(find.text('Captured entries'));
      await _settle(tester);
      expect(find.text('Synthetic screenshot feedback'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.text('Synthetic screenshot feedback'));
      await _settle(tester);
      expect(
        find.text(
          'Screenshot pixels are stored exactly as captured and '
          'are not redacted.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Done'));
      await _settle(tester);

      await tester.tap(find.byTooltip('Export private bundle'));
      await _settle(tester);
      expect(
        find.textContaining('Screenshot pixels are not redacted at all'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      semantics.dispose();
    },
  );

  testWidgets('read, clear, and partial delete failures stay recoverable', (
    tester,
  ) async {
    const config = ReadyFeedbackConfig(
      applicationName: 'Perfect!',
      storageNamespace: 'feedback-overlay-errors-test',
      settingsKey: 'feedback.enabled',
    );
    late final Directory temporary;
    await tester.runAsync(() async {
      temporary = await Directory.systemTemp.createTemp(
        'perfect-feedback-overlay-errors-',
      );
    });
    addTearDown(() => temporary.delete(recursive: true));
    var failStoreRoot = false;
    final repository = _MemoryRepository(
      config: config,
      rootDirectoryResolver: () async {
        if (failStoreRoot) {
          throw const ReadyFeedbackStorageException(
            'Synthetic clear storage failure.',
          );
        }
        return temporary;
      },
    );
    final logger = ReadyFeedbackLogger(
      memoryLimit: 20,
      retryDelays: const <Duration>[],
    );
    addTearDown(logger.dispose);
    final controller = ReadyFeedbackController(
      config: config,
      repository: repository,
      settingsStore: _MemorySettings(),
      logger: logger,
      idFactory: () => 'synthetic-error-entry',
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.initialize);
    await controller.addEntry(
      route: 'Synthetic route',
      note: 'Synthetic recoverable feedback',
      kind: ReadyFeedbackKind.error,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadyFeedbackOverlay(
            controller: controller,
            routeName: 'Synthetic route',
            child: const ColoredBox(color: Color(0xFFF6F1EA)),
          ),
        ),
      ),
    );
    await _settle(tester);
    await _openEntries(tester);

    repository.failPreview = true;
    await tester.tap(find.byTooltip('Export private bundle'));
    await _settle(tester);
    expect(
      find.text('Could not read the private feedback folder. Try again.'),
      findsOneWidget,
    );
    await _dismissSnackBar(tester);
    repository.failPreview = false;

    repository.failRecoveryPreview = true;
    await tester.tap(find.byTooltip('Export private bundle'));
    await _settle(tester);
    expect(
      find.textContaining('Private screenshots were preserved'),
      findsOneWidget,
    );
    await _dismissSnackBar(tester);
    repository.failRecoveryPreview = false;

    failStoreRoot = true;
    await tester.tap(find.byTooltip('Clear all entries and logs'));
    await _settle(tester);
    expect(
      find.textContaining(
        'ZIPs you explicitly saved or shared outside Perfect remain',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('delete those copies separately'),
      findsOneWidget,
    );
    await tester.tap(find.text('Clear all'));
    await _settle(tester);
    expect(
      find.text('Could not clear the private feedback folder.'),
      findsOneWidget,
    );
    await _dismissSnackBar(tester);
    failStoreRoot = false;

    repository.failDeleteCleanup = true;
    await tester.tap(find.byTooltip('Delete entry'));
    await _settle(tester);
    expect(
      find.textContaining(
        'Active records were removed, but a private recovery artifact or '
        'Perfect-managed temporary export could not be deleted',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Saved or shared ZIPs outside Perfect remain'),
      findsOneWidget,
    );
    expect(controller.entryCount, 0);
  });

  testWidgets('owner-confirmed recovery preserves artifacts and unbricks UI', (
    tester,
  ) async {
    const config = ReadyFeedbackConfig(
      applicationName: 'Perfect!',
      storageNamespace: 'feedback-overlay-recovery-test',
      settingsKey: 'feedback.enabled',
    );
    final repository = _MemoryRepository(config: config)
      ..failEntryReadRecovery = true;
    final logger = ReadyFeedbackLogger(memoryLimit: 20);
    addTearDown(logger.dispose);
    final controller = ReadyFeedbackController(
      config: config,
      repository: repository,
      settingsStore: _MemorySettings(),
      logger: logger,
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadyFeedbackOverlay(
            controller: controller,
            routeName: 'Synthetic recovery route',
            child: const ColoredBox(color: Color(0xFFF6F1EA)),
          ),
        ),
      ),
    );
    await _settle(tester);
    await _openEntries(tester);
    expect(find.text('Recover safely'), findsOneWidget);

    await tester.tap(find.text('Recover safely'));
    await _settle(tester);
    expect(find.text('Preserve & recover'), findsOneWidget);
    expect(
      find.textContaining('Nothing is shared or silently deleted'),
      findsOneWidget,
    );
    await tester.tap(find.text('Preserve & recover'));
    await _settle(tester);

    expect(repository.recoveryCalls, 1);
    expect(find.text('No captured entries yet.'), findsOneWidget);
    expect(
      find.textContaining('Recovery copy preserved locally'),
      findsOneWidget,
    );
  });
}

Future<void> _openScreenshotDraft(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Capture feedback'));
  await _settle(tester);
  await tester.tap(find.text('Screenshot + note'));
  await _settle(tester);
}

Future<void> _openEntries(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Capture feedback'));
  await _settle(tester);
  await tester.ensureVisible(find.text('Captured entries'));
  await tester.tap(find.text('Captured entries'));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 2),
);

Future<void> _dismissSnackBar(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  await _settle(tester);
}

class _MemorySettings implements ReadyFeedbackSettingsStore {
  @override
  Future<bool?> readEnabled() async => true;

  @override
  Future<void> writeEnabled(bool value) async {}
}

class _MemoryRepository extends ReadyFeedbackRepository {
  _MemoryRepository({required super.config, super.rootDirectoryResolver});

  final List<ReadyFeedbackEntry> _entries = <ReadyFeedbackEntry>[];
  final Map<String, Uint8List> _screenshots = <String, Uint8List>{};
  final List<ReadyFeedbackLogRecord> _logs = <ReadyFeedbackLogRecord>[];
  int addCalls = 0;
  bool failPreview = false;
  bool failRecoveryPreview = false;
  bool failDeleteCleanup = false;
  bool failEntryReadRecovery = false;
  int recoveryCalls = 0;

  @override
  Future<List<ReadyFeedbackEntry>> readEntries() async {
    if (failEntryReadRecovery) {
      throw const ReadyFeedbackIndexRecoveryException(
        'Synthetic entry index recovery state.',
      );
    }
    return List<ReadyFeedbackEntry>.unmodifiable(_entries);
  }

  @override
  Future<ReadyFeedbackEntry> addEntry(
    ReadyFeedbackEntry entry, {
    ReadyFeedbackScreenshotCapture? screenshot,
    Uint8List? screenshotBytes,
  }) async {
    addCalls++;
    final bytes = screenshot?.bytes ?? screenshotBytes;
    final stored = bytes == null
        ? entry
        : entry.copyWith(
            screenshotFileName: '${entry.id}.png',
            screenshotWidthPx: 1,
            screenshotHeightPx: 1,
            screenshotByteLength: bytes.lengthInBytes,
            screenshotPixelRatio: screenshot?.pixelRatio ?? 1,
          );
    _entries
      ..add(stored)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    if (bytes != null) _screenshots[stored.screenshotFileName!] = bytes;
    return stored;
  }

  @override
  Future<Uint8List?> readScreenshot(ReadyFeedbackEntry entry) async =>
      _screenshots[entry.screenshotFileName];

  @override
  Future<void> deleteEntry(String id) async {
    final matches = _entries.where((entry) => entry.id == id).toList();
    _entries.removeWhere((entry) => entry.id == id);
    for (final entry in matches) {
      _screenshots.remove(entry.screenshotFileName);
    }
    if (failDeleteCleanup) {
      throw const ReadyFeedbackCleanupException(
        'Synthetic committed screenshot cleanup failure.',
      );
    }
  }

  @override
  Future<void> clearAll() async {
    _entries.clear();
    _screenshots.clear();
    _logs.clear();
  }

  @override
  Future<void> appendLog(ReadyFeedbackLogRecord record) async {
    _logs.add(record);
  }

  @override
  Future<ReadyFeedbackRepositorySnapshot> createExportSnapshot() async {
    if (failRecoveryPreview) {
      throw const ReadyFeedbackIndexRecoveryException(
        'Synthetic index recovery state.',
      );
    }
    if (failPreview) {
      throw const ReadyFeedbackStorageException(
        'Synthetic export preview failure.',
      );
    }
    return ReadyFeedbackRepositorySnapshot(
      entries: _entries,
      logs: _logs,
      screenshots: _screenshots,
    );
  }

  @override
  Future<ReadyFeedbackRecoveryResult> recoverCorruptStore({
    required bool ownerConfirmed,
  }) async {
    if (!ownerConfirmed) throw ArgumentError('Synthetic confirmation needed.');
    recoveryCalls++;
    failEntryReadRecovery = false;
    _entries.clear();
    _screenshots.clear();
    return ReadyFeedbackRecoveryResult(
      directory: Directory('X:/synthetic-feedback-recovery'),
      artifactCount: 4,
      screenshotCount: 1,
    );
  }
}
