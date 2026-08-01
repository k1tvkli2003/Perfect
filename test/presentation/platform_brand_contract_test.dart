import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Android and Windows expose the approved Perfect! name and icon',
    () async {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final androidStrings = File(
        'android/app/src/main/res/values/strings.xml',
      ).readAsStringSync();
      final windowsMain = File('windows/runner/main.cpp').readAsStringSync();
      final windowsResources = File(
        'windows/runner/Runner.rc',
      ).readAsStringSync();
      final flutterMetadata = File('.metadata').readAsStringSync();
      final launcherConfig = File('pubspec.yaml').readAsStringSync();
      final selectedSource = File('assets/brand/perfect-launcher.png');
      final androidIcon = File(
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      );
      final windowsIcon = File('windows/runner/resources/app_icon.ico');
      final adaptiveIcon = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();
      final launcherColors = File(
        'android/app/src/main/res/values/colors.xml',
      ).readAsStringSync();
      const legacyIcons = <String, int>{
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      const adaptiveForegrounds = <String, int>{
        'mdpi': 108,
        'hdpi': 162,
        'xhdpi': 216,
        'xxhdpi': 324,
        'xxxhdpi': 432,
      };
      const requiredWindowsIconSizes = <int>{
        16,
        20,
        24,
        32,
        40,
        48,
        64,
        128,
        256,
      };
      const forbiddenLauncherResources = <String>[
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
        'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
        'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher_round.xml',
      ];

      expect(manifest, contains('android:label="@string/app_name"'));
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(
        manifest,
        isNot(contains('android:roundIcon')),
        reason:
            'One adaptive icon contract is enough; a separate round override '
            'can drift from the approved mark.',
      );
      expect(
        androidStrings,
        contains('<string name="app_name">Perfect!</string>'),
      );
      expect(
        adaptiveIcon,
        allOf(
          contains('@color/ic_launcher_background'),
          contains('@drawable/ic_launcher_foreground'),
          contains('@drawable/ic_launcher_monochrome'),
          contains('android:inset="10%"'),
        ),
      );
      expect(
        launcherColors,
        contains('<color name="ic_launcher_background">#FFF3E8</color>'),
      );
      for (final forbidden in <String>[
        '#FFFFFF',
        '#FFFFFFFF',
        '#000000',
        '#FF000000',
        '#00FFFFFF',
      ]) {
        expect(
          launcherColors.toUpperCase(),
          isNot(contains('>$forbidden<')),
          reason:
              'The selected Day Compass must not bake a white or black tile '
              'behind its transparent platform mark.',
        );
      }
      expect(launcherConfig, contains('adaptive_icon_background: "#FFF3E8"'));
      expect(
        launcherConfig,
        contains('adaptive_icon_foreground: assets/brand/perfect-launcher.png'),
      );
      expect(launcherConfig, contains('adaptive_icon_foreground_inset: 10'));
      expect(
        launcherConfig,
        contains(
          'adaptive_icon_monochrome: '
          'assets/brand/perfect-launcher-monochrome.png',
        ),
      );
      expect(
        RegExp(
          r'assets/brand/perfect-launcher\.png',
        ).allMatches(launcherConfig).length,
        greaterThanOrEqualTo(3),
        reason:
            'Legacy Android, adaptive Android, and Windows must all derive '
            'from the same approved source mark.',
      );
      for (final path in forbiddenLauncherResources) {
        expect(
          File(path).existsSync(),
          isFalse,
          reason:
              '$path is an unnecessary duplicate launcher override that can '
              'drift from the generated adaptive contract.',
        );
      }
      for (final icon in legacyIcons.entries) {
        final bitmap = File(
          'android/app/src/main/res/mipmap-${icon.key}/ic_launcher.png',
        );
        expect(bitmap.existsSync(), isTrue);
        expect(bitmap.lengthSync(), greaterThan(1000));

        final codec = await ui.instantiateImageCodec(
          await bitmap.readAsBytes(),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final rgba = pixels!.buffer.asUint8List();

        expect(image.width, icon.value);
        expect(image.height, icon.value);
        expect(
          <int>[
            rgba[3],
            rgba[((image.width - 1) * 4) + 3],
            rgba[(((image.height - 1) * image.width) * 4) + 3],
            rgba[((image.width * image.height) - 1) * 4 + 3],
          ],
          everyElement(0),
          reason:
              '${icon.key} launcher corners must remain transparent; a baked '
              'black or white tile is forbidden.',
        );

        image.dispose();
        codec.dispose();
      }
      for (final foreground in adaptiveForegrounds.entries) {
        for (final layer in <String>['foreground', 'monochrome']) {
          final bitmap = File(
            'android/app/src/main/res/drawable-${foreground.key}/'
            'ic_launcher_$layer.png',
          );
          expect(bitmap.existsSync(), isTrue);
          expect(bitmap.lengthSync(), greaterThan(1000));

          final codec = await ui.instantiateImageCodec(
            await bitmap.readAsBytes(),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;
          final pixels = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final rgba = pixels!.buffer.asUint8List();

          expect(image.width, foreground.value);
          expect(image.height, foreground.value);
          expect(
            <int>[
              rgba[3],
              rgba[((image.width - 1) * 4) + 3],
              rgba[(((image.height - 1) * image.width) * 4) + 3],
              rgba[((image.width * image.height) - 1) * 4 + 3],
            ],
            everyElement(0),
            reason:
                '${foreground.key} $layer layer must preserve the Day '
                'Compass without a baked black or white tile.',
          );

          image.dispose();
          codec.dispose();
        }
      }
      expect(windowsMain, contains('window.Create(L"Perfect!"'));
      expect(windowsResources, contains('VALUE "ProductName", "Perfect!"'));
      expect(windowsResources, contains('VALUE "FileDescription", "Perfect!"'));
      expect(selectedSource.lengthSync(), greaterThan(1000));
      expect(androidIcon.lengthSync(), greaterThan(1000));
      expect(windowsIcon.lengthSync(), greaterThan(1000));
      final ico = windowsIcon.readAsBytesSync();
      expect(ico.length, greaterThan(6));
      expect(ico[0], 0);
      expect(ico[1], 0);
      expect(ico[2], 1);
      expect(ico[3], 0);
      final frameCount = ico[4] | (ico[5] << 8);
      final actualWindowsIconSizes = <int>{};
      for (var frame = 0; frame < frameCount; frame++) {
        final offset = 6 + (frame * 16);
        expect(ico.length, greaterThan(offset + 15));
        final width = ico[offset] == 0 ? 256 : ico[offset];
        final height = ico[offset + 1] == 0 ? 256 : ico[offset + 1];
        expect(height, width);
        actualWindowsIconSizes.add(width);
      }
      expect(
        actualWindowsIconSizes,
        containsAll(requiredWindowsIconSizes),
        reason:
            'Explorer, taskbar, window chrome and shortcuts require distinct '
            'Day Compass frames instead of scaling one 256px bitmap.',
      );
      expect(flutterMetadata, isNot(contains('platform: web')));
      expect(flutterMetadata, isNot(contains('platform: ios')));
      expect(flutterMetadata, isNot(contains('platform: linux')));
      expect(flutterMetadata, isNot(contains('platform: macos')));
    },
  );

  test('private release identities stay external to source and CI-aware', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final androidBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final contract = File(
      '.github/private-build-contract.yml',
    ).readAsStringSync();

    expect(pubspec, contains('identity_name: com.k1tvkli2003.perfect'));
    expect(pubspec, contains('publisher: CN=K1 Perfect Private'));
    expect(pubspec, contains('display_name: Perfect!'));
    expect(pubspec, contains('protocol_activation: perfect'));
    expect(workflow, contains('dart run msix:create'));
    expect(workflow, contains('PERFECT_WINDOWS_PFX_BASE64'));
    expect(workflow, contains('PERFECT_ANDROID_KEYSTORE_BASE64'));
    expect(androidBuild, contains('PERFECT_ANDROID_KEYSTORE_PATH'));
    expect(androidBuild, contains('privateRelease'));
    expect(
      contract,
      contains('publication: trusted-main-success-to-draft-then-private'),
    );
    expect(contract, contains('private_github_releases: true'));
    expect(contract, isNot(contains('.pfx')));
    expect(contract, isNot(contains('.jks')));
  });

  test('Android cold start keeps the approved Day Compass surface', () {
    final fallback = File(
      'android/app/src/main/res/drawable/launch_background.xml',
    ).readAsStringSync();
    final fallbackV21 = File(
      'android/app/src/main/res/drawable-v21/launch_background.xml',
    ).readAsStringSync();
    final splashV31 = File(
      'android/app/src/main/res/values-v31/styles.xml',
    ).readAsStringSync();
    final splashNightV31 = File(
      'android/app/src/main/res/values-night-v31/styles.xml',
    ).readAsStringSync();

    for (final launchSurface in <String>[fallback, fallbackV21]) {
      expect(
        launchSurface,
        allOf(
          contains('@color/perfect_splash_background'),
          contains('@drawable/perfect_widget_mark'),
          contains('android:gravity="center"'),
        ),
      );
      expect(launchSurface, isNot(contains('@android:color/white')));
    }
    for (final platformSplash in <String>[splashV31, splashNightV31]) {
      expect(
        platformSplash,
        allOf(
          contains('android:windowSplashScreenBackground'),
          contains('@color/perfect_splash_background'),
          contains('android:windowSplashScreenAnimatedIcon'),
          contains('@drawable/perfect_widget_mark'),
          contains('android:windowSplashScreenIconBackgroundColor'),
          contains('@android:color/transparent'),
        ),
      );
    }
  });
}
