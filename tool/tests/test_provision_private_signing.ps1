[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not $IsWindows) {
  throw "This provisioning test requires Windows DPAPI and ACLs."
}

function Assert-True([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw $Message
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

function Protect-TestSecret([string]$Value) {
  $secure = ConvertTo-SecureString $Value -AsPlainText -Force
  try {
    return ConvertFrom-SecureString $secure
  } finally {
    $secure.Dispose()
  }
}

function Get-BasicConstraints([string]$CertificatePath) {
  $certificate =
    [Security.Cryptography.X509Certificates.X509Certificate2]::new(
      $CertificatePath
    )
  try {
    $source = @($certificate.Extensions | Where-Object {
      $_.Oid.Value -ceq "2.5.29.19"
    })[0]
    if ($null -eq $source) {
      throw "Synthetic certificate has no Basic Constraints."
    }
    $constraints =
      [Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::
        new($source, $source.Critical)
    return [pscustomobject]@{
      CertificateAuthority = $constraints.CertificateAuthority
      Critical = $source.Critical
      Thumbprint = $certificate.Thumbprint.ToUpperInvariant()
      Subject = $certificate.Subject
    }
  } finally {
    $certificate.Dispose()
  }
}

function New-LegacyWindowsCaIdentity(
  [string]$Root,
  [string]$Password,
  [string]$OpenSsl
) {
  $privateKey = Join-Path $Root "legacy-key.pem"
  $certificatePem = Join-Path $Root "legacy-cert.pem"
  $pfxPath = Join-Path $Root "Perfect-private.pfx"
  $cerPath = Join-Path $Root "Perfect-private.cer"
  $env:PERFECT_TEST_LEGACY_PASSWORD = $Password
  try {
    & $OpenSsl req `
      -x509 `
      -newkey rsa:2048 `
      -sha256 `
      -days 30 `
      -keyout $privateKey `
      -out $certificatePem `
      -passout env:PERFECT_TEST_LEGACY_PASSWORD `
      -subj "/CN=K1 Perfect Private" `
      -addext "basicConstraints=critical,CA:TRUE" `
      -addext "keyUsage=critical,digitalSignature" `
      -addext "extendedKeyUsage=critical,codeSigning" `
      2>$null
    if ($LASTEXITCODE -ne 0) {
      throw "Synthetic legacy certificate generation failed."
    }
    & $OpenSsl pkcs12 `
      -export `
      -out $pfxPath `
      -inkey $privateKey `
      -in $certificatePem `
      -name "Synthetic Legacy Perfect Signer" `
      -passin env:PERFECT_TEST_LEGACY_PASSWORD `
      -passout env:PERFECT_TEST_LEGACY_PASSWORD `
      2>$null
    if ($LASTEXITCODE -ne 0) {
      throw "Synthetic legacy PFX export failed."
    }
    & $OpenSsl x509 `
      -in $certificatePem `
      -outform der `
      -out $cerPath `
      2>$null
    if ($LASTEXITCODE -ne 0) {
      throw "Synthetic legacy CER export failed."
    }
  } finally {
    $env:PERFECT_TEST_LEGACY_PASSWORD = $null
    foreach ($path in @($privateKey, $certificatePem)) {
      if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
      }
    }
  }

  $protectedPath = Join-Path $Root "protected-secrets.json"
  $protected = Get-Content -Raw -LiteralPath $protectedPath | ConvertFrom-Json
  $protected.windows_pfx_password = Protect-TestSecret $Password
  $protected | ConvertTo-Json |
    Set-Content -LiteralPath $protectedPath -Encoding utf8
  return Get-BasicConstraints $cerPath
}

function Invoke-SyntheticProvision([string]$Root) {
  return @(
    & $provisioner `
      -SigningRoot $Root `
      -Repository "synthetic/never-contact" `
      -SkipRepositorySync `
      2>&1
  ) | Out-String
}

$testRoot = Join-Path `
  ([IO.Path]::GetTempPath()) `
  "perfect-provision-$([Guid]::NewGuid().ToString('N'))"
$creationRoot = Join-Path $testRoot "creation"
$migrationRoot = Join-Path $testRoot "migration"
$failureRoot = Join-Path $testRoot "failure"
$invalidRoot = Join-Path $testRoot "invalid"
$provisioner = Join-Path $PSScriptRoot "..\provision_private_signing.ps1"
$openssl = (Get-Command openssl -ErrorAction Stop).Source
$legacyPassword = "Synthetic-Legacy-Windows-Password-2026"

try {
  New-Item -ItemType Directory -Path $testRoot | Out-Null

  $creationOutput = Invoke-SyntheticProvision $creationRoot
  Assert-True `
    (-not $creationOutput.Contains($legacyPassword)) `
    "A synthetic password appeared in provisioning output."
  $creationConstraints = Get-BasicConstraints (
    Join-Path $creationRoot "Perfect-private.cer"
  )
  Assert-True `
    (-not $creationConstraints.CertificateAuthority) `
    "Fresh provisioning created a CA certificate."
  Assert-True `
    $creationConstraints.Critical `
    "Fresh Basic Constraints is not critical."
  Assert-True `
    ($creationConstraints.Subject -ceq "CN=K1 Perfect Private") `
    "Fresh Windows signer has the wrong subject."

  $initialAndroidHash = (
    Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $creationRoot "perfect-private.jks")
  ).Hash
  $initialWindowsHash = (
    Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $creationRoot "Perfect-private.pfx")
  ).Hash
  $null = Invoke-SyntheticProvision $creationRoot
  Assert-True `
    ((Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $creationRoot "perfect-private.jks")
    ).Hash -ceq $initialAndroidHash) `
    "An idempotent rerun rotated the Android identity."
  Assert-True `
    ((Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $creationRoot "Perfect-private.pfx")
    ).Hash -ceq $initialWindowsHash) `
    "An idempotent rerun rotated a valid Windows end-entity identity."

  Copy-Item -LiteralPath $creationRoot -Destination $migrationRoot -Recurse
  $legacy = New-LegacyWindowsCaIdentity `
    $migrationRoot `
    $legacyPassword `
    $openssl
  Assert-True `
    $legacy.CertificateAuthority `
    "Synthetic migration input is not a CA certificate."
  $legacyPfxHash = (
    Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $migrationRoot "Perfect-private.pfx")
  ).Hash
  $legacyCerHash = (
    Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $migrationRoot "Perfect-private.cer")
  ).Hash
  $migrationAndroidHash = (
    Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $migrationRoot "perfect-private.jks")
  ).Hash
  Copy-Item -LiteralPath $migrationRoot -Destination $failureRoot -Recurse
  Copy-Item -LiteralPath $migrationRoot -Destination $invalidRoot -Recurse

  $migrationOutput = Invoke-SyntheticProvision $migrationRoot
  Assert-True `
    (-not $migrationOutput.Contains($legacyPassword)) `
    "The old Windows password appeared in migration output."
  $migrated = Get-BasicConstraints (
    Join-Path $migrationRoot "Perfect-private.cer"
  )
  Assert-True `
    (-not $migrated.CertificateAuthority -and $migrated.Critical) `
    "Migration did not promote a critical CA=false end entity."
  Assert-True `
    ($migrated.Thumbprint -cne $legacy.Thumbprint) `
    "Migration did not rotate the invalid legacy Windows identity."
  Assert-True `
    ((Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $migrationRoot "perfect-private.jks")
    ).Hash -ceq $migrationAndroidHash) `
    "Windows migration changed the Android identity."

  $backupRoot = Join-Path `
    $migrationRoot `
    "migration-backups\windows-ca-$($legacy.Thumbprint)"
  Assert-True `
    ((Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $backupRoot "Perfect-private.pfx")
    ).Hash -ceq $legacyPfxHash) `
    "The recoverable backup does not contain the old Windows PFX."
  Assert-True `
    ((Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $backupRoot "Perfect-private.cer")
    ).Hash -ceq $legacyCerHash) `
    "The recoverable backup does not contain the old Windows CER."
  Assert-True `
    (Test-Path -LiteralPath (Join-Path $backupRoot "signing-manifest.json")) `
    "The recoverable backup omitted the pre-migration manifest."

  $migratedPfxHash = (
    Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $migrationRoot "Perfect-private.pfx")
  ).Hash
  $null = Invoke-SyntheticProvision $migrationRoot
  Assert-True `
    ((Get-FileHash `
      -Algorithm SHA256 `
      -LiteralPath (Join-Path $migrationRoot "Perfect-private.pfx")
    ).Hash -ceq $migratedPfxHash) `
    "A post-migration rerun rotated the new Windows identity."
  Assert-True `
    (@(Get-ChildItem `
      -Directory `
      -LiteralPath (Join-Path $migrationRoot "migration-backups")
    ).Count -eq 1) `
    "A post-migration rerun created another backup or rotation."

  $failureHashes = @{}
  foreach ($name in @(
    "Perfect-private.pfx",
    "Perfect-private.cer",
    "protected-secrets.json"
  )) {
    $failureHashes[$name] = (
      Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $failureRoot $name)
    ).Hash
  }
  $promotionFailureObserved = $false
  $env:PERFECT_PROVISION_TEST_FAILURE_POINT =
    "after-first-windows-promotion"
  try {
    try {
      $null = Invoke-SyntheticProvision $failureRoot
    } catch {
      $promotionFailureObserved =
        ($_ | Out-String).Contains("Injected Windows signing promotion failure.")
    }
  } finally {
    $env:PERFECT_PROVISION_TEST_FAILURE_POINT = $null
  }
  Assert-True `
    $promotionFailureObserved `
    "The migration rollback failure seam was not exercised."
  foreach ($name in $failureHashes.Keys) {
    Assert-True `
      ((Get-FileHash `
        -Algorithm SHA256 `
        -LiteralPath (Join-Path $failureRoot $name)
      ).Hash -ceq $failureHashes[$name]) `
      "Failed migration did not restore $name."
  }
  Assert-True `
    (@(Get-ChildItem `
      -Directory `
      -LiteralPath $failureRoot `
      -Filter ".windows-end-entity-staging-*"
    ).Count -eq 0) `
    "Failed migration left private staging material behind."

  Copy-Item `
    -LiteralPath (Join-Path $creationRoot "Perfect-private.cer") `
    -Destination (Join-Path $invalidRoot "Perfect-private.cer") `
    -Force
  $invalidHashes = @{}
  foreach ($name in @("Perfect-private.pfx", "Perfect-private.cer")) {
    $invalidHashes[$name] = (
      Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $invalidRoot $name)
    ).Hash
  }
  $invalidRejected = $false
  try {
    $null = Invoke-SyntheticProvision $invalidRoot
  } catch {
    $invalidRejected =
      ($_ | Out-String).Contains("Windows PFX and CER identities do not match.")
  }
  Assert-True $invalidRejected "An ambiguous Windows identity was not rejected."
  foreach ($name in $invalidHashes.Keys) {
    Assert-True `
      ((Get-FileHash `
        -Algorithm SHA256 `
        -LiteralPath (Join-Path $invalidRoot $name)
      ).Hash -ceq $invalidHashes[$name]) `
      "Rejected ambiguous identity changed $name."
  }
  Assert-True `
    (-not (Test-Path -LiteralPath (
      Join-Path $invalidRoot "migration-backups"
    ))) `
    "Rejected ambiguous identity created a migration backup."

  $protected = Get-Content `
    -Raw `
    -LiteralPath (Join-Path $migrationRoot "protected-secrets.json") |
      ConvertFrom-Json
  $migratedPassword = Unprotect-TestSecret $protected.windows_pfx_password
  try {
    Assert-True `
      ($migratedPassword -cne $legacyPassword) `
      "Migration reused the legacy Windows password."
  } finally {
    $migratedPassword = $null
  }

  Write-Output "Perfect private signing provisioner: PASS"
} finally {
  $legacyPassword = $null
  $env:PERFECT_PROVISION_TEST_FAILURE_POINT = $null
  if (Test-Path -LiteralPath $testRoot) {
    $resolvedTemp = (Resolve-Path -LiteralPath ([IO.Path]::GetTempPath())).Path
    $resolvedTest = (Resolve-Path -LiteralPath $testRoot).Path
    $tempPrefix = $resolvedTemp.TrimEnd(
      [IO.Path]::DirectorySeparatorChar,
      [IO.Path]::AltDirectorySeparatorChar
    ) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedTest.StartsWith(
      $tempPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )) {
      throw "Refusing to clean a provisioning test path outside system temp."
    }
    Remove-Item -LiteralPath $resolvedTest -Recurse -Force
  }
}
