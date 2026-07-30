import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String module;
  late String backupCommand;
  late String restoreCommand;
  late String roundTrip;

  setUpAll(() {
    module = File('tool/PerfectSigningPortable.psm1').readAsStringSync();
    backupCommand = File('tool/backup_private_signing.ps1').readAsStringSync();
    restoreCommand = File(
      'tool/restore_private_signing.ps1',
    ).readAsStringSync();
    roundTrip = File(
      'tool/tests/test_private_signing_portable_roundtrip.ps1',
    ).readAsStringSync();
  });

  test('backup is a versioned authenticated portable envelope', () {
    expect(module, contains(r'$script:BackupVersion = 1'));
    expect(module, contains(r'$script:KdfIterations = 600000'));
    expect(module, contains(r'$script:MaximumPackageBytes = 67108864'));
    expect(module, contains(r'$script:MaximumIdentityFileBytes = 33554432'));
    expect(module, contains('PBKDF2-HMAC-SHA256'));
    expect(module, contains('AES-256-GCM'));
    expect(module, contains('[Security.Cryptography.AesGcm]::new'));
    expect(
      module,
      contains(
        '[Security.Cryptography.CryptographicOperations]::FixedTimeEquals',
      ),
    );
    expect(module, contains('[Security.Cryptography.RandomNumberGenerator]'));
    expect(
      module,
      contains('Perfect signing portability requires PowerShell 7.4 or newer.'),
    );
    expect(module, contains(r'$aes.Encrypt('));
    expect(module, contains(r'$aes.Decrypt('));
    expect(module, contains(r'$script:Aad'));
  });

  test(
    'all private identity material is encrypted without plaintext staging',
    () {
      for (final fileName in <String>[
        'perfect-private.jks',
        'Perfect-private.pfx',
        'Perfect-private.cer',
        'perfect-private-android.cer',
        'signing-manifest.json',
      ]) {
        expect(module, contains('"$fileName"'));
      }
      expect(module, contains('android_store_password'));
      expect(module, contains('android_key_password'));
      expect(module, contains('windows_pfx_password'));
      expect(module, contains('ConvertFrom-DpapiSecret'));
      expect(module, contains('Protect-WithCurrentUserDpapi'));
      expect(module, isNot(contains('Export-Clixml')));
      expect(module, isNot(contains('Start-Process')));
      expect(module, isNot(contains('keytool')));
      expect(module, isNot(contains('openssl')));
    },
  );

  test('restore verifies pinned identity before creating the target', () {
    final validation = module.indexOf(
      r'$validated = ConvertTo-ValidatedSigningPayload $plaintext',
    );
    final createTarget = module.indexOf(
      r'$null = [IO.Directory]::CreateDirectory($SigningRoot)',
    );
    expect(validation, greaterThan(0));
    expect(createTarget, greaterThan(validation));

    expect(module, contains('Get-JksIdentity'));
    expect(module, contains('The Android JKS password or integrity digest'));
    expect(module, contains('Unprotect-JksPrivateKey'));
    expect(module, contains('ImportPkcs8PrivateKey'));
    expect(module, contains('SignData'));
    expect(module, contains('VerifyData'));
    expect(module, contains(r'$payload.secrets.android_key_password'));
    expect(
      module,
      contains(
        'The Android private key is malformed, mismatched, or unusable.',
      ),
    );
    expect(
      module,
      contains(
        'The pinned Android alias is not a private-key entry in the JKS.',
      ),
    );
    expect(module, contains('android_certificate_sha256'));
    expect(module, contains('windows_certificate_thumbprint'));
    expect(module, contains('windows_certificate_subject'));
    expect(module, contains('The Windows PFX does not contain a private key'));
    expect(module, contains('[IO.FileMode]::CreateNew'));
  });

  test('commands prompt securely and never accept a plaintext passphrase', () {
    expect(backupCommand, contains('Read-Host'));
    expect(backupCommand, contains('-AsSecureString'));
    expect(restoreCommand, contains('Read-Host'));
    expect(restoreCommand, contains('-AsSecureString'));
    expect(backupCommand, isNot(contains('[string]\$Passphrase')));
    expect(restoreCommand, isNot(contains('[string]\$Passphrase')));
    expect(backupCommand, isNot(contains('NetworkCredential')));
    expect(backupCommand, isNot(contains('Write-Output')));
    expect(restoreCommand, isNot(contains('Write-Output')));
    expect(module, isNot(contains('Write-Host')));
    expect(module, isNot(contains('Write-Verbose')));
    expect(module, isNot(contains('Write-Debug')));
  });

  test('overwrite, ACL, atomicity, and tamper behaviors are covered', () {
    expect(
      module,
      contains(
        'The backup destination already exists; overwrite is not allowed',
      ),
    );
    expect(module, contains('AllowExistingEmptyTarget'));
    expect(module, contains('must be an explicitly allowed empty directory'));
    expect(module, contains('Set-RestrictedAcl'));
    expect(module, contains('/inheritance:r'));
    expect(module, contains(r'$partialPath'));
    expect(module, contains(r'[IO.File]::Move($partialPath, $OutputPath)'));

    expect(roundTrip, contains('synthetic-source'));
    expect(roundTrip, contains('synthetic-restored'));
    expect(roundTrip, contains('authenticated-ciphertext change'));
    expect(roundTrip, contains('non-empty signing target'));
    expect(roundTrip, contains('wrong Android private-key password'));
    expect(roundTrip, contains('certificate-only Android alias'));
    expect(roundTrip, contains('preserve the existing empty target ACL'));
    expect(roundTrip, contains('Injected post-ACL write failure.'));
    expect(roundTrip, contains('appeared in command output'));
    expect(roundTrip, contains('Perfect signing portable round-trip: PASS'));
  });
}
