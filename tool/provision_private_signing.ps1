[CmdletBinding()]
param(
  [string]$Repository = "k1tvkli2003/Perfect",
  [string]$SigningRoot = (Join-Path $env:USERPROFILE ".perfect-signing")
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
  & gh variable set $Name --repo $Repository --body $Value
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to set GitHub variable $Name."
  }
}

$keytool = (Get-Command keytool -ErrorAction Stop).Source
$openssl = (Get-Command openssl -ErrorAction Stop).Source
$script:GhExecutable = (Get-Command gh -ErrorAction Stop).Source

$androidKeystore = Join-Path $SigningRoot "perfect-private.jks"
$windowsPfx = Join-Path $SigningRoot "Perfect-private.pfx"
$windowsCer = Join-Path $SigningRoot "Perfect-private.cer"
$androidCer = Join-Path $SigningRoot "perfect-private-android.cer"
$protectedSecretsPath = Join-Path $SigningRoot "protected-secrets.json"
$manifestPath = Join-Path $SigningRoot "signing-manifest.json"
$privatePem = Join-Path $SigningRoot "Perfect-private-key.pem"
$certificatePem = Join-Path $SigningRoot "Perfect-private-cert.pem"
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

    $env:PERFECT_PROVISION_WINDOWS_PASSWORD = $windowsPassword
    & $openssl req `
      -x509 `
      -newkey rsa:4096 `
      -sha256 `
      -days 3650 `
      -keyout $privatePem `
      -out $certificatePem `
      -passout env:PERFECT_PROVISION_WINDOWS_PASSWORD `
      -subj "/CN=K1 Perfect Private" `
      -addext "keyUsage=digitalSignature" `
      -addext "extendedKeyUsage=codeSigning"
    if ($LASTEXITCODE -ne 0) {
      throw "Windows code-signing certificate generation failed."
    }
    & $openssl pkcs12 `
      -export `
      -out $windowsPfx `
      -inkey $privatePem `
      -in $certificatePem `
      -name "Perfect Private Code Signing" `
      -passin env:PERFECT_PROVISION_WINDOWS_PASSWORD `
      -passout env:PERFECT_PROVISION_WINDOWS_PASSWORD
    if ($LASTEXITCODE -ne 0) {
      throw "Windows PFX export failed."
    }
    & $openssl x509 `
      -in $certificatePem `
      -outform der `
      -out $windowsCer
    if ($LASTEXITCODE -ne 0) {
      throw "Windows public certificate export failed."
    }

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
    if (Test-Path -LiteralPath $privatePem) {
      Remove-Item -LiteralPath $privatePem -Force
    }
    if (Test-Path -LiteralPath $certificatePem) {
      Remove-Item -LiteralPath $certificatePem -Force
    }
  }
}

$protected = Get-Content -Raw -LiteralPath $protectedSecretsPath |
  ConvertFrom-Json
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

  Set-RepositorySecret "PERFECT_ANDROID_KEYSTORE_BASE64" $androidBase64
  Set-RepositorySecret "PERFECT_ANDROID_KEYSTORE_PASSWORD" $androidStorePassword
  Set-RepositorySecret "PERFECT_ANDROID_KEY_ALIAS" $protected.android_alias
  Set-RepositorySecret "PERFECT_ANDROID_KEY_PASSWORD" $androidKeyPassword
  Set-RepositorySecret "PERFECT_WINDOWS_PFX_BASE64" $windowsBase64
  Set-RepositorySecret "PERFECT_WINDOWS_PFX_PASSWORD" $windowsPfxPassword
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

Set-RepositoryVariable `
  "PERFECT_ANDROID_CERT_SHA256" `
  $androidCertificateSha256
Set-RepositoryVariable `
  "PERFECT_WINDOWS_CERT_THUMBPRINT" `
  $windowsCertificateThumbprint

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
Write-Output "GitHub repository: $Repository"
