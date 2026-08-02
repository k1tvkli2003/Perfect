import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String workflow;
  late String contract;
  late String androidBuild;
  late String signingProvisioner;
  late String signingProvisionerTest;
  late String gitignore;

  setUpAll(() {
    workflow = File('.github/workflows/verify.yml').readAsStringSync();
    contract = File('.github/private-build-contract.yml').readAsStringSync();
    androidBuild = File('android/app/build.gradle.kts').readAsStringSync();
    signingProvisioner = File(
      'tool/provision_private_signing.ps1',
    ).readAsStringSync();
    signingProvisionerTest = File(
      'tool/tests/test_provision_private_signing.ps1',
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
    expect(
      workflow,
      contains(
        r'artifact_version="$semantic_version-build.$android_version_code"',
      ),
    );
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
      contains(
        r"${{ needs.prepare.outputs.trusted_build == 'true' && "
        r"secrets.PERFECT_OWNER_AUTH_EMAIL || '' }}",
      ),
    );
    expect(
      workflow,
      contains(
        '--dart-define="PERFECT_OWNER_AUTH_EMAIL=\$PERFECT_OWNER_AUTH_EMAIL"',
      ),
    );
    expect(
      workflow,
      contains(
        '--dart-define="PERFECT_OWNER_AUTH_EMAIL=\$env:PERFECT_OWNER_AUTH_EMAIL"',
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

  test('legacy Windows CA signer migration is recoverable and idempotent', () {
    expect(signingProvisioner, contains('basicConstraints=critical,CA:FALSE'));
    expect(signingProvisioner, contains('LegacyCertificateAuthority'));
    expect(signingProvisioner, contains('ValidEndEntity'));
    expect(signingProvisioner, contains('migration-backups'));
    expect(
      signingProvisioner,
      contains('The Windows PFX and CER identities do not match.'),
    );
    expect(
      signingProvisioner,
      contains(r'$process.StandardInput.Write($Value)'),
    );
    expect(
      signingProvisioner,
      isNot(contains('PERFECT_WINDOWS_PFX_PASSWORD --body')),
    );

    expect(signingProvisionerTest, contains('synthetic/never-contact'));
    expect(signingProvisionerTest, contains('SkipRepositorySync'));
    expect(
      signingProvisionerTest,
      contains('An idempotent rerun rotated the Android identity.'),
    );
    expect(
      signingProvisionerTest,
      contains('A post-migration rerun rotated the new Windows identity.'),
    );
    expect(
      signingProvisionerTest,
      contains('Injected Windows signing promotion failure.'),
    );
    expect(
      signingProvisionerTest,
      contains('An ambiguous Windows identity was not rejected.'),
    );
    expect(
      signingProvisionerTest,
      contains('Perfect private signing provisioner: PASS'),
    );
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
    expect(workflow, contains('Signed Windows checksum coverage'));
    expect(workflow, contains('build/windows/x64/msix/SHA256SUMS.txt'));
    expect(
      RegExp(
        r'SignTool Error:\\s\+A certificate chain processed,\\s\+',
      ).allMatches(workflow),
      hasLength(2),
    );
    expect(
      RegExp(r'but terminated in a root').allMatches(workflow),
      hasLength(2),
    );
    expect(
      RegExp(
        r'certificate which is not trusted by\\s\+the trust provider\\\.',
      ).allMatches(workflow),
      hasLength(2),
    );
    expect(
      workflow,
      isNot(contains(r'but terminated in a root\s+certificate which is not')),
    );
  });

  test('trusted runs publish one verified three-asset private release', () {
    expect(workflow, contains(r'release_tag=v$artifact_version'));
    expect(workflow, contains('Publish private install-ready release'));
    expect(
      workflow,
      contains(
        "if: needs.prepare.outputs.trusted_build == 'true' && success()",
      ),
    );
    expect(workflow, contains('contents: write'));
    expect(workflow, contains('attestations: read'));
    expect(workflow, contains('gh release create'));
    expect(workflow, contains(r'ensure_release_tag "$tag"'));
    expect(
      RegExp(r'ensure_release_tag "\$tag"').allMatches(workflow),
      hasLength(2),
    );
    expect(workflow, contains('git/ref/tags/\$candidate_tag'));
    expect(workflow, contains('refs/tags/\$candidate_tag'));
    expect(workflow, contains('--verify-tag'));
    expect(
      workflow,
      contains(
        'Release tag \$candidate_tag resolves to \$resolved_sha instead of \$GITHUB_SHA',
      ),
    );
    expect(workflow, contains('--draft'));
    expect(workflow, contains('--draft=false'));
    expect(workflow, contains('gh release download'));
    expect(workflow, contains('Draft release byte mismatch'));
    expect(workflow, contains('gh release verify'));
    expect(workflow, contains('isImmutable'));
    expect(workflow, contains(r'immutable $tag already matches this commit'));
    expect(workflow, contains('exactly three verified install-ready assets'));
    expect(
      workflow,
      contains(r'Perfect-$PERFECT_ARTIFACT_VERSION-Android.apk'),
    );
    expect(
      workflow,
      contains(r'Perfect-$PERFECT_ARTIFACT_VERSION-Windows-Setup.exe'),
    );
    expect(
      workflow,
      contains(r'Perfect-$PERFECT_ARTIFACT_VERSION-Windows-Portable.zip'),
    );
    expect(
      workflow,
      contains('for required in \\\n            perfect.exe \\'),
    );
    expect(workflow, isNot(contains('Portable ZIP is missing Perfect.exe')));
    expect(
      contract,
      contains('publication: trusted-main-success-to-draft-then-private'),
    );
    expect(
      contract,
      contains('The three user-facing release assets are exactly one signed'),
    );
    expect(
      contract,
      contains('CER, raw MSIX, checksum files, logs, and transport wrappers'),
    );
  });

  test('trusted Windows builds prove install-over without trusting Root', () {
    expect(workflow, contains('actions: read'));
    expect(workflow, contains('Prove MSIX install-over preserves LocalState'));
    expect(
      workflow,
      contains(r"Cert:\LocalMachine\TrustedPeople\$expectedThumbprint"),
    );
    expect(workflow, contains('X509BasicConstraintsExtension'));
    expect(workflow, contains(r'$basicConstraints.CertificateAuthority'));
    expect(workflow, contains(r'$certificate.Issuer -ne $certificate.Subject'));
    expect(workflow, contains('Add-AppxPackage'));
    expect(workflow, contains(r'$candidateCertificate.Thumbprint'));
    expect(
      workflow,
      contains('No older private MSIX with the pinned signer exists'),
    );
    expect(
      workflow,
      contains(r'SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'),
    );
    expect(workflow, contains(r'SOFTWARE\Policies\Microsoft\Windows\Appx'));
    expect(workflow, contains("'AllowAllTrustedApps'"));
    expect(workflow, contains(r'$snapshot.Key.DeleteValue'));
    expect(workflow, contains(r'$snapshot.PreviousValue'));
    expect(workflow, contains('ci-install-over-marker.json'));
    expect(workflow, contains(r'PackageFamilyName -ne $previousFamily'));
    expect(workflow, contains('LocalState marker disappeared'));
    expect(workflow, contains('LocalState marker changed'));
    expect(workflow, contains('Remove-AppxPackage'));
    expect(
      RegExp(
        r'PERFECT_WINDOWS_CERT_THUMBPRINT:\s*\$\{\{ vars\.'
        r'PERFECT_WINDOWS_CERT_THUMBPRINT \}\}',
      ).allMatches(workflow),
      hasLength(3),
    );
    expect(
      workflow,
      isNot(
        contains(
          r'PERFECT_WINDOWS_CERT_THUMBPRINT: ${{ secrets.'
          'PERFECT_WINDOWS_CERT_THUMBPRINT }}',
        ),
      ),
    );
    expect(workflow, isNot(contains(r'Cert:\CurrentUser\Root')));
    expect(workflow, contains('did not mutate Root'));
    expect(
      workflow,
      contains('Certificate stores did not return to their exact baseline'),
    );
    expect(workflow, contains(r'(@($trustedPeopleBefore) -join "`n")'));
    expect(workflow, isNot(contains(r'Compare-Object $trustedPeopleBefore')));
    expect(
      contract,
      contains('proving that package family and an exact LocalState marker'),
    );
    expect(contract, contains('self-signed end-entity certificate'));
    expect(contract, contains('restores prior policy values'));
  });
}
