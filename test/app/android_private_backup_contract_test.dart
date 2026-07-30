import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('private Android data is excluded from cloud and device transfer', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final legacyRules = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();
    final extractionRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(legacyRules, contains('<exclude domain="database" path="."'));
    expect(legacyRules, contains('<exclude domain="sharedpref" path="."'));
    expect(extractionRules, contains('<cloud-backup>'));
    expect(extractionRules, contains('<device-transfer>'));
    expect(
      RegExp(
        '<exclude domain="database" path="\\."',
      ).allMatches(extractionRules),
      hasLength(2),
    );
    expect(
      RegExp(
        '<exclude domain="sharedpref" path="\\."',
      ).allMatches(extractionRules),
      hasLength(2),
    );
  });
}
