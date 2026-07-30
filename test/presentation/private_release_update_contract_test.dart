import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String workflow;
  late String contract;
  late String androidBuild;
  late String signingProvisioner;
  late String gitignore;

  setUpAll(() {
    workflow = File('.github/workflows/verify.yml').readAsStringSync();
    contract = File('.github/private-build-contract.yml').readAsStringSync();
    androidBuild = File('android/app/build.gradle.kts').readAsStringSync();
    signingProvisioner = File(
      'tool/provision_private_signing.ps1',
    ).readAsStringSync();
    gitignore = File('.gitignore').readAsStringSync();
  });

  test('one deterministic run plus a stable epoch feeds Android and MSIX', () {
    expect(workflow, contains('github.run_number'));
    expect(workflow, contains(r'android_version_code=$android_version_code'));
    expect(
      workflow,
      contains(r'android_version_code=$((android_epoch + run_number))'),
    );
    expect(workflow, contains(r'msix_version=$semantic_version.$run_number'));
    expect(workflow, contains(r'artifact_version=$semantic_version-build.'));
    expect(
      workflow,
      contains('--build-number="\$PERFECT_ANDROID_VERSION_CODE"'),
    );
    expect(
      workflow,
      contains('--build-number="\$env:PERFECT_WINDOWS_BUILD_NUMBER"'),
    );
    expect(workflow, contains('PERFECT_MSIX_VERSION'));
    expect(workflow, contains('android_version_code > 2100000000'));
    expect(workflow, contains('run_number > 65535'));
    expect(workflow, contains('cancel-in-progress: false'));
    expect(workflow, contains('queue: max'));
    expect(workflow, contains('fetch-depth: 0'));
    expect(workflow, contains('PERFECT_BASE_SHA'));
    expect(workflow, contains(r'git show "$comparison_ref":pubspec.yaml'));
    expect(workflow, contains('regresses from'));
    expect(
      RegExp(r'run: flutter pub get --enforce-lockfile').allMatches(workflow),
      hasLength(2),
    );

    expect(
      contract,
      contains(
        'version_code: pubspec BUILD epoch plus GitHub Actions run number',
      ),
    );
    expect(
      contract,
      contains('msix_version: MAJOR.MINOR.PATCH.GITHUB_RUN_NUMBER'),
    );
    expect(
      contract,
      contains('A rerun keeps the same Android versionCode and MSIX version'),
    );
  });

  test('stable package and certificate identities are pinned', () {
    expect(androidBuild, contains('applicationId = "com.k1tvkli2003.perfect"'));
    expect(androidBuild, contains('hasAnyPrivateReleaseSigning'));
    expect(
      androidBuild,
      contains('Perfect private Android signing is only partially configured'),
    );

    expect(workflow, contains('PERFECT_ANDROID_CERT_SHA256'));
    expect(workflow, contains('PERFECT_WINDOWS_CERT_THUMBPRINT'));
    expect(
      workflow,
      contains('The final APK does not carry the pinned Android'),
    );
    expect(workflow, contains(r'$certificate.Thumbprint'));
    expect(workflow, contains('CN=K1 Perfect Private'));
    expect(workflow, contains('1.3.6.1.5.5.7.3.3'));
    expect(workflow, contains('com.k1tvkli2003.perfect'));

    expect(
      contract,
      contains(
        'The Android application ID, JKS alias/certificate fingerprint, '
        'Windows package identity/publisher, and PFX thumbprint are immutable',
      ),
    );
  });

  test('untrusted changes cannot receive signing or runtime secrets', () {
    expect(workflow, isNot(contains('pull_request_target')));
    expect(
      workflow,
      contains(
        r"${{ (github.event_name == 'push' || github.event_name == "
        r"'workflow_dispatch') && github.ref == 'refs/heads/main' }}",
      ),
    );
    expect(
      workflow,
      contains(
        r"${{ needs.prepare.outputs.trusted_build == 'true' && "
        r"secrets.PERFECT_ANDROID_KEYSTORE_BASE64 || '' }}",
      ),
    );
    expect(
      workflow,
      contains(
        r"${{ needs.prepare.outputs.trusted_build == 'true' && "
        r"secrets.PERFECT_SUPABASE_URL || '' }}",
      ),
    );
    expect(
      workflow,
      contains("if: needs.prepare.outputs.trusted_build == 'true'"),
    );
    expect(
      contract,
      contains('manual runs outside main never receive Supabase or signing'),
    );
    expect(
      contract,
      contains('Trusted builds fail closed when a signing secret'),
    );
  });

  test('signing secrets never travel in command arguments', () {
    final secretFunction = signingProvisioner.substring(
      signingProvisioner.indexOf('function Set-RepositorySecret'),
      signingProvisioner.indexOf('function Set-RepositoryVariable'),
    );
    expect(secretFunction, isNot(contains('secret set \$Name --repo')));
    expect(secretFunction, isNot(contains('--body \$Value')));
    expect(
      secretFunction,
      contains(r'$startInfo.RedirectStandardInput = $true'),
    );
    expect(secretFunction, contains(r'$process.StandardInput.Write($Value)'));
    expect(secretFunction, contains(r'$process.StandardInput.Close()'));
    expect(
      secretFunction,
      isNot(contains(r'$process.StandardInput.WriteLine($Value)')),
    );
    expect(workflow, isNot(contains('--certificate-password')));
    expect(workflow, contains('Import-PfxCertificate'));
    expect(workflow, contains(r'Cert:\CurrentUser\My'));
    expect(workflow, contains('--signtool-options \$signToolOptions'));
    expect(workflow, contains(r'$securePfxPassword.Dispose()'));
    expect(workflow, contains(r'$env:PERFECT_WINDOWS_PFX_PASSWORD = $null'));
    expect(workflow, contains(r'$env:PERFECT_WINDOWS_PFX_BASE64 = $null'));
    expect(
      workflow,
      isNot(
        contains(
          'echo "PERFECT_ANDROID_KEYSTORE_PASSWORD='
          r'$PERFECT_ANDROID_KEYSTORE_PASSWORD"',
        ),
      ),
    );
    for (final privateMaterial in <String>[
      '*.jks',
      '*.keystore',
      '*.pfx',
      '*-private-key.pem',
      'protected-secrets.json',
    ]) {
      expect(gitignore, contains(privateMaterial));
    }
  });

  test('final installables are identity-checked and checksummed', () {
    expect(workflow, contains('aapt2" dump badging'));
    expect(workflow, contains('apksigner" verify'));
    expect(workflow, contains('zipalign" -c'));
    expect(workflow, contains('arm64-v8a armeabi-v7a x86_64'));
    expect(workflow, contains('-android-universal.apk'));
    expect(workflow, contains('sha256sum --check SHA256SUMS.txt'));
    expect(workflow, contains('AppxManifest.xml'));
    expect(workflow, contains('AppxSignature.p7x'));
    expect(workflow, contains('signtool.exe'));
    expect(workflow, contains('Signed MSIX checksum coverage'));
    expect(workflow, contains('build/windows/x64/msix/SHA256SUMS.txt'));
  });
}
