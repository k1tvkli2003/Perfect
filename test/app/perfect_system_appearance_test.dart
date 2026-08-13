import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/app/perfect_system_appearance.dart';
import 'package:perfect/presentation/perfect_theme.dart';

void main() {
  test(
    'native appearance bridge deduplicates one exact semantic snapshot',
    () async {
      final calls = <Map<String, Object?>>[];
      final bridge = PerfectSystemAppearanceBridge(
        invoker: (method, arguments) async {
          expect(method, 'apply');
          calls.add(arguments);
          return null;
        },
      );
      const snapshot = PerfectSystemAppearanceSnapshot(
        themeMode: ThemeMode.dark,
        dark: true,
        highContrast: true,
        themeId: 'theme-hc-dark-clarity',
        canvas: Color(0xff000000),
        ink: Color(0xffffffff),
        outline: Color(0xffffffff),
      );

      await bridge.apply(snapshot);
      await bridge.apply(snapshot);

      expect(calls, hasLength(1));
      expect(calls.single, <String, Object?>{
        'themeMode': 'dark',
        'dark': true,
        'highContrast': true,
        'themeId': 'theme-hc-dark-clarity',
        'canvasArgb': 0xff000000,
        'inkArgb': 0xffffffff,
        'outlineArgb': 0xffffffff,
      });
    },
  );

  testWidgets(
    'projection paints immediately while native work remains non-blocking',
    (tester) async {
      final nativeCompletion = Completer<Object?>();
      final payloads = <Map<String, Object?>>[];
      final bridge = PerfectSystemAppearanceBridge(
        invoker: (method, arguments) {
          payloads.add(arguments);
          return nativeCompletion.future;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PerfectTheme.highContrastLight(),
          home: PerfectSystemAppearanceProjection(
            themeMode: ThemeMode.light,
            contrastMode: PerfectContrastMode.high,
            bridge: bridge,
            child: const ColoredBox(
              key: ValueKey<String>('planner-first-frame'),
              color: Colors.transparent,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('planner-first-frame')),
        findsOneWidget,
      );
      expect(payloads, hasLength(1));
      expect(payloads.single['themeId'], 'theme-hc-light-clarity');
      expect(payloads.single['highContrast'], isTrue);
      expect(nativeCompletion.isCompleted, isFalse);

      await tester.pump();
      expect(payloads, hasLength(1));
      nativeCompletion.complete(null);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
