import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

({int left, int top, int right, int bottom}) _alphaBounds(
  Uint8List rgba,
  int width,
  int height, {
  int threshold = 1,
}) {
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = rgba[((y * width) + x) * 4 + 3];
      if (alpha < threshold) continue;
      minX = minX < x ? minX : x;
      minY = minY < y ? minY : y;
      maxX = maxX > x ? maxX : x;
      maxY = maxY > y ? maxY : y;
    }
  }
  if (maxX < 0 || maxY < 0) {
    throw StateError('Expected at least one visible icon pixel.');
  }
  return (left: minX, top: minY, right: maxX + 1, bottom: maxY + 1);
}

int _alphaComponents(
  Uint8List rgba,
  int width,
  int height, {
  int threshold = 192,
}) {
  final visible = List<bool>.generate(width * height, (index) {
    return rgba[(index * 4) + 3] >= threshold;
  });
  var components = 0;
  final queue = <int>[];
  for (var index = 0; index < visible.length; index++) {
    if (!visible[index]) continue;
    components++;
    visible[index] = false;
    queue
      ..clear()
      ..add(index);
    for (var cursor = 0; cursor < queue.length; cursor++) {
      final current = queue[cursor];
      final x = current % width;
      final y = current ~/ width;
      for (var offsetY = -1; offsetY <= 1; offsetY++) {
        for (var offsetX = -1; offsetX <= 1; offsetX++) {
          if (offsetX == 0 && offsetY == 0) continue;
          final nextX = x + offsetX;
          final nextY = y + offsetY;
          if (nextX < 0 || nextX >= width || nextY < 0 || nextY >= height) {
            continue;
          }
          final next = (nextY * width) + nextX;
          if (!visible[next]) continue;
          visible[next] = false;
          queue.add(next);
        }
      }
    }
  }
  return components;
}

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
          contains('android:inset="19%"'),
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
      expect(launcherConfig, contains('adaptive_icon_foreground_inset: 19'));
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
          final bounds = _alphaBounds(
            rgba,
            image.width,
            image.height,
            threshold: 128,
          );
          final densityScale = image.width / 108;
          const appliedLayerScale = 1 - (2 * .19);
          final effectiveWidthDp =
              ((bounds.right - bounds.left) / densityScale) * appliedLayerScale;
          final effectiveHeightDp =
              ((bounds.bottom - bounds.top) / densityScale) * appliedLayerScale;

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
          expect(
            effectiveWidthDp,
            inInclusiveRange(48, 66),
            reason:
                '${foreground.key} $layer must stay optically legible while '
                'remaining inside Android\'s adaptive-icon safe zone.',
          );
          expect(effectiveHeightDp, inInclusiveRange(48, 66));
          final startInset = bounds.left / densityScale;
          final endInset = (image.width - bounds.right) / densityScale;
          final topInset = bounds.top / densityScale;
          final bottomInset = (image.height - bounds.bottom) / densityScale;
          expect((startInset - endInset).abs(), lessThanOrEqualTo(1));
          expect((topInset - bottomInset).abs(), lessThanOrEqualTo(1));

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

  test(
    'Android widgets render a dedicated inset Day Compass at 48dp',
    () async {
      final publicMark = File(
        'android/app/src/main/res/drawable/perfect_widget_mark.xml',
      ).readAsStringSync();
      expect(publicMark, contains('@drawable/perfect_widget_mark_raster'));
      expect(publicMark, isNot(contains('pathData=')));

      const rasterSizes = <String, int>{
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final raster in rasterSizes.entries) {
        final bitmap = File(
          'android/app/src/main/res/drawable-${raster.key}/'
          'perfect_widget_mark_raster.png',
        );
        expect(bitmap.existsSync(), isTrue);
        final codec = await ui.instantiateImageCodec(
          await bitmap.readAsBytes(),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final rgba = pixels!.buffer.asUint8List();

        expect(image.width, raster.value);
        expect(image.height, raster.value);
        expect(<int>[
          rgba[3],
          rgba[((image.width - 1) * 4) + 3],
          rgba[(((image.height - 1) * image.width) * 4) + 3],
          rgba[((image.width * image.height) - 1) * 4 + 3],
        ], everyElement(0));
        final bounds = _alphaBounds(
          rgba,
          image.width,
          image.height,
          threshold: 8,
        );
        final scale = raster.value / 48;
        expect(bounds.left / scale, greaterThanOrEqualTo(3.5));
        expect(bounds.top / scale, greaterThanOrEqualTo(3.5));
        expect((image.width - bounds.right) / scale, greaterThanOrEqualTo(3.5));
        expect(
          (image.height - bounds.bottom) / scale,
          greaterThanOrEqualTo(3.5),
        );
        expect(
          _alphaComponents(rgba, image.width, image.height, threshold: 192),
          7,
          reason:
              '${raster.key} widget mark must preserve all six selected pastel '
              'modules plus the dark owner core.',
        );
        final centre =
            (((image.height ~/ 2) * image.width) + (image.width ~/ 2)) * 4;
        expect(rgba[centre + 3], greaterThan(220));
        expect(rgba[centre], lessThan(100));
        expect(rgba[centre + 1], lessThan(100));
        expect(rgba[centre + 2], lessThan(100));

        image.dispose();
        codec.dispose();
      }

      for (final layout in <String>[
        'perfect_today_widget_small.xml',
        'perfect_today_widget_tall.xml',
        'perfect_today_widget_wide.xml',
        'perfect_today_widget_large.xml',
      ]) {
        final source = File(
          'android/app/src/main/res/layout/$layout',
        ).readAsStringSync();
        expect(source, contains('@drawable/perfect_widget_mark'));
        expect(source, contains('@drawable/perfect_widget_wordmark_raster'));
        expect(source, isNot(contains('android:text="Perfect!"')));
        expect(source, isNot(contains('android:text="Perfect! Today"')));
      }
      expect(
        File(
          'android/app/src/main/res/layout/perfect_widget_quick_add.xml',
        ).readAsStringSync(),
        contains('@drawable/perfect_widget_mark'),
      );
    },
  );

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
          contains('@drawable/perfect_splash_mark_raster'),
          contains('android:gravity="center"'),
        ),
      );
      expect(launchSurface, isNot(contains('@drawable/perfect_widget_mark')));
      expect(launchSurface, isNot(contains('@android:color/white')));
    }
    for (final platformSplash in <String>[splashV31, splashNightV31]) {
      expect(
        platformSplash,
        allOf(
          contains('android:windowSplashScreenBackground'),
          contains('@color/perfect_splash_background'),
          contains('android:windowSplashScreenAnimatedIcon'),
          contains('@drawable/perfect_splash_mark_raster'),
          contains('android:windowSplashScreenIconBackgroundColor'),
          contains('@android:color/transparent'),
        ),
      );
      expect(platformSplash, isNot(contains('@drawable/perfect_widget_mark')));
    }

    final dayColors = File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsStringSync();
    final nightColors = File(
      'android/app/src/main/res/values-night/colors.xml',
    ).readAsStringSync();
    expect(dayColors, contains('#FFFFFBF6'));
    expect(nightColors, contains('#FF171821'));
  });

  test(
    'Android splash keeps the complete mark inside the 192dp safe circle',
    () async {
      const rasterSizes = <String, int>{
        'mdpi': 288,
        'hdpi': 432,
        'xhdpi': 576,
        'xxhdpi': 864,
        'xxxhdpi': 1152,
      };
      for (final raster in rasterSizes.entries) {
        final bitmap = File(
          'android/app/src/main/res/drawable-${raster.key}/'
          'perfect_splash_mark_raster.png',
        );
        expect(bitmap.existsSync(), isTrue);
        final codec = await ui.instantiateImageCodec(
          await bitmap.readAsBytes(),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final rgba = pixels!.buffer.asUint8List();
        final bounds = _alphaBounds(
          rgba,
          image.width,
          image.height,
          threshold: 8,
        );
        final scale = raster.value / 288;
        final widthDp = (bounds.right - bounds.left) / scale;
        final heightDp = (bounds.bottom - bounds.top) / scale;

        expect(image.width, raster.value);
        expect(image.height, raster.value);
        expect(widthDp, lessThanOrEqualTo(170));
        expect(heightDp, lessThanOrEqualTo(170));
        expect(
          (bounds.left / scale - (image.width - bounds.right) / scale).abs(),
          lessThanOrEqualTo(1.25),
        );
        expect(
          (bounds.top / scale - (image.height - bounds.bottom) / scale).abs(),
          lessThanOrEqualTo(1.25),
        );
        expect(
          _alphaComponents(rgba, image.width, image.height, threshold: 192),
          7,
        );
        image.dispose();
        codec.dispose();

        final nightBitmap = File(
          'android/app/src/main/res/drawable-night-${raster.key}/'
          'perfect_splash_mark_raster.png',
        );
        expect(nightBitmap.existsSync(), isTrue);
        final nightCodec = await ui.instantiateImageCodec(
          await nightBitmap.readAsBytes(),
        );
        final nightFrame = await nightCodec.getNextFrame();
        final nightImage = nightFrame.image;
        final nightPixels = await nightImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final nightRgba = nightPixels!.buffer.asUint8List();
        final nightBounds = _alphaBounds(
          nightRgba,
          nightImage.width,
          nightImage.height,
          threshold: 8,
        );
        final centre =
            (((nightImage.height ~/ 2) * nightImage.width) +
                (nightImage.width ~/ 2)) *
            4;
        expect(nightImage.width, raster.value);
        expect(nightImage.height, raster.value);
        expect(nightBounds, bounds);
        expect(nightRgba[centre + 3], greaterThan(240));
        expect(nightRgba[centre], greaterThan(235));
        expect(nightRgba[centre + 1], greaterThan(235));
        expect(nightRgba[centre + 2], greaterThan(235));
        nightImage.dispose();
        nightCodec.dispose();
      }
    },
  );

  test('wordmark SVGs contain authored paths rather than live font text', () {
    for (final name in <String>[
      'perfect-wordmark.svg',
      'perfect-wordmark-dark.svg',
      'perfect-wordmark-high-contrast-light.svg',
      'perfect-wordmark-high-contrast-dark.svg',
    ]) {
      final source = File('assets/brand/$name').readAsStringSync();
      expect(source.toLowerCase(), isNot(contains('<text')));
      expect(RegExp(r'<path ').allMatches(source), hasLength(8));
      expect(
        source,
        contains('<title id="perfect-wordmark-title">Perfect!</title>'),
      );
    }
  });
}
