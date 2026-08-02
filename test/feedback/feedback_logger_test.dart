import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/feedback/ready_feedback_capture.dart';

void main() {
  const config = ReadyFeedbackConfig(
    applicationName: 'Perfect!',
    storageNamespace: 'feedback-logger-test',
    settingsKey: 'feedback.enabled',
    maxLogs: 10,
  );

  test(
    'pre-attach logs persist once and detached logs stay quarantined',
    () async {
      final repository = _RecordingRepository(config: config);
      final logger = ReadyFeedbackLogger(memoryLimit: 10);
      addTearDown(logger.dispose);

      logger.info('synthetic-before-attach');
      logger.attachRepository(repository);
      logger.attachRepository(repository);
      await _waitFor(() => repository.records.length == 1);

      logger.detachRepository(repository);
      logger.warning('synthetic-while-detached');
      logger.attachRepository(repository);
      logger.warning('synthetic-after-reattach');
      await _waitFor(() => repository.records.length == 2);

      expect(repository.records.map((record) => record.message), <String>[
        'synthetic-before-attach',
        'synthetic-after-reattach',
      ]);
    },
  );

  test(
    'failed records from one owner never drain into another owner',
    () async {
      final ownerA = Object();
      final ownerB = Object();
      final repositoryA = _RecordingRepository(config: config, failures: 100);
      final repositoryB = _RecordingRepository(config: config);
      final logger = ReadyFeedbackLogger(
        memoryLimit: 10,
        retryDelays: const <Duration>[Duration(seconds: 1)],
      );
      addTearDown(logger.dispose);

      logger.attachRepository(repositoryA, owner: ownerA);
      logger.error('synthetic-owner-a');
      await _waitFor(() => repositoryA.attempts == 1);
      logger.detachRepository(repositoryA, owner: ownerA);
      logger.attachRepository(repositoryB, owner: ownerB);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repositoryB.records, isEmpty);

      logger.info('synthetic-owner-b');
      await _waitFor(() => repositoryB.records.length == 1);
      expect(repositoryB.records.single.message, 'synthetic-owner-b');
    },
  );

  test('append failures retry with a bounded schedule', () async {
    final repository = _RecordingRepository(config: config, failures: 2);
    final logger = ReadyFeedbackLogger(
      retryDelays: const <Duration>[
        Duration(milliseconds: 1),
        Duration(milliseconds: 1),
        Duration(milliseconds: 1),
      ],
    );
    addTearDown(logger.dispose);

    logger.attachRepository(repository, owner: const _Owner('retry'));
    logger.error('synthetic-retry-record');
    await _waitFor(() => repository.records.length == 1);
    expect(repository.attempts, 3);
  });

  test('detach cancels retry and same-owner reattach resumes safely', () async {
    const owner = _Owner('detached-retry');
    final repository = _RecordingRepository(config: config, failures: 1);
    final logger = ReadyFeedbackLogger(
      retryDelays: const <Duration>[Duration(milliseconds: 60)],
    );
    addTearDown(logger.dispose);

    logger.attachRepository(repository, owner: owner);
    logger.error('synthetic-detach-record');
    await _waitFor(() => repository.attempts == 1);
    logger.detachRepository(repository, owner: owner);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(repository.attempts, 1);

    logger.attachRepository(repository, owner: owner);
    await _waitFor(() => repository.records.length == 1);
    expect(repository.attempts, 2);
  });
}

class _Owner {
  const _Owner(this.name);

  final String name;
}

class _RecordingRepository extends ReadyFeedbackRepository {
  _RecordingRepository({required super.config, this.failures = 0})
    : super(rootDirectoryResolver: () async => Directory.systemTemp);

  final int failures;
  final List<ReadyFeedbackLogRecord> records = <ReadyFeedbackLogRecord>[];
  int attempts = 0;

  @override
  Future<void> appendLog(ReadyFeedbackLogRecord record) async {
    attempts++;
    if (attempts <= failures) {
      throw FileSystemException(
        'Synthetic append failure',
        'X:/not-a-real-feedback-log.json',
      );
    }
    records.add(record);
  }
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for the synthetic logger condition.');
}
