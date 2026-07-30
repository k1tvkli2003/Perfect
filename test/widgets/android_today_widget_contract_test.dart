import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native widget keeps its resize, scroll, security, and rollover contract',
    () {
      final provider = File(
        'android/app/src/main/kotlin/com/k1tvkli2003/perfect/'
        'PerfectTodayWidgetProvider.kt',
      ).readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final info = File(
        'android/app/src/main/res/xml/perfect_today_widget_info.xml',
      ).readAsStringSync();
      final compactItem = File(
        'android/app/src/main/res/layout/'
        'perfect_today_widget_item_compact.xml',
      ).readAsStringSync();
      final layouts = <String>[
        for (final size in <String>['small', 'wide', 'large'])
          File(
            'android/app/src/main/res/layout/perfect_today_widget_$size.xml',
          ).readAsStringSync(),
      ];

      expect(layouts.every((layout) => layout.contains('<ListView')), isTrue);
      expect(provider, contains('onAppWidgetOptionsChanged'));
      expect(provider, contains('perfect_today_widget_small'));
      expect(provider, contains('PerfectTodayWidgetRefreshReceiver'));
      expect(provider, contains('setAndAllowWhileIdle'));
      expect(provider, contains('dateKey != LocalDate.now().toString()'));
      expect(provider, contains('PendingIntent.FLAG_MUTABLE'));
      expect(provider, contains('EXTRA_COMPACT_LAYOUT'));
      expect(provider, contains('perfect_today_widget_item_compact'));
      expect(provider, contains('ACTION_SEQUENCE_KEY'));
      expect(provider, contains('put("queue_sequence", queueSequence)'));
      expect(provider, contains('putLong(ACTION_SEQUENCE_KEY'));
      expect(provider, contains('ACKNOWLEDGED_ACTIONS_KEY'));
      expect(provider, contains('LinkedHashMap<String, JSONObject>()'));
      expect(provider, contains('compacted.remove(nextKey)'));
      expect(provider, contains('private const val MAX_ACTIONS = 4096'));
      expect(provider, contains('QUEUE_OVERFLOW_COUNT_KEY'));
      expect(provider, isNot(contains('prior.length() - (MAX_ACTIONS - 1)')));
      expect(compactItem, contains('android:minHeight="48dp"'));
      expect(compactItem, contains('android:layout_width="48dp"'));
      expect(compactItem, contains('android:id="@+id/widget_item_title"'));
      expect(compactItem, isNot(contains('widget_item_state')));
      expect(compactItem, contains('android:textDirection="locale"'));
      expect(
        provider,
        contains(
          '"pending" -> "completed"\n'
          '    "completed" -> "missed"\n'
          '    "missed" -> "partial"',
        ),
      );
      expect(info, contains('android:resizeMode="horizontal|vertical"'));
      expect(info, contains('android:updatePeriodMillis="1800000"'));
      expect(
        manifest,
        contains('android:name=".PerfectTodayWidgetRefreshReceiver"'),
      );
      expect(
        manifest,
        contains('android:permission="android.permission.BIND_REMOTEVIEWS"'),
      );
      expect(manifest, contains('android:supportsRtl="true"'));
      expect(
        layouts.every(
          (layout) => layout.contains('android:layoutDirection="locale"'),
        ),
        isTrue,
      );
    },
  );
}
