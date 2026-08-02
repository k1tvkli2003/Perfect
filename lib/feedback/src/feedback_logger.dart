import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:perfect/feedback/src/feedback_models.dart';
import 'package:perfect/feedback/src/feedback_redactor.dart';
import 'package:perfect/feedback/src/feedback_repository.dart';

class ReadyFeedbackLogger {
  ReadyFeedbackLogger({
    int memoryLimit = 300,
    List<Duration> retryDelays = const <Duration>[
      Duration(seconds: 1),
      Duration(seconds: 5),
      Duration(seconds: 30),
    ],
  }) : assert(retryDelays.every((delay) => !delay.isNegative)),
       _retryDelays = List<Duration>.unmodifiable(retryDelays),
       assert(memoryLimit > 0),
       _memoryLimit = memoryLimit;

  static final ReadyFeedbackLogger instance = ReadyFeedbackLogger();

  final ListQueue<ReadyFeedbackLogRecord> _memory =
      ListQueue<ReadyFeedbackLogRecord>();
  final ListQueue<_PendingLogRecord> _pendingPersistence =
      ListQueue<_PendingLogRecord>();
  final List<Duration> _retryDelays;
  ReadyFeedbackRepository? _repository;
  Object? _owner;
  Object? _detachedOwner;
  int _memoryLimit;
  bool _handlersInstalled = false;
  bool _draining = false;
  bool _hasEverAttached = false;
  bool _disposed = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  static final Object _unscopedOwner = Object();

  List<ReadyFeedbackLogRecord> get recent =>
      List<ReadyFeedbackLogRecord>.unmodifiable(_memory);

  void installGlobalErrorCapture() {
    if (_handlersInstalled) return;
    _handlersInstalled = true;

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      error(
        details.exceptionAsString(),
        stackTrace: details.stack,
        context: details.context?.toDescription(),
      );
      if (previousFlutterHandler != null) {
        previousFlutterHandler(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final dispatcher = PlatformDispatcher.instance;
    final previousPlatformHandler = dispatcher.onError;
    dispatcher.onError = (exception, stackTrace) {
      error(exception, stackTrace: stackTrace, context: 'Uncaught async error');
      return previousPlatformHandler?.call(exception, stackTrace) ?? false;
    };
  }

  void attachRepository(ReadyFeedbackRepository repository, {Object? owner}) {
    if (_disposed) return;
    final resolvedOwner = owner ?? repository;
    final firstAttachment = !_hasEverAttached;
    _hasEverAttached = true;
    final sameScope =
        identical(_owner, resolvedOwner) ||
        (_repository == null && identical(_detachedOwner, resolvedOwner));
    if (!sameScope) {
      _pendingPersistence.removeWhere(
        (pending) =>
            !identical(pending.owner, resolvedOwner) &&
            !(firstAttachment && identical(pending.owner, _unscopedOwner)),
      );
      _retryAttempt = 0;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _repository = repository;
    _owner = resolvedOwner;
    _detachedOwner = null;
    _memoryLimit = repository.config.maxLogs;
    _trimMemory();
    _scheduleDrain();
  }

  void detachRepository(ReadyFeedbackRepository repository, {Object? owner}) {
    final resolvedOwner = owner ?? repository;
    if (identical(_repository, repository) &&
        identical(_owner, resolvedOwner)) {
      _repository = null;
      _owner = null;
      _detachedOwner = resolvedOwner;
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  void clearBuffer() {
    _memory.clear();
    _pendingPersistence.clear();
    _retryAttempt = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _repository = null;
    _owner = null;
    _detachedOwner = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _pendingPersistence.clear();
  }

  void error(Object message, {StackTrace? stackTrace, String? context}) =>
      _record(
        ReadyFeedbackLogLevel.error,
        _withContext(message, context),
        stackTrace,
      );

  void warning(Object message, {StackTrace? stackTrace, String? context}) =>
      _record(
        ReadyFeedbackLogLevel.warning,
        _withContext(message, context),
        stackTrace,
      );

  void info(Object message, {String? context}) =>
      _record(ReadyFeedbackLogLevel.info, _withContext(message, context), null);

  void debug(Object message, {String? context}) => _record(
    ReadyFeedbackLogLevel.debug,
    _withContext(message, context),
    null,
  );

  String _withContext(Object message, String? context) {
    final prefix = context?.trim();
    return prefix == null || prefix.isEmpty ? '$message' : '$prefix: $message';
  }

  void _record(
    ReadyFeedbackLogLevel level,
    String message,
    StackTrace? stackTrace,
  ) {
    if (_disposed) return;
    final record = ReadyFeedbackLogRecord(
      createdAt: DateTime.now().toUtc(),
      level: level,
      message: ReadyFeedbackRedactor.redact(message),
      stackTrace: stackTrace == null
          ? null
          : ReadyFeedbackRedactor.redact('$stackTrace'),
    );
    _memory.addFirst(record);
    _trimMemory();
    final owner = _owner;
    if (owner != null) {
      _pendingPersistence.addLast(_PendingLogRecord(owner, record));
    } else if (!_hasEverAttached) {
      _pendingPersistence.addLast(_PendingLogRecord(_unscopedOwner, record));
    }
    _scheduleDrain();
  }

  void _trimMemory() {
    while (_memory.length > _memoryLimit) {
      _memory.removeLast();
    }
  }

  void _scheduleDrain() {
    final repository = _repository;
    final owner = _owner;
    if (_disposed ||
        _draining ||
        _retryTimer != null ||
        repository == null ||
        owner == null ||
        _pendingPersistence.isEmpty) {
      return;
    }
    _draining = true;
    unawaited(_drain(repository, owner));
  }

  Future<void> _drain(ReadyFeedbackRepository repository, Object owner) async {
    var failed = false;
    try {
      while (identical(_repository, repository) &&
          identical(_owner, owner) &&
          _pendingPersistence.isNotEmpty) {
        final pending = _pendingPersistence.first;
        if (!identical(pending.owner, owner) &&
            !identical(pending.owner, _unscopedOwner)) {
          _pendingPersistence.removeFirst();
          continue;
        }
        try {
          await repository.appendLog(pending.record);
        } on Object {
          failed = true;
          break;
        }
        if (_pendingPersistence.isNotEmpty &&
            identical(_pendingPersistence.first, pending)) {
          _pendingPersistence.removeFirst();
        }
        _retryAttempt = 0;
      }
    } finally {
      _draining = false;
      if (failed &&
          identical(_repository, repository) &&
          identical(_owner, owner)) {
        _scheduleRetry(repository, owner);
      } else if (_repository != null && _pendingPersistence.isNotEmpty) {
        _scheduleDrain();
      }
    }
  }

  void _scheduleRetry(ReadyFeedbackRepository repository, Object owner) {
    if (_retryAttempt >= _retryDelays.length || _disposed) return;
    final delay = _retryDelays[_retryAttempt++];
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (identical(_repository, repository) && identical(_owner, owner)) {
        _scheduleDrain();
      }
    });
  }
}

class _PendingLogRecord {
  const _PendingLogRecord(this.owner, this.record);

  final Object owner;
  final ReadyFeedbackLogRecord record;
}
