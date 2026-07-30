[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not $IsWindows) {
  throw "This round-trip test requires Windows DPAPI and ACLs."
}

function Assert-True([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw $Message
  }
}

function Protect-TestSecret([string]$Value) {
  $secure = ConvertTo-SecureString $Value -AsPlainText -Force
  try {
    return ConvertFrom-SecureString $secure
  } finally {
    $secure.Dispose()
  }
}

function Unprotect-TestSecret([string]$Value) {
  $secure = ConvertTo-SecureString $Value
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    $secure.Dispose()
  }
}

$testRoot = Join-Path `
  ([IO.Path]::GetTempPath()) `
  "perfect-signing-roundtrip-$([Guid]::NewGuid().ToString('N'))"
$sourceRoot = Join-Path $testRoot "synthetic-source"
$restoredRoot = Join-Path $testRoot "synthetic-restored"
$existingRoot = Join-Path $testRoot "existing"
$backupPath = Join-Path $testRoot "synthetic.perfect-signing-backup"
$tamperedPath = Join-Path $testRoot "tampered.perfect-signing-backup"
$tamperedTarget = Join-Path $testRoot "tampered-target"
$wrongKeyBackup = Join-Path $testRoot "wrong-key.perfect-signing-backup"
$certificateOnlyBackup =
  Join-Path $testRoot "certificate-only.perfect-signing-backup"
$certificateOnlyJks = Join-Path $testRoot "certificate-only.jks"
$aclRollbackTarget = Join-Path $testRoot "acl-rollback-target"
$androidPassword = "Synthetic-Android-Only-Password-2026"
$windowsPassword = "Synthetic-Windows-Only-Password-2026"
$recoveryPassword = "Synthetic-Recovery-Phrase-Only-2026"
$alias = "perfect"
$keytool = (Get-Command keytool -ErrorAction Stop).Source

try {
  $null = [IO.Directory]::CreateDirectory($sourceRoot)
  Import-Module (
    Join-Path $PSScriptRoot "..\PerfectSigningPortable.psm1"
  ) -Force

  $env:PERFECT_TEST_JKS_PASSWORD = $androidPassword
  try {
    & $keytool `
      -genkeypair `
      -keystore (Join-Path $sourceRoot "perfect-private.jks") `
      -storetype JKS `
      -storepass:env PERFECT_TEST_JKS_PASSWORD `
      -keypass:env PERFECT_TEST_JKS_PASSWORD `
      -alias $alias `
      -keyalg RSA `
      -keysize 2048 `
      -sigalg SHA256withRSA `
      -validity 30 `
      -dname "CN=Synthetic Perfect Android, O=Perfect Test, C=IR" `
      2>$null
    if ($LASTEXITCODE -ne 0) {
      throw "Synthetic JKS generation failed."
    }
    & $keytool `
      -exportcert `
      -keystore (Join-Path $sourceRoot "perfect-private.jks") `
      -storepass:env PERFECT_TEST_JKS_PASSWORD `
      -alias $alias `
      -file (Join-Path $sourceRoot "perfect-private-android.cer") `
      2>$null
    if ($LASTEXITCODE -ne 0) {
      throw "Synthetic Android certificate export failed."
    }
  } finally {
    $env:PERFECT_TEST_JKS_PASSWORD = $null
  }

  $rsa = [Security.Cryptography.RSA]::Create(2048)
  try {
    $request =
      [Security.Cryptography.X509Certificates.CertificateRequest]::new(
        "CN=Synthetic Perfect Private",
        $rsa,
        [Security.Cryptography.HashAlgorithmName]::SHA256,
        [Security.Cryptography.RSASignaturePadding]::Pkcs1
      )
    $request.CertificateExtensions.Add(
      [Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new(
        [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::
          DigitalSignature,
        $true
      )
    )
    $oids = [Security.Cryptography.OidCollection]::new()
    $null = $oids.Add([Security.Cryptography.Oid]::new("1.3.6.1.5.5.7.3.3"))
    $request.CertificateExtensions.Add(
      [Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::
        new($oids, $true)
    )
    $certificate = $request.CreateSelfSigned(
      [DateTimeOffset]::UtcNow.AddMinutes(-1),
      [DateTimeOffset]::UtcNow.AddDays(30)
    )
    try {
      [IO.File]::WriteAllBytes(
        (Join-Path $sourceRoot "Perfect-private.pfx"),
        $certificate.Export(
          [Security.Cryptography.X509Certificates.X509ContentType]::Pfx,
          $windowsPassword
        )
      )
      [IO.File]::WriteAllBytes(
        (Join-Path $sourceRoot "Perfect-private.cer"),
        $certificate.Export(
          [Security.Cryptography.X509Certificates.X509ContentType]::Cert
        )
      )
      $windowsThumbprint = $certificate.Thumbprint.ToUpperInvariant()
      $windowsSubject = $certificate.Subject
    } finally {
      $certificate.Dispose()
    }
  } finally {
    $rsa.Dispose()
  }

  @{
    version = 1
    android_alias = $alias
    android_store_password = Protect-TestSecret $androidPassword
    android_key_password = Protect-TestSecret $androidPassword
    windows_pfx_password = Protect-TestSecret $windowsPassword
  } |
    ConvertTo-Json |
    Set-Content `
      -LiteralPath (Join-Path $sourceRoot "protected-secrets.json") `
      -Encoding utf8

  @{
    version = 1
    android_alias = $alias
    android_keystore_sha256 = (
      Get-FileHash `
        -Algorithm SHA256 `
        -LiteralPath (Join-Path $sourceRoot "perfect-private.jks")
    ).Hash
    android_certificate_sha256 = (
      Get-FileHash `
        -Algorithm SHA256 `
        -LiteralPath (Join-Path $sourceRoot "perfect-private-android.cer")
    ).Hash
    windows_certificate_subject = $windowsSubject
    windows_certificate_thumbprint = $windowsThumbprint
    windows_pfx_sha256 = (
      Get-FileHash `
        -Algorithm SHA256 `
        -LiteralPath (Join-Path $sourceRoot "Perfect-private.pfx")
    ).Hash
  } |
    ConvertTo-Json |
    Set-Content `
      -LiteralPath (Join-Path $sourceRoot "signing-manifest.json") `
      -Encoding utf8

  $recovery = ConvertTo-SecureString $recoveryPassword -AsPlainText -Force
  try {
    $captured = @(
      Backup-PerfectSigningIdentity `
        -SigningRoot $sourceRoot `
        -OutputPath $backupPath `
        -Passphrase $recovery
      Restore-PerfectSigningIdentity `
        -PackagePath $backupPath `
        -SigningRoot $restoredRoot `
        -Passphrase $recovery
    ) | Out-String
  } finally {
    $recovery.Dispose()
  }
  Assert-True `
    (-not $captured.Contains($androidPassword)) `
    "Android password appeared in command output."
  Assert-True `
    (-not $captured.Contains($windowsPassword)) `
    "Windows password appeared in command output."
  Assert-True `
    (-not $captured.Contains($recoveryPassword)) `
    "Recovery passphrase appeared in command output."

  $protectedSecretsPath = Join-Path $sourceRoot "protected-secrets.json"
  $originalProtectedSecrets =
    Get-Content -Raw -LiteralPath $protectedSecretsPath
  $wrongKeySecrets = $originalProtectedSecrets | ConvertFrom-Json
  $wrongKeySecrets.android_key_password =
    Protect-TestSecret "Deliberately-Wrong-Key-Password"
  $wrongKeySecrets |
    ConvertTo-Json |
    Set-Content -LiteralPath $protectedSecretsPath -Encoding utf8
  $wrongKeyRejected = $false
  $recovery = ConvertTo-SecureString $recoveryPassword -AsPlainText -Force
  try {
    try {
      Backup-PerfectSigningIdentity `
        -SigningRoot $sourceRoot `
        -OutputPath $wrongKeyBackup `
        -Passphrase $recovery
    } catch {
      $wrongKeyRejected = $true
    }
  } finally {
    $recovery.Dispose()
    [IO.File]::WriteAllText(
      $protectedSecretsPath,
      $originalProtectedSecrets,
      [Text.UTF8Encoding]::new($false)
    )
  }
  Assert-True `
    $wrongKeyRejected `
    "A wrong Android private-key password was accepted."
  Assert-True `
    (-not (Test-Path -LiteralPath $wrongKeyBackup)) `
    "Wrong-key validation created a backup."

  $androidJksPath = Join-Path $sourceRoot "perfect-private.jks"
  $manifestPath = Join-Path $sourceRoot "signing-manifest.json"
  $originalJks = [IO.File]::ReadAllBytes($androidJksPath)
  $originalManifest = Get-Content -Raw -LiteralPath $manifestPath
  $env:PERFECT_TEST_JKS_PASSWORD = $androidPassword
  try {
    & $keytool `
      -importcert `
      -noprompt `
      -keystore $certificateOnlyJks `
      -storetype JKS `
      -storepass:env PERFECT_TEST_JKS_PASSWORD `
      -alias $alias `
      -file (Join-Path $sourceRoot "perfect-private-android.cer") `
      2>$null
    if ($LASTEXITCODE -ne 0) {
      throw "Synthetic certificate-only JKS generation failed."
    }
  } finally {
    $env:PERFECT_TEST_JKS_PASSWORD = $null
  }
  [IO.File]::WriteAllBytes(
    $androidJksPath,
    [IO.File]::ReadAllBytes($certificateOnlyJks)
  )
  $certificateOnlyManifest = $originalManifest | ConvertFrom-Json
  $certificateOnlyManifest.android_keystore_sha256 = (
    Get-FileHash -Algorithm SHA256 -LiteralPath $androidJksPath
  ).Hash
  $certificateOnlyManifest |
    ConvertTo-Json |
    Set-Content -LiteralPath $manifestPath -Encoding utf8
  $certificateOnlyRejected = $false
  $recovery = ConvertTo-SecureString $recoveryPassword -AsPlainText -Force
  try {
    try {
      Backup-PerfectSigningIdentity `
        -SigningRoot $sourceRoot `
        -OutputPath $certificateOnlyBackup `
        -Passphrase $recovery
    } catch {
      $certificateOnlyRejected = $true
    }
  } finally {
    $recovery.Dispose()
    [IO.File]::WriteAllBytes($androidJksPath, $originalJks)
    [IO.File]::WriteAllText(
      $manifestPath,
      $originalManifest,
      [Text.UTF8Encoding]::new($false)
    )
    [Array]::Clear($originalJks, 0, $originalJks.Length)
  }
  Assert-True `
    $certificateOnlyRejected `
    "A certificate-only Android alias was accepted."
  Assert-True `
    (-not (Test-Path -LiteralPath $certificateOnlyBackup)) `
    "Certificate-only validation created a backup."

  foreach ($fileName in @(
    "perfect-private.jks",
    "Perfect-private.pfx",
    "Perfect-private.cer",
    "perfect-private-android.cer",
    "signing-manifest.json"
  )) {
    $sourceHash = (
      Get-FileHash -Algorithm SHA256 -LiteralPath (
        Join-Path $sourceRoot $fileName
      )
    ).Hash
    $restoredHash = (
      Get-FileHash -Algorithm SHA256 -LiteralPath (
        Join-Path $restoredRoot $fileName
      )
    ).Hash
    Assert-True `
      ($sourceHash -ceq $restoredHash) `
      "Restored $fileName does not match."
  }

  $restoredSecrets = Get-Content `
    -Raw `
    -LiteralPath (Join-Path $restoredRoot "protected-secrets.json") |
      ConvertFrom-Json
  Assert-True `
    ((Unprotect-TestSecret $restoredSecrets.android_store_password) -ceq
      $androidPassword) `
    "Android password was not re-protected for the current user."
  Assert-True `
    ((Unprotect-TestSecret $restoredSecrets.windows_pfx_password) -ceq
      $windowsPassword) `
    "Windows password was not re-protected for the current user."

  $null = [IO.Directory]::CreateDirectory($existingRoot)
  [IO.File]::WriteAllText((Join-Path $existingRoot "keep.txt"), "keep")
  $existingRejected = $false
  $recovery = ConvertTo-SecureString $recoveryPassword -AsPlainText -Force
  try {
    try {
      Restore-PerfectSigningIdentity `
        -PackagePath $backupPath `
        -SigningRoot $existingRoot `
        -Passphrase $recovery `
        -AllowExistingEmptyTarget
    } catch {
      $existingRejected = $true
    }
  } finally {
    $recovery.Dispose()
  }
  Assert-True $existingRejected "A non-empty signing target was not rejected."
  Assert-True `
    (Test-Path -LiteralPath (Join-Path $existingRoot "keep.txt")) `
    "Restore modified the rejected non-empty target."

  $tampered = Get-Content -Raw -LiteralPath $backupPath | ConvertFrom-Json
  $ciphertext = [Convert]::FromBase64String([string]$tampered.ciphertext)
  $ciphertext[0] = $ciphertext[0] -bxor 1
  $tampered.ciphertext = [Convert]::ToBase64String($ciphertext)
  $tampered |
    ConvertTo-Json -Depth 5 -Compress |
    Set-Content -LiteralPath $tamperedPath -Encoding utf8
  [Array]::Clear($ciphertext, 0, $ciphertext.Length)

  $tamperRejected = $false
  $recovery = ConvertTo-SecureString $recoveryPassword -AsPlainText -Force
  try {
    try {
      Restore-PerfectSigningIdentity `
        -PackagePath $tamperedPath `
        -SigningRoot $tamperedTarget `
        -Passphrase $recovery
    } catch {
      $tamperRejected = $true
    }
  } finally {
    $recovery.Dispose()
  }
  Assert-True $tamperRejected "An authenticated-ciphertext change was accepted."
  Assert-True `
    (-not (Test-Path -LiteralPath $tamperedTarget)) `
    "Tampered restore created a signing target."

  $null = [IO.Directory]::CreateDirectory($aclRollbackTarget)
  $aclBefore = (Get-Acl -LiteralPath $aclRollbackTarget).Sddl
  $portableModule = Get-Module PerfectSigningPortable
  & $portableModule {
    Set-Item `
      -Path Function:script:New-RestoreDestinationStream `
      -Value {
        param([string]$Path)
        throw "Injected post-ACL write failure."
      }
  }
  $postAclFailureObserved = $false
  $postAclFailureText = ""
  $recovery = ConvertTo-SecureString $recoveryPassword -AsPlainText -Force
  try {
    try {
      Restore-PerfectSigningIdentity `
        -PackagePath $backupPath `
        -SigningRoot $aclRollbackTarget `
        -Passphrase $recovery `
        -AllowExistingEmptyTarget
    } catch {
      $postAclFailureText = $_ | Out-String
      $postAclFailureObserved =
        $postAclFailureText.Contains("Injected post-ACL write failure.")
    }
  } finally {
    $recovery.Dispose()
    Import-Module (
      Join-Path $PSScriptRoot "..\PerfectSigningPortable.psm1"
    ) -Force
  }
  Assert-True `
    $postAclFailureObserved `
    "The post-ACL failure seam was not exercised: $postAclFailureText"
  $aclAfter = (Get-Acl -LiteralPath $aclRollbackTarget).Sddl
  Assert-True `
    ($aclBefore -ceq $aclAfter) `
    "A failed restore did not preserve the existing empty target ACL."
  Assert-True `
    (@(Get-ChildItem -Force -LiteralPath $aclRollbackTarget).Count -eq 0) `
    "A failed restore left files in the existing empty target."

  Write-Output "Perfect signing portable round-trip: PASS"
} finally {
  $androidPassword = $null
  $windowsPassword = $null
  $recoveryPassword = $null
  if (Test-Path -LiteralPath $testRoot) {
    $resolvedTemp = (Resolve-Path -LiteralPath ([IO.Path]::GetTempPath())).Path
    $resolvedTest = (Resolve-Path -LiteralPath $testRoot).Path
    if ($resolvedTest -notlike "$resolvedTemp*") {
      throw "Refusing to clean a test path outside the system temp directory."
    }
    Remove-Item -LiteralPath $resolvedTest -Recurse -Force
  }
}
