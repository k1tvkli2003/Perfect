import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native widget keeps its resize, scroll, security, and rollover contract',
    () {
      final provider = File(
        'android/app/src/main/kotlin/com/k1tvkli2003/perfect/'
        'PerfectTodayWidgetProvider.kt',
      ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final mainActivity = File(
        'android/app/src/main/kotlin/com/k1tvkli2003/perfect/MainActivity.kt',
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
      final regularItem = File(
        'android/app/src/main/res/layout/perfect_today_widget_item.xml',
      ).readAsStringSync();
      final quickAddActivity = File(
        'android/app/src/main/kotlin/com/k1tvkli2003/perfect/'
        'PerfectWidgetQuickAddActivity.kt',
      ).readAsStringSync();
      final quickAddLayout = File(
        'android/app/src/main/res/layout/perfect_widget_quick_add.xml',
      ).readAsStringSync();
      final layouts = <String>[
        for (final size in <String>['small', 'tall', 'wide', 'large'])
          File(
            'android/app/src/main/res/layout/perfect_today_widget_$size.xml',
          ).readAsStringSync(),
      ];
      const densities = <String>['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
      const appearanceSuffixes = <String>['', '_dark', '_hc_light', '_hc_dark'];

      expect(layouts.every((layout) => layout.contains('<ListView')), isTrue);
      expect(
        layouts.every(
          (layout) => layout.contains('android:id="@+id/widget_root"'),
        ),
        isTrue,
      );
      expect(
        layouts.every(
          (layout) => layout.contains('android:id="@+id/widget_brand_mark"'),
        ),
        isTrue,
      );
      expect(
        layouts.every(
          (layout) => layout.contains('android:id="@+id/widget_quick_add"'),
        ),
        isTrue,
      );
      expect(provider, contains('onAppWidgetOptionsChanged'));
      expect(provider, contains('perfect_today_widget_small'));
      expect(provider, contains('perfect_today_widget_tall'));
      expect(
        provider,
        contains('Build.VERSION.SDK_INT >= Build.VERSION_CODES.S'),
      );
      expect(provider, contains('RemoteViews('));
      expect(provider, contains('linkedMapOf('));
      expect(provider, contains('SizeF(110f, 110f)'));
      expect(provider, contains('SizeF(110f, 180f)'));
      expect(provider, contains('SizeF(220f, 110f)'));
      expect(provider, contains('SizeF(260f, 220f)'));
      expect(provider, contains('PerfectTodayWidgetRefreshReceiver'));
      expect(provider, contains('setImageViewResource'));
      expect(provider, contains('PerfectNativeAppearance.resolve'));
      expect(provider, contains('R.id.widget_root'));
      expect(provider, contains('appearance.widgetSurfaceResource'));
      expect(provider, contains('appearance.markResource'));
      expect(provider, contains('appearance.wordmarkResource'));
      expect(provider, contains('perfect_widget_status_completed'));
      expect(provider, isNot(contains('"completed" -> "✓"')));
      expect(provider, contains('setAndAllowWhileIdle'));
      expect(provider, contains('dateKey != LocalDate.now().toString()'));
      expect(provider, contains('PendingIntent.FLAG_MUTABLE'));
      expect(provider, contains('PerfectWidgetQuickAddActivity::class.java'));
      expect(
        provider,
        contains('setOnClickPendingIntent(R.id.widget_quick_add'),
      );
      expect(provider, contains('PENDING_QUICK_ADDS_KEY'));
      expect(provider, contains('ACKNOWLEDGED_QUICK_ADDS_KEY'));
      expect(provider, contains('private const val MAX_QUICK_ADDS = 256'));
      expect(provider, contains('fun enqueueQuickAdd('));
      expect(provider, isNot(contains('.appendQueryParameter("title"')));
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
      expect(compactItem, contains('<ImageView'));
      expect(compactItem, isNot(contains('android:text="○"')));
      expect(compactItem, isNot(contains('widget_item_state')));
      expect(compactItem, contains('android:textDirection="locale"'));
      expect(regularItem, contains('android:layout_width="64dp"'));
      expect(compactItem, contains('android:layout_width="48dp"'));
      expect(
        RegExp('android:maxLines="2"').allMatches(regularItem),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(
        provider,
        contains(
          '"pending" -> "completed"\n'
          '    "completed" -> "missed"\n'
          '    "missed" -> "partial"',
        ),
      );
      expect(info, contains('android:resizeMode="horizontal|vertical"'));
      expect(info, contains('android:minResizeWidth="110dp"'));
      expect(info, contains('android:minResizeHeight="110dp"'));
      expect(info, contains('android:updatePeriodMillis="1800000"'));
      expect(
        manifest,
        contains('android:name=".PerfectTodayWidgetRefreshReceiver"'),
      );
      expect(
        manifest,
        contains('android:permission="android.permission.BIND_REMOTEVIEWS"'),
      );
      expect(
        manifest,
        contains('android:name=".PerfectWidgetQuickAddActivity"'),
      );
      expect(manifest, contains('android:excludeFromRecents="true"'));
      expect(manifest, contains('android:noHistory="true"'));
      expect(
        quickAddActivity,
        contains('PerfectTodayWidgetStore.enqueueQuickAdd'),
      );
      expect(
        quickAddActivity,
        contains('applyAppearance(PerfectNativeAppearance.resolve'),
      );
      expect(quickAddActivity, contains('appearance.highContrast'));
      expect(quickAddActivity, contains('appearance.markResource'));
      expect(
        quickAddActivity,
        contains('HomeWidgetBackgroundIntent.getBroadcast'),
      );
      expect(quickAddActivity, isNot(contains('PlannerDatabase')));
      expect(quickAddActivity, isNot(contains('PlannerLocalStore')));
      expect(quickAddLayout, contains('android:maxLength="160"'));
      expect(quickAddLayout, contains('android:imeOptions="actionDone"'));
      expect(
        quickAddLayout,
        contains('android:accessibilityLiveRegion="polite"'),
      );
      expect(manifest, contains('android:supportsRtl="true"'));
      expect(
        layouts.every(
          (layout) => layout.contains('android:layoutDirection="locale"'),
        ),
        isTrue,
      );
      expect(
        mainActivity,
        contains('com.k1tvkli2003.perfect/system_appearance'),
      );
      expect(mainActivity, contains('perfect_appearance_theme_id'));
      expect(mainActivity, contains('perfect_appearance_high_contrast'));
      expect(mainActivity, contains('setApplicationNightMode'));
      expect(mainActivity, contains('PerfectTodayWidgetProvider.refresh'));

      for (final density in densities) {
        for (final suffix in appearanceSuffixes) {
          expect(
            File(
              'android/app/src/main/res/drawable-$density/'
              'perfect_widget_mark${suffix}_raster.png',
            ).existsSync(),
            isTrue,
            reason: 'missing $density mark$suffix',
          );
          expect(
            File(
              'android/app/src/main/res/drawable-$density/'
              'perfect_widget_wordmark${suffix}_raster.png',
            ).existsSync(),
            isTrue,
            reason: 'missing $density wordmark$suffix',
          );
        }
      }
      for (final suffix in appearanceSuffixes) {
        expect(
          File(
            'android/app/src/main/res/drawable/'
            'perfect_widget_surface$suffix.xml',
          ).existsSync(),
          isTrue,
          reason: 'missing widget surface$suffix',
        );
        for (final state in <String>[
          'pending',
          'completed',
          'partial',
          'missed',
        ]) {
          expect(
            File(
              'android/app/src/main/res/drawable/'
              'perfect_widget_status_$state$suffix.xml',
            ).existsSync(),
            isTrue,
            reason: 'missing $state status$suffix',
          );
        }
      }
    },
  );
}
