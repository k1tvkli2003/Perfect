import 'dart:io';
import 'dart:typed_data';

import 'package:perfect/ai/perfect_ai_contract.dart';
import 'package:record/record.dart';

abstract interface class PerfectVoiceRecorder {
  Future<bool> hasPermission();

  Future<void> start();

  Future<PerfectVoiceClip?> stop();

  Future<void> cancel();

  Future<void> dispose();
}

class NativePerfectVoiceRecorder implements PerfectVoiceRecorder {
  NativePerfectVoiceRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  Directory? _workingDirectory;
  DateTime? _startedAt;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    await cancel();
    final directory = await Directory.systemTemp.createTemp(
      'perfect_ai_voice_',
    );
    _workingDirectory = directory;
    _startedAt = DateTime.now();
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: '${directory.path}${Platform.pathSeparator}voice.wav',
      );
    } on Object {
      _startedAt = null;
      await _deleteWorkingDirectory();
      rethrow;
    }
  }

  @override
  Future<PerfectVoiceClip?> stop() async {
    final path = await _recorder.stop();
    final startedAt = _startedAt;
    _startedAt = null;
    if (path == null || startedAt == null) {
      await _deleteWorkingDirectory();
      return null;
    }
    try {
      final bytes = await File(path).readAsBytes();
      final duration = DateTime.now().difference(startedAt);
      if (bytes.isEmpty ||
          bytes.length > PerfectVoiceClip.maxBytes ||
          duration > PerfectVoiceClip.maxDuration) {
        throw const PerfectAiException(
          code: PerfectAiErrorCode.invalidInput,
          message: 'Voice notes must be shorter than 45 seconds.',
          retryable: false,
        );
      }
      return PerfectVoiceClip(
        bytes: Uint8List.fromList(bytes),
        mimeType: 'audio/wav',
        duration: duration,
      );
    } finally {
      await _deleteWorkingDirectory();
    }
  }

  @override
  Future<void> cancel() async {
    _startedAt = null;
    try {
      await _recorder.cancel();
    } on Object {
      // Cleanup below is the privacy boundary even if the native recorder has
      // already stopped during an app lifecycle transition.
    }
    await _deleteWorkingDirectory();
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }

  Future<void> _deleteWorkingDirectory() async {
    final directory = _workingDirectory;
    _workingDirectory = null;
    if (directory == null || !await directory.exists()) return;
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // Some Windows audio drivers retain the handle briefly after stop. The
      // native recorder has already been cancelled; a later OS temp cleanup
      // can collect the inaccessible directory without exposing its content.
    }
  }
}
