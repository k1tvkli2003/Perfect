import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'emoji guard catches glyphs and escapes without banning punctuation',
    () {
      expect(_rawEmoji.hasMatch(String.fromCharCode(0x1f331)), isTrue);
      expect(_escapedEmoji.hasMatch(r'\u{1F331}'), isTrue);
      expect(_rawEmoji.hasMatch('Today’s flow — 50% → done…'), isFalse);
    },
  );

  test('user-facing Flutter surfaces do not ship raw keyboard emoji', () {
    final violations = <String>[];
    final files = <File>[
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('assets')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) => <String>{
              '.svg',
              '.json',
              '.yaml',
            }.contains(_extension(file.path)),
          ),
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      final lines = source.split('\n');
      for (var index = 0; index < lines.length; index++) {
        if (_rawEmoji.hasMatch(lines[index]) ||
            _escapedEmoji.hasMatch(lines[index])) {
          violations.add('${file.path}:${index + 1}: ${lines[index].trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use a project-owned SVG pictogram or a semantic Flutter icon, '
          'not a raw keyboard emoji:\n${violations.join('\n')}',
    );
  });

  test('Perfect pictogram SVGs stay scalable, text-free, and transparent', () {
    final files =
        Directory('assets/icons/perfect')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.svg'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, hasLength(11));
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, contains('viewBox="0 0 24 24"'), reason: file.path);
      expect(source, isNot(contains('<text')), reason: file.path);
      expect(source, isNot(contains('<rect width="24" height="24"')));
      expect(source, isNot(contains('font-family')), reason: file.path);
    }
  });
}

final _rawEmoji = RegExp(
  '['
  r'\u{1F000}-\u{1FAFF}'
  r'\u{2300}-\u{23FF}'
  r'\u{2600}-\u{27BF}'
  r'\u{1F1E6}-\u{1F1FF}'
  r'\u{FE0F}'
  ']',
  unicode: true,
);

final _escapedEmoji = RegExp(
  r'\\u(?:\{(?:1[fF][0-9a-fA-F]{3,4}|2[36][0-9a-fA-F]{2}|27[0-9a-fA-F]{2})\}'
  r'|(?:23|26|27)[0-9a-fA-F]{2})',
);

String _extension(String path) {
  final index = path.lastIndexOf('.');
  return index < 0 ? '' : path.substring(index).toLowerCase();
}
