[CmdletBinding()]
param(
  [string]$Repository = "k1tvkli2003/Perfect",
  [string]$SigningRoot = (Join-Path $env:USERPROFILE ".perfect-signing"),
  [switch]$SkipRepositorySync
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function New-RandomSecret {
  $bytes = [byte[]]::new(48)
  [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
  return [Convert]::ToBase64String($bytes)
    .TrimEnd("=")
    .Replace("+", "-")
    .Replace("/", "_")
}

function Protect-LocalSecret([string]$Value) {
  $secure = ConvertTo-SecureString $Value -AsPlainText -Force
  return ConvertFrom-SecureString $secure
}

function Unprotect-LocalSecret([string]$Value) {
  $secure = ConvertTo-SecureString $Value
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
}

function Set-RepositorySecret(
  [string]$Name,
  [string]$Value
) {
  # gh accepts the secret body on stdin. Use a redirected process and Write()
  # (not WriteLine/pipeline output) so the secret is neither placed in argv nor
  # silently changed by an appended newline.
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $script:GhExecutable
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardInput = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.CreateNoWindow = $true
  foreach ($argument in @(
    "secret",
    "set",
    $Name,
    "--repo",
    $Repository
  )) {
    $startInfo.ArgumentList.Add($argument)
  }

  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  try {
    if (-not $process.Start()) {
      throw "Failed to start GitHub CLI for secret $Name."
    }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.Write($Value)
    $process.StandardInput.Close()
    $process.WaitForExit()
    $null = $stdoutTask.GetAwaiter().GetResult()
    $null = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
  } finally {
    $process.Dispose()
  }
  if ($exitCode -ne 0) {
    throw "Failed to set GitHub secret $Name."
  }
}

function Set-RepositoryVariable(
  [string]$Name,
  [string]$Value
) {
  & $script:GhExecutable variable set $Name --repo $Repository --body $Value
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to set GitHub variable $Name."
  }
}

function Get-CertificateExtension(
  [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
  [string]$Oid
) {
  $matches = @($Certificate.Extensions | Where-Object {
    $_.Oid.Value -ceq $Oid
  })
  if ($matches.Count -ne 1) {
    throw "The Windows certificate must contain exactly one extension $Oid."
  }

  return $matches[0]
}

function Get-WindowsSigningIdentityState(
  [string]$PfxPath,
  [string]$CerPath,
  [string]$Password
) {
  $collection =
    [Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
  $publicCertificate = $null
  try {
    $flags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::
      EphemeralKeySet
    $collection.Import(
      [IO.File]::ReadAllBytes($PfxPath),
      $Password,
      $flags
    )
    $privateCertificates = @($collection | Where-Object { $_.HasPrivateKey })
    if ($privateCertificates.Count -ne 1) {
      throw "The Windows PFX must contain exactly one private-key certificate."
    }
    $certificate = $privateCertificates[0]
    $publicCertificate =
      [Security.Cryptography.X509Certificates.X509Certificate2]::new($CerPath)
    $thumbprint = $certificate.Thumbprint.ToUpperInvariant()
    if ($thumbprint -cne $publicCertificate.Thumbprint.ToUpperInvariant()) {
      throw "The Windows PFX and CER identities do not match."
    }
    if ($certificate.Subject -cne "CN=K1 Perfect Private" -or
        $certificate.Issuer -cne $certificate.Subject) {
      throw "The Windows certificate is not the expected self-issued identity."
    }
    if ([DateTime]::UtcNow -lt $certificate.NotBefore.ToUniversalTime() -or
        [DateTime]::UtcNow -gt $certificate.NotAfter.ToUniversalTime()) {
      throw "The Windows certificate is outside its validity period."
    }

    $keyUsageSource = Get-CertificateExtension $certificate "2.5.29.15"
    if ($null -eq $keyUsageSource) {
      throw "The Windows certificate has no key-usage extension."
    }
    $keyUsage =
      [Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new(
        $keyUsageSource,
        $keyUsageSource.Critical
      )
    if (($keyUsage.KeyUsages -band
        [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::
          DigitalSignature) -eq 0) {
      throw "The Windows certificate cannot create digital signatures."
    }

    $enhancedKeyUsageSource = Get-CertificateExtension $certificate "2.5.29.37"
    if ($null -eq $enhancedKeyUsageSource) {
      throw "The Windows certificate has no enhanced-key-usage extension."
    }
    $enhancedKeyUsage =
      [Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::
        new($enhancedKeyUsageSource, $enhancedKeyUsageSource.Critical)
    if (@($enhancedKeyUsage.EnhancedKeyUsages | Where-Object {
      $_.Value -ceq "1.3.6.1.5.5.7.3.3"
    }).Count -ne 1) {
      throw "The Windows certificate is not restricted to code signing."
    }

    $basicConstraintsSource = Get-CertificateExtension $certificate "2.5.29.19"
    if ($null -eq $basicConstraintsSource) {
      throw "The Windows certificate has no Basic Constraints extension."
    }
    $basicConstraints =
      [Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::
        new($basicConstraintsSource, $basicConstraintsSource.Critical)
    $classification = if ($basicConstraints.CertificateAuthority) {
      "LegacyCertificateAuthority"
    } elseif (-not $basicConstraintsSource.Critical) {
      throw "Basic Constraints must be critical for the Windows signer."
    } else {
      "ValidEndEntity"
    }

    return [pscustomobject]@{
      Classification = $classification
      Thumbprint = $thumbprint
      Subject = $certificate.Subject
      NotAfter = $certificate.NotAfter.ToUniversalTime()
    }
  } finally {
    if ($null -ne $publicCertificate) {
      $publicCertificate.Dispose()
    }
    foreach ($certificateToDispose in $collection) {
      $certificateToDispose.Dispose()
    }
  }
}

function New-WindowsEndEntitySigningMaterial(
  [string]$Destination,
  [string]$Password
) {
  $pfxPath = Join-Path $Destination "Perfect-private.pfx"
  $cerPath = Join-Path $Destination "Perfect-private.cer"
  $privateKeyPath = Join-Path $Destination "Perfect-private-key.pem"
  $certificatePath = Join-Path $Destination "Perfect-private-cert.pem"
  $env:PERFECT_PROVISION_WINDOWS_PASSWORD = $Password
  try {
    & $openssl req `
      -x509 `
      -newkey rsa:4096 `
      -sha256 `
      -days 3650 `
      -keyout $privateKeyPath `
      -out $certificatePath `
      -passout env:PERFECT_PROVISION_WINDOWS_PASSWORD `
      -subj "/CN=K1 Perfect Private" `
      -addext "basicConstraints=critical,CA:FALSE" `
      -addext "keyUsage=critical,digitalSignature" `
      -addext "extendedKeyUsage=critical,codeSigning"
    if ($LASTEXITCODE -ne 0) {
      throw "Windows end-entity certificate generation failed."
    }
    & $openssl pkcs12 `
      -export `
      -out $pfxPath `
      -inkey $privateKeyPath `
      -in $certificatePath `
      -name "Perfect Private Code Signing" `
      -passin env:PERFECT_PROVISION_WINDOWS_PASSWORD `
      -passout env:PERFECT_PROVISION_WINDOWS_PASSWORD
    if ($LASTEXITCODE -ne 0) {
      throw "Windows PFX export failed."
    }
    & $openssl x509 `
      -in $certificatePath `
      -outform der `
      -out $cerPath
    if ($LASTEXITCODE -ne 0) {
      throw "Windows public certificate export failed."
    }
    $state = Get-WindowsSigningIdentityState $pfxPath $cerPath $Password
    if ($state.Classification -cne "ValidEndEntity") {
      throw "The generated Windows signer is not a valid end entity."
    }
    return $state
  } finally {
    $env:PERFECT_PROVISION_WINDOWS_PASSWORD = $null
    foreach ($temporaryPath in @($privateKeyPath, $certificatePath)) {
      if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
      }
    }
  }
}

function Backup-LegacyWindowsSigningIdentity(
  [string]$Root,
  [string]$Thumbprint,
  [string[]]$Paths
) {
  $backupParent = Join-Path $Root "migration-backups"
  $backupPath = Join-Path $backupParent "windows-ca-$Thumbprint"
  $filePaths = @($Paths | Where-Object {
    Test-Path -LiteralPath $_ -PathType Leaf
  })
  if (Test-Path -LiteralPath $backupPath) {
    foreach ($sourcePath in $filePaths) {
      $backupFile = Join-Path $backupPath (Split-Path -Leaf $sourcePath)
      if (-not (Test-Path -LiteralPath $backupFile -PathType Leaf) -or
          (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -cne
          (Get-FileHash -Algorithm SHA256 -LiteralPath $backupFile).Hash) {
        throw "The existing Windows migration backup does not match source state."
      }
    }
    return $backupPath
  }

  New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
  $partialPath = "$backupPath.partial.$([Guid]::NewGuid().ToString('N'))"
  try {
    New-Item -ItemType Directory -Path $partialPath | Out-Null
    foreach ($sourcePath in $filePaths) {
      Copy-Item -LiteralPath $sourcePath -Destination $partialPath
    }
    @{
      version = 1
      reason = "legacy-self-signed-ca-to-end-entity"
      old_windows_certificate_thumbprint = $Thumbprint
      backed_up_at = (Get-Date).ToUniversalTime().ToString("o")
      files = @($filePaths | ForEach-Object {
        @{
          name = Split-Path -Leaf $_
          sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash
        }
      })
    } | ConvertTo-Json -Depth 4 |
      Set-Content `
        -LiteralPath (Join-Path $partialPath "migration-manifest.json") `
        -Encoding utf8
    & icacls $partialPath /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" |
      Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to restrict the Windows migration backup ACL."
    }
    [IO.Directory]::Move($partialPath, $backupPath)
    return $backupPath
  } finally {
    if (Test-Path -LiteralPath $partialPath) {
      Remove-Item -LiteralPath $partialPath -Recurse -Force
    }
  }
}

function Repair-LegacyWindowsSigningIdentity(
  [string]$Root,
  [pscustomobject]$ProtectedSecrets,
  [pscustomobject]$LegacyState,
  [string]$PfxPath,
  [string]$CerPath,
  [string]$ProtectedPath,
  [string]$ManifestPath
) {
  $backupPath = Backup-LegacyWindowsSigningIdentity `
    $Root `
    $LegacyState.Thumbprint `
    @($PfxPath, $CerPath, $ProtectedPath, $ManifestPath)
  $stagingPath = Join-Path $Root (
    ".windows-end-entity-staging-$([Guid]::NewGuid().ToString('N'))"
  )
  $newPassword = New-RandomSecret
  $promotedPaths = @($PfxPath, $CerPath, $ProtectedPath)
  try {
    New-Item -ItemType Directory -Path $stagingPath | Out-Null
    $null = New-WindowsEndEntitySigningMaterial $stagingPath $newPassword
    @{
      version = 1
      android_alias = $ProtectedSecrets.android_alias
      android_store_password = $ProtectedSecrets.android_store_password
      android_key_password = $ProtectedSecrets.android_key_password
      windows_pfx_password = Protect-LocalSecret $newPassword
    } | ConvertTo-Json |
      Set-Content `
        -LiteralPath (Join-Path $stagingPath "protected-secrets.json") `
        -Encoding utf8

    foreach ($destination in $promotedPaths) {
      $source = Join-Path $stagingPath (Split-Path -Leaf $destination)
      Copy-Item -LiteralPath $source -Destination $destination -Force
      if ($env:PERFECT_PROVISION_TEST_FAILURE_POINT -ceq
          "after-first-windows-promotion") {
        $env:PERFECT_PROVISION_TEST_FAILURE_POINT = $null
        throw "Injected Windows signing promotion failure."
      }
    }
    $verified = Get-WindowsSigningIdentityState $PfxPath $CerPath $newPassword
    if ($verified.Classification -cne "ValidEndEntity") {
      throw "The promoted Windows signer failed end-entity validation."
    }
    return [pscustomobject]@{
      State = $verified
      BackupPath = $backupPath
    }
  } catch {
    foreach ($destination in $promotedPaths) {
      $backupFile = Join-Path $backupPath (Split-Path -Leaf $destination)
      if (Test-Path -LiteralPath $backupFile -PathType Leaf) {
        Copy-Item -LiteralPath $backupFile -Destination $destination -Force
      }
    }
    throw
  } finally {
    $newPassword = $null
    if (Test-Path -LiteralPath $stagingPath) {
      Remove-Item -LiteralPath $stagingPath -Recurse -Force
    }
  }
}

$keytool = (Get-Command keytool -ErrorAction Stop).Source
$openssl = (Get-Command openssl -ErrorAction Stop).Source
$script:GhExecutable = if ($SkipRepositorySync) {
  $null
} else {
  (Get-Command gh -ErrorAction Stop).Source
}

$androidKeystore = Join-Path $SigningRoot "perfect-private.jks"
$windowsPfx = Join-Path $SigningRoot "Perfect-private.pfx"
$windowsCer = Join-Path $SigningRoot "Perfect-private.cer"
$androidCer = Join-Path $SigningRoot "perfect-private-android.cer"
$protectedSecretsPath = Join-Path $SigningRoot "protected-secrets.json"
$manifestPath = Join-Path $SigningRoot "signing-manifest.json"
$androidAlias = "perfect"

New-Item -ItemType Directory -Force -Path $SigningRoot | Out-Null
& icacls $SigningRoot /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to restrict the signing directory ACL."
}

$requiredExisting = @(
  $androidKeystore,
  $windowsPfx,
  $windowsCer,
  $protectedSecretsPath
)
$existingCount = @($requiredExisting | Where-Object {
  Test-Path -LiteralPath $_
}).Count
if ($existingCount -ne 0 -and $existingCount -ne $requiredExisting.Count) {
  throw "Signing state is incomplete. Preserve it and repair manually; no key will be overwritten."
}

if ($existingCount -eq 0) {
  $androidPassword = New-RandomSecret
  $windowsPassword = New-RandomSecret
  try {
    $env:PERFECT_PROVISION_ANDROID_PASSWORD = $androidPassword
    & $keytool `
      -genkeypair `
      -keystore $androidKeystore `
      -storetype JKS `
      -storepass:env PERFECT_PROVISION_ANDROID_PASSWORD `
      -keypass:env PERFECT_PROVISION_ANDROID_PASSWORD `
      -alias $androidAlias `
      -keyalg RSA `
      -keysize 4096 `
      -sigalg SHA256withRSA `
      -validity 10000 `
      -dname "CN=K1 Perfect Private, O=Perfect, C=IR"
    if ($LASTEXITCODE -ne 0) {
      throw "Android keystore generation failed."
    }

    $null = New-WindowsEndEntitySigningMaterial $SigningRoot $windowsPassword

    @{
      version = 1
      android_alias = $androidAlias
      android_store_password = Protect-LocalSecret $androidPassword
      android_key_password = Protect-LocalSecret $androidPassword
      windows_pfx_password = Protect-LocalSecret $windowsPassword
    } |
      ConvertTo-Json |
      Set-Content -LiteralPath $protectedSecretsPath -Encoding utf8
  } finally {
    $env:PERFECT_PROVISION_ANDROID_PASSWORD = $null
    $env:PERFECT_PROVISION_WINDOWS_PASSWORD = $null
  }
}

$protected = Get-Content -Raw -LiteralPath $protectedSecretsPath |
  ConvertFrom-Json
$windowsPfxPassword = Unprotect-LocalSecret $protected.windows_pfx_password
try {
  $windowsState = Get-WindowsSigningIdentityState `
    $windowsPfx `
    $windowsCer `
    $windowsPfxPassword
} finally {
  $windowsPfxPassword = $null
}
if ($windowsState.Classification -ceq "LegacyCertificateAuthority") {
  $repair = Repair-LegacyWindowsSigningIdentity `
    $SigningRoot `
    $protected `
    $windowsState `
    $windowsPfx `
    $windowsCer `
    $protectedSecretsPath `
    $manifestPath
  $protected = Get-Content -Raw -LiteralPath $protectedSecretsPath |
    ConvertFrom-Json
  $windowsState = $repair.State
  Write-Output (
    "Repaired legacy Windows CA signer; recoverable backup: " +
    $repair.BackupPath
  )
}
if ($windowsState.Classification -cne "ValidEndEntity") {
  throw "The Windows signing identity is not a valid end entity."
}

$androidStorePassword = Unprotect-LocalSecret $protected.android_store_password
$androidKeyPassword = Unprotect-LocalSecret $protected.android_key_password
$windowsPfxPassword = Unprotect-LocalSecret $protected.windows_pfx_password
try {
  $androidBase64 = [Convert]::ToBase64String(
    [IO.File]::ReadAllBytes($androidKeystore)
  )
  $windowsBase64 = [Convert]::ToBase64String(
    [IO.File]::ReadAllBytes($windowsPfx)
  )

  if (-not $SkipRepositorySync) {
    Set-RepositorySecret "PERFECT_ANDROID_KEYSTORE_BASE64" $androidBase64
    Set-RepositorySecret `
      "PERFECT_ANDROID_KEYSTORE_PASSWORD" `
      $androidStorePassword
    Set-RepositorySecret "PERFECT_ANDROID_KEY_ALIAS" $protected.android_alias
    Set-RepositorySecret "PERFECT_ANDROID_KEY_PASSWORD" $androidKeyPassword
    Set-RepositorySecret "PERFECT_WINDOWS_PFX_BASE64" $windowsBase64
    Set-RepositorySecret "PERFECT_WINDOWS_PFX_PASSWORD" $windowsPfxPassword
  }
} finally {
  $androidBase64 = $null
  $windowsBase64 = $null
  $androidStorePassword = $null
  $androidKeyPassword = $null
  $windowsPfxPassword = $null
}

$env:PERFECT_PROVISION_ANDROID_PASSWORD = Unprotect-LocalSecret (
  $protected.android_store_password
)
try {
  & $keytool `
    -exportcert `
    -keystore $androidKeystore `
    -storepass:env PERFECT_PROVISION_ANDROID_PASSWORD `
    -alias $protected.android_alias `
    -file $androidCer
  if ($LASTEXITCODE -ne 0) {
    throw "Android public certificate export failed."
  }
} finally {
  $env:PERFECT_PROVISION_ANDROID_PASSWORD = $null
}

$certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
  $windowsCer
)
$androidCertificateSha256 = (
  Get-FileHash -Algorithm SHA256 -LiteralPath $androidCer
).Hash.ToUpperInvariant()
$windowsCertificateThumbprint = $certificate.Thumbprint.ToUpperInvariant()

if (-not $SkipRepositorySync) {
  Set-RepositoryVariable `
    "PERFECT_ANDROID_CERT_SHA256" `
    $androidCertificateSha256
  Set-RepositoryVariable `
    "PERFECT_WINDOWS_CERT_THUMBPRINT" `
    $windowsCertificateThumbprint
}

@{
  version = 1
  repository = $Repository
  created_or_verified_at = (Get-Date).ToUniversalTime().ToString("o")
  android_alias = $protected.android_alias
  android_keystore_sha256 = (
    Get-FileHash -Algorithm SHA256 -LiteralPath $androidKeystore
  ).Hash
  android_certificate_sha256 = $androidCertificateSha256
  windows_certificate_subject = $certificate.Subject
  windows_certificate_thumbprint = $windowsCertificateThumbprint
  windows_certificate_not_after = $certificate.NotAfter.ToUniversalTime().ToString("o")
  windows_pfx_sha256 = (
    Get-FileHash -Algorithm SHA256 -LiteralPath $windowsPfx
  ).Hash
} |
  ConvertTo-Json |
  Set-Content -LiteralPath $manifestPath -Encoding utf8
$certificate.Dispose()

Write-Output "Perfect private signing identity is provisioned."
Write-Output "Signing root: $SigningRoot"
if ($SkipRepositorySync) {
  Write-Output "GitHub repository sync was skipped."
} else {
  Write-Output "GitHub repository: $Repository"
}
