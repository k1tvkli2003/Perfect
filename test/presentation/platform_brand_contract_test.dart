import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android and Windows expose the approved Perfect! name and icon', () {
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
    final selectedSource = File('assets/brand/perfect-launcher.png');
    final androidIcon = File(
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    );
    final windowsIcon = File('windows/runner/resources/app_icon.ico');
    final adaptiveIcon = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    final themedIcon = File(
      'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    expect(
      androidStrings,
      contains('<string name="app_name">Perfect!</string>'),
    );
    expect(adaptiveIcon, contains('@drawable/perfect_launcher_foreground'));
    expect(themedIcon, contains('@drawable/perfect_launcher_monochrome'));
    expect(windowsMain, contains('window.Create(L"Perfect!"'));
    expect(windowsResources, contains('VALUE "ProductName", "Perfect!"'));
    expect(windowsResources, contains('VALUE "FileDescription", "Perfect!"'));
    expect(selectedSource.lengthSync(), greaterThan(1000));
    expect(androidIcon.lengthSync(), greaterThan(1000));
    expect(windowsIcon.lengthSync(), greaterThan(1000));
    expect(flutterMetadata, isNot(contains('platform: web')));
    expect(flutterMetadata, isNot(contains('platform: ios')));
    expect(flutterMetadata, isNot(contains('platform: linux')));
    expect(flutterMetadata, isNot(contains('platform: macos')));
  });

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
    expect(contract, contains('publication: disabled'));
    expect(contract, isNot(contains('.pfx')));
    expect(contract, isNot(contains('.jks')));
  });
}
