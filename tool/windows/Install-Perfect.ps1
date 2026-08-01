[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet(
    "ValidatePayload",
    "MachineTrust",
    "InstallPackage",
    "RemoveTrust"
  )]
  [string]$Phase,

  [Parameter(Mandatory = $true)]
  [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
  [string]$MsixPath,

  [Parameter(Mandatory = $true)]
  [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
  [string]$CertificatePath,

  [Parameter(Mandatory = $true)]
  [ValidatePattern("^[0-9A-Fa-f]{40}$")]
  [string]$ExpectedThumbprint,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ExpectedSubject,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ExpectedPackageIdentityName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ExpectedPublisher,

  [Parameter(Mandatory = $true)]
  [ValidatePattern("^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$")]
  [string]$ExpectedVersion,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Windows PowerShell can expose the Certificate provider without materializing
# its conventional Cert: drive in a fresh -NoProfile child process (as seen on
# hosted Windows runners). Create only that provider-backed drive explicitly;
# every trust operation below remains pinned to LocalMachine\TrustedPeople.
Import-Module Microsoft.PowerShell.Security -ErrorAction Stop
if (-not (Get-PSDrive -Name Cert -ErrorAction SilentlyContinue)) {
  $null = New-PSDrive `
    -Name Cert `
    -PSProvider Certificate `
    -Root "\" `
    -ErrorAction Stop
}
if (
  (Get-PSDrive -Name Cert).Provider.Name -cne "Certificate" -or
  -not (Test-Path -LiteralPath "Cert:\LocalMachine\TrustedPeople")
) {
  throw "The Windows Certificate provider is unavailable."
}

$script:TrustedPeoplePath = "Cert:\LocalMachine\TrustedPeople"
$script:CodeSigningOid = "1.3.6.1.5.5.7.3.3"
$script:TrustAddedExitCode = 10
$script:NormalizedThumbprint = $ExpectedThumbprint.ToUpperInvariant()
$script:ResolvedMsixPath = (Resolve-Path -LiteralPath $MsixPath).Path
$script:ResolvedCertificatePath =
  (Resolve-Path -LiteralPath $CertificatePath).Path
$script:ExpectedPackageVersion = [version]::Parse($ExpectedVersion)

# The elevated machine phase writes only beneath ProgramData. The original-user
# phase resolves this marker inside that user's own profile. This avoids both
# writing an elevated log into a user-writable directory and accidentally
# resolving a standard user's profile as the UAC credential owner.
if ($LogPath -ceq "__PERFECT_ORIGINAL_USER_LOG__") {
  $LogPath = Join-Path $env:LOCALAPPDATA (
    "Perfect\InstallerLogs\Perfect-setup-{0}-user.log" -f $ExpectedVersion
  )
}

function Write-InstallerLog {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("INFO", "WARN", "ERROR")]
    [string]$Level,

    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  $line = "{0:o} [{1}] [{2}] {3}" -f (
    [DateTime]::UtcNow,
    $Level,
    $Phase,
    $Message
  )
  try {
    $parent = Split-Path -Parent $LogPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
      $null = New-Item -ItemType Directory -Path $parent -Force
    }
    [IO.File]::AppendAllText(
      $LogPath,
      $line + [Environment]::NewLine,
      [Text.UTF8Encoding]::new($false)
    )
  } catch {
    Write-Warning "Installer logging failed: $($_.Exception.Message)"
  }
  Write-Host $line
}

function Assert-Condition {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,

    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Test-IsAdministrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  try {
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole(
      [Security.Principal.WindowsBuiltInRole]::Administrator
    )
  } finally {
    $identity.Dispose()
  }
}

function Get-ExactlyOneCertificateExtension {
  param(
    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [Parameter(Mandatory = $true)]
    [string]$Oid
  )

  $matches = @($Certificate.Extensions | Where-Object {
    $_.Oid.Value -ceq $Oid
  })
  Assert-Condition `
    ($matches.Count -eq 1) `
    "Certificate must contain exactly one extension $Oid."
  return $matches[0]
}

function Assert-CertificateContract {
  param(
    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  Assert-Condition `
    (-not $Certificate.HasPrivateKey) `
    "The embedded CER unexpectedly contains a private key."
  Assert-Condition `
    ($Certificate.Thumbprint.ToUpperInvariant() -ceq
      $script:NormalizedThumbprint) `
    "Certificate thumbprint does not match the release pin."
  Assert-Condition `
    ($Certificate.Subject -ceq $ExpectedSubject) `
    "Certificate subject does not match the release pin."
  Assert-Condition `
    ($Certificate.Issuer -ceq $ExpectedSubject) `
    "Certificate must be the expected self-issued end entity."
  Assert-Condition `
    ($ExpectedPublisher -ceq $ExpectedSubject) `
    "Expected package publisher and certificate subject must be identical."
  Assert-Condition `
    ([DateTime]::UtcNow -ge $Certificate.NotBefore.ToUniversalTime() -and
      [DateTime]::UtcNow -le $Certificate.NotAfter.ToUniversalTime()) `
    "Certificate is outside its validity period."

  $basicSource = Get-ExactlyOneCertificateExtension `
    -Certificate $Certificate `
    -Oid "2.5.29.19"
  $basic =
    [Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::
      new($basicSource, $basicSource.Critical)
  Assert-Condition `
    $basicSource.Critical `
    "BasicConstraints must be marked critical."
  Assert-Condition `
    (-not $basic.CertificateAuthority) `
    "Package signer must be an end-entity certificate (CA=false)."
  Assert-Condition `
    (-not $basic.HasPathLengthConstraint) `
    "End-entity package signer must not contain a CA path-length constraint."

  $usageSource = Get-ExactlyOneCertificateExtension `
    -Certificate $Certificate `
    -Oid "2.5.29.15"
  $usage =
    [Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new(
      $usageSource,
      $usageSource.Critical
    )
  $digitalSignature =
    [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature
  Assert-Condition `
    $usageSource.Critical `
    "KeyUsage must be marked critical."
  Assert-Condition `
    (($usage.KeyUsages -band $digitalSignature) -eq $digitalSignature) `
    "Certificate KeyUsage must permit DigitalSignature."

  $ekuSource = Get-ExactlyOneCertificateExtension `
    -Certificate $Certificate `
    -Oid "2.5.29.37"
  $eku =
    [Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::
      new($ekuSource, $ekuSource.Critical)
  $ekuOids = @($eku.EnhancedKeyUsages | ForEach-Object { $_.Value })
  Assert-Condition `
    ($ekuOids.Count -eq 1 -and $ekuOids[0] -ceq $script:CodeSigningOid) `
    "Certificate EKU must contain only Code Signing."
}

function Read-PackageContract {
  param(
    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  Add-Type -AssemblyName System.Security
  $archive = [IO.Compression.ZipFile]::OpenRead($script:ResolvedMsixPath)
  try {
    $manifestEntry = $archive.GetEntry("AppxManifest.xml")
    $blockMapEntry = $archive.GetEntry("AppxBlockMap.xml")
    $signatureEntry = $archive.GetEntry("AppxSignature.p7x")
    Assert-Condition `
      ($null -ne $manifestEntry -and $null -ne $blockMapEntry -and
        $null -ne $signatureEntry) `
      "MSIX is missing its manifest, block map, or package signature."

    $reader = [IO.StreamReader]::new($manifestEntry.Open())
    try {
      [xml]$manifest = $reader.ReadToEnd()
    } finally {
      $reader.Dispose()
    }

    $namespaces = [Xml.XmlNamespaceManager]::new($manifest.NameTable)
    $namespaces.AddNamespace(
      "f",
      "http://schemas.microsoft.com/appx/manifest/foundation/windows10"
    )
    $identities = @($manifest.SelectNodes(
      "/f:Package/f:Identity",
      $namespaces
    ))
    Assert-Condition `
      ($identities.Count -eq 1) `
      "MSIX must contain exactly one package identity."
    $identity = $identities[0]
    Assert-Condition `
      ($identity.GetAttribute("Name") -ceq $ExpectedPackageIdentityName) `
      "MSIX identity name does not match the release contract."
    Assert-Condition `
      ($identity.GetAttribute("Publisher") -ceq $ExpectedPublisher) `
      "MSIX publisher does not match the release contract."
    Assert-Condition `
      ($identity.GetAttribute("ProcessorArchitecture") -ceq "x64") `
      "MSIX architecture must be x64."
    Assert-Condition `
      ($identity.GetAttribute("Version") -ceq $ExpectedVersion) `
      "MSIX version does not match the bootstrapper version."

    $displayNames = @($manifest.SelectNodes(
      "/f:Package/f:Properties/f:DisplayName",
      $namespaces
    ))
    Assert-Condition `
      ($displayNames.Count -eq 1 -and $displayNames[0].InnerText -ceq
        "Perfect!") `
      "MSIX display name must remain Perfect!."

    $applications = @($manifest.SelectNodes(
      "/f:Package/f:Applications/f:Application",
      $namespaces
    ))
    Assert-Condition `
      ($applications.Count -eq 1) `
      "MSIX must expose exactly one launch application."
    $application = $applications[0]
    Assert-Condition `
      ($application.GetAttribute("Id") -ceq "perfect" -and
        $application.GetAttribute("Executable") -ceq "perfect.exe" -and
        $application.GetAttribute("EntryPoint") -ceq
          "Windows.FullTrustApplication") `
      "MSIX launch registration drifted from the Perfect desktop contract."
    $namespaces.AddNamespace(
      "uap",
      "http://schemas.microsoft.com/appx/manifest/uap/windows10"
    )
    $protocols = @($manifest.SelectNodes(
      "//uap:Protocol[@Name='perfect']",
      $namespaces
    ))
    Assert-Condition `
      ($protocols.Count -eq 1) `
      "MSIX must contain exactly one perfect protocol registration."

    $blockMapReader = [IO.StreamReader]::new($blockMapEntry.Open())
    try {
      [xml]$blockMap = $blockMapReader.ReadToEnd()
    } finally {
      $blockMapReader.Dispose()
    }
    Assert-Condition `
      ($blockMap.DocumentElement.HashMethod -ceq
        "http://www.w3.org/2001/04/xmlenc#sha256") `
      "MSIX block map must use SHA-256."

    $signatureStream = $signatureEntry.Open()
    $signatureBuffer = [IO.MemoryStream]::new()
    try {
      $signatureStream.CopyTo($signatureBuffer)
      $signatureBytes = $signatureBuffer.ToArray()
    } finally {
      $signatureStream.Dispose()
      $signatureBuffer.Dispose()
    }
    Assert-Condition `
      ($signatureBytes.Length -gt 4 -and
        [Text.Encoding]::ASCII.GetString($signatureBytes, 0, 4) -ceq "PKCX") `
      "MSIX package signature has an invalid header."
    $cmsBytes = [byte[]]::new($signatureBytes.Length - 4)
    [Array]::Copy($signatureBytes, 4, $cmsBytes, 0, $cmsBytes.Length)
    $signedCms =
      [System.Security.Cryptography.Pkcs.SignedCms]::new()
    $signedCms.Decode($cmsBytes)
    $signedCms.CheckSignature($true)
    Assert-Condition `
      ($signedCms.SignerInfos.Count -eq 1) `
      "MSIX must contain exactly one primary signer."
    $packageSigner = $signedCms.SignerInfos[0].Certificate
    Assert-Condition `
      ($null -ne $packageSigner) `
      "MSIX signer certificate is missing."
    Assert-Condition `
      ($packageSigner.Thumbprint.ToUpperInvariant() -ceq
        $script:NormalizedThumbprint) `
      "MSIX signer thumbprint does not match the release pin."
    Assert-Condition `
      ($packageSigner.Subject -ceq $ExpectedSubject) `
      "MSIX signer subject does not match the release pin."
    Assert-Condition `
      ([Convert]::ToBase64String($packageSigner.RawData) -ceq
        [Convert]::ToBase64String($Certificate.RawData)) `
      "MSIX signer certificate does not byte-match the embedded CER."

    return [pscustomobject]@{
      IdentityName = $identity.GetAttribute("Name")
      Publisher = $identity.GetAttribute("Publisher")
      Version = [version]::Parse($identity.GetAttribute("Version"))
      Architecture = $identity.GetAttribute("ProcessorArchitecture")
    }
  } finally {
    $archive.Dispose()
  }
}

function Get-TrustedCertificate {
  $matches = @(Get-ChildItem -LiteralPath $script:TrustedPeoplePath |
    Where-Object {
      $_.Thumbprint.ToUpperInvariant() -ceq $script:NormalizedThumbprint
    })
  Assert-Condition `
    ($matches.Count -le 1) `
    "TrustedPeople contains duplicate entries for the pinned thumbprint."
  if ($matches.Count -eq 0) {
    return $null
  }
  return $matches[0]
}

function Assert-TrustedCertificateMatches {
  param(
    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Expected,

    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Actual
  )

  Assert-Condition `
    ([Convert]::ToBase64String($Actual.RawData) -ceq
      [Convert]::ToBase64String($Expected.RawData)) `
    "TrustedPeople entry does not byte-match the embedded release certificate."
  Assert-Condition `
    (-not $Actual.HasPrivateKey) `
    "TrustedPeople must contain only the public package certificate."
}

function Invoke-MachineTrust {
  param(
    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  Assert-Condition `
    (Test-IsAdministrator) `
    "Machine trust requires an elevated administrator token."
  $trusted = Get-TrustedCertificate
  if ($null -ne $trusted) {
    Assert-TrustedCertificateMatches -Expected $Certificate -Actual $trusted
    Write-InstallerLog INFO "Pinned certificate is already trusted; no change."
    return 0
  }

  try {
    $imported = Import-Certificate `
      -FilePath $script:ResolvedCertificatePath `
      -CertStoreLocation $script:TrustedPeoplePath
    Assert-Condition `
      ($null -ne $imported -and
        $imported.Thumbprint.ToUpperInvariant() -ceq
          $script:NormalizedThumbprint) `
      "Certificate import did not return the pinned TrustedPeople identity."
    $trusted = Get-TrustedCertificate
    Assert-Condition `
      ($null -ne $trusted) `
      "Pinned certificate is absent after TrustedPeople import."
    Assert-TrustedCertificateMatches -Expected $Certificate -Actual $trusted
    Write-InstallerLog INFO "Added the pinned public certificate to machine TrustedPeople."
    return $script:TrustAddedExitCode
  } catch {
    # There was no matching entry before this call. If Import-Certificate made
    # one before a later validation failed, this phase owns and removes it.
    $importFailure = $_.Exception
    try {
      $possiblyAdded = Get-TrustedCertificate
      if ($null -ne $possiblyAdded) {
        Assert-TrustedCertificateMatches `
          -Expected $Certificate `
          -Actual $possiblyAdded
        Remove-Item -LiteralPath $possiblyAdded.PSPath -Force
        Assert-Condition `
          ($null -eq (Get-TrustedCertificate)) `
          "TrustedPeople entry remains after failed-import rollback."
        Write-InstallerLog WARN (
          "Rolled back trust after machine-phase validation failed."
        )
      }
    } catch {
      throw (
        "Machine trust failed ({0}) and its rollback also failed ({1})." -f
          $importFailure.Message,
          $_.Exception.Message
      )
    }
    throw $importFailure
  }
}

function Invoke-RemoveTrust {
  param(
    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  Assert-Condition `
    (Test-IsAdministrator) `
    "Trust rollback requires an elevated administrator token."
  $trusted = Get-TrustedCertificate
  if ($null -eq $trusted) {
    Write-InstallerLog INFO "Rollback found no pinned TrustedPeople entry."
    return 0
  }
  Assert-TrustedCertificateMatches -Expected $Certificate -Actual $trusted
  Remove-Item -LiteralPath $trusted.PSPath -Force
  Assert-Condition `
    ($null -eq (Get-TrustedCertificate)) `
    "Pinned certificate remains after TrustedPeople rollback."
  Write-InstallerLog INFO "Rolled back the TrustedPeople entry added by this setup run."
  return 0
}

function Get-CurrentUserPackage {
  $packages = @(Get-AppxPackage -Name $ExpectedPackageIdentityName |
    Where-Object { $_.Name -ceq $ExpectedPackageIdentityName })
  Assert-Condition `
    ($packages.Count -le 1) `
    "Current user has multiple installed packages with the Perfect identity."
  if ($packages.Count -eq 0) {
    return $null
  }
  $package = $packages[0]
  Assert-Condition `
    ($package.Publisher -ceq $ExpectedPublisher) `
    "Installed package publisher conflicts with the release identity."
  Assert-Condition `
    ($package.Architecture.ToString() -ceq "X64") `
    "Installed Perfect package architecture is not x64."
  return $package
}

function Invoke-InstallPackage {
  param(
    [Parameter(Mandatory = $true)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  $trusted = Get-TrustedCertificate
  Assert-Condition `
    ($null -ne $trusted) `
    "Pinned package certificate is absent from machine TrustedPeople."
  Assert-TrustedCertificateMatches -Expected $Certificate -Actual $trusted

  $before = Get-CurrentUserPackage
  if ($null -ne $before) {
    $beforeVersion = [version]$before.Version
    if ($beforeVersion -gt $script:ExpectedPackageVersion) {
      Write-InstallerLog WARN ((
        "A newer Perfect version ({0}) is already installed for this user; " +
        "the bootstrapper will not downgrade it."
      ) -f $beforeVersion)
      return 0
    }
    if ($beforeVersion -eq $script:ExpectedPackageVersion) {
      Write-InstallerLog INFO ((
        "Perfect {0} is already installed for this user; no change."
      ) -f $beforeVersion)
      return 0
    }
  }

  $beforeFamily = if ($null -ne $before) { $before.PackageFamilyName } else { $null }
  $beforeLocalState = if ($beforeFamily) {
    Join-Path $env:LOCALAPPDATA "Packages\$beforeFamily\LocalState"
  } else {
    $null
  }
  $localStateExisted =
    ($beforeLocalState -and (Test-Path -LiteralPath $beforeLocalState))

  Write-InstallerLog INFO ((
    "Installing Perfect {0} for interactive user {1}."
  ) -f $ExpectedVersion,
    [Security.Principal.WindowsIdentity]::GetCurrent().Name)
  Add-AppxPackage `
    -Path $script:ResolvedMsixPath `
    -ForceApplicationShutdown

  $after = Get-CurrentUserPackage
  Assert-Condition `
    ($null -ne $after) `
    "Perfect package is absent after Add-AppxPackage completed."
  Assert-Condition `
    ([version]$after.Version -eq $script:ExpectedPackageVersion) `
    "Installed package version does not match the bootstrapper payload."
  $installedExecutable = Join-Path $after.InstallLocation "perfect.exe"
  Assert-Condition `
    (Test-Path -LiteralPath $installedExecutable -PathType Leaf) `
    "Perfect launch executable is absent after package registration."
  if ($beforeFamily) {
    Assert-Condition `
      ($after.PackageFamilyName -ceq $beforeFamily) `
      "Package family changed during the in-place upgrade."
  }
  if ($localStateExisted) {
    Assert-Condition `
      (Test-Path -LiteralPath $beforeLocalState -PathType Container) `
      "The existing LocalState directory disappeared during upgrade."
  }
  Write-InstallerLog INFO ((
    "Perfect {0} installed successfully; package family is {1}."
  ) -f $after.Version, $after.PackageFamilyName)
  return 0
}

try {
  Assert-Condition `
    ([IO.Path]::GetExtension($script:ResolvedMsixPath) -ceq ".msix") `
    "Package payload must use the .msix extension."
  Assert-Condition `
    ([IO.Path]::GetExtension($script:ResolvedCertificatePath) -ceq ".cer") `
    "Certificate payload must use the .cer extension."
  Write-InstallerLog INFO "Starting fail-closed payload validation."
  $certificate =
    [Security.Cryptography.X509Certificates.X509Certificate2]::new(
      $script:ResolvedCertificatePath
    )
  try {
    Assert-CertificateContract -Certificate $certificate
    $packageContract = Read-PackageContract -Certificate $certificate
    Write-InstallerLog INFO ((
      "Validated signed MSIX {0} version {1} for publisher {2}."
    ) -f $packageContract.IdentityName, $packageContract.Version,
      $packageContract.Publisher)

    $exitCode = switch ($Phase) {
      "ValidatePayload" { 0 }
      "MachineTrust" { Invoke-MachineTrust -Certificate $certificate }
      "InstallPackage" { Invoke-InstallPackage -Certificate $certificate }
      "RemoveTrust" { Invoke-RemoveTrust -Certificate $certificate }
      default { throw "Unsupported installer phase $Phase." }
    }
  } finally {
    $certificate.Dispose()
  }
  Write-InstallerLog INFO "Phase completed with exit code $exitCode."
  exit $exitCode
} catch {
  Write-InstallerLog ERROR $_.Exception.Message
  Write-Error $_.Exception.Message
  exit 1
}
