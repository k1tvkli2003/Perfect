[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,

    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "ASSERTION FAILED: $Message"
  }
}

function Assert-Contains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Message
  )

  Assert-True ($Text.Contains($Needle)) $Message
}

function Assert-DoesNotMatch {
  param(
    [string]$Text,
    [string]$Pattern,
    [string]$Message
  )

  Assert-True (-not [regex]::IsMatch(
    $Text,
    $Pattern,
    [Text.RegularExpressions.RegexOptions]::IgnoreCase
  )) $Message
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$installerRoot = Join-Path $repositoryRoot "tool\windows"
$issPath = Join-Path $installerRoot "PerfectBootstrap.iss"
$scriptPath = Join-Path $installerRoot "Install-Perfect.ps1"
$workflowPath = Join-Path $repositoryRoot ".github\workflows\verify.yml"

Assert-True (Test-Path -LiteralPath $issPath -PathType Leaf) `
  "PerfectBootstrap.iss must exist."
Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) `
  "Install-Perfect.ps1 must exist."
Assert-True (Test-Path -LiteralPath $workflowPath -PathType Leaf) `
  "Windows installer workflow must exist."

$iss = Get-Content -Raw -LiteralPath $issPath
$installer = Get-Content -Raw -LiteralPath $scriptPath
$workflow = Get-Content -Raw -LiteralPath $workflowPath

Assert-Contains $installer 'Import-Module Microsoft.PowerShell.Security' `
  "Fresh no-profile installer children must load the Certificate provider."
Assert-Contains $installer 'New-PSDrive' `
  "Installer must materialize Cert: when a fresh child omits the drive."
Assert-Contains $installer '-PSProvider Certificate' `
  "The materialized Cert: drive must use the Windows Certificate provider."
Assert-Contains $installer 'Cert:\LocalMachine\TrustedPeople' `
  "The provider must remain scoped to machine TrustedPeople."

# Inno 7's compiler binaries intentionally expose FileVersion 0.0.0.0. The
# pinned distribution's uninstaller carries ProductVersion 7.0.2 with fixed-
# width trailing padding, so CI must use and trim that explicit version carrier.
Assert-Contains $workflow "Join-Path `$installRoot 'unins000.exe'" `
  "CI must read the pinned Inno distribution version carrier."
Assert-Contains $workflow ").VersionInfo.ProductVersion.Trim()" `
  "CI must trim Inno 7's fixed-width ProductVersion before exact comparison."
Assert-Contains $workflow 'PERFECT_ISCC_PATH=$iscc' `
  "CI must preserve the exact verified compiler path across steps."
Assert-Contains $workflow 'PERFECT_ISCC_VERSION=$compilerVersion' `
  "CI must preserve the exact verified compiler version across steps."
Assert-DoesNotMatch $workflow `
  'ISCC[^\r\n]*VersionInfo\.FileVersion|VersionInfo\.FileVersion[^\r\n]*ISCC' `
  "CI must not infer Inno 7 version from ISCC's neutral 0.0.0.0 resource."
Assert-Contains $workflow '-FilePath $Path' `
  "Hosted Setup proof must launch the exact generated executable."
Assert-Contains $workflow '-WindowStyle Hidden' `
  "Hosted Setup proof must remain non-interactive and deterministic."
Assert-Contains $workflow '$process.ExitCode' `
  "Hosted Setup proof must wait for and inspect the GUI process exit code."
Assert-Contains $workflow 'Perfect Setup diagnostic:' `
  "Hosted Setup proof must expose non-secret bootstrap diagnostics."
Assert-Contains $workflow '$machineInstallerLog' `
  "Hosted Setup proof must capture the elevated machine-phase log."
Assert-Contains $workflow '$userInstallerLog' `
  "Hosted Setup proof must capture the original-user phase log."
Assert-Contains $workflow '[DateTime]::UtcNow.AddSeconds(15)' `
  "Hosted Setup proof must allow bounded package-registration propagation."
Assert-Contains $workflow 'Start-Sleep -Milliseconds 500' `
  "Hosted Setup proof must poll registration without a busy loop."
Assert-DoesNotMatch $workflow '&\s+\$Path\s+@arguments' `
  "Hosted Setup proof must not fire-and-forget the GUI executable."

# Single-file bootstrapper and ownership contract.
Assert-Contains $iss "Uninstallable=no" `
  "MSIX, not Inno Setup, must own uninstallation."
Assert-Contains $iss "CreateUninstallRegKey=no" `
  "Bootstrapper must not create a competing uninstall entry."
Assert-Contains $iss "PrivilegesRequired=admin" `
  "Machine TrustedPeople import must require UAC elevation."
Assert-Contains $iss "SetupArchitecture=x64" `
  "The Windows x64 release must use Inno 7's native x64 Setup loader/runtime."
Assert-Contains $iss "SetupIconFile={#SetupIcon}" `
  "Installer must use the project-owned Perfect icon."
Assert-Contains $iss "Compression=lzma2/ultra64" `
  "Bootstrapper should use deterministic high compression."
Assert-Contains $iss "SolidCompression=yes" `
  "Bootstrapper should produce one compact payload."
$embeddedSources = [regex]::Matches($iss, '(?m)^Source:\s*').Count
Assert-True ($embeddedSources -eq 3) `
  "Bootstrapper must embed exactly MSIX, CER, and installer script."
Assert-True (
  [regex]::Matches(
    $iss,
    '(?m)^Source:.*Flags:.*\bdeleteafterinstall\b'
  ).Count -eq 3
) "All three staged support payloads must be deleted after Setup."
Assert-Contains $iss "{autopf}\Perfect Installer Staging\" `
  "Executable payloads must stage beneath protected Program Files."
Assert-Contains $iss "RedirectionGuard=yes" `
  "Installer must keep Inno reparse-point redirection protection enabled."
Assert-Contains $iss "ExtractFileName(ExpandConstant('{tmp}'))" `
  "Each Setup run must use a unique staging child directory."
Assert-Contains $iss "AssertStagedPayloadHashes();" `
  "Every child-process launch must recheck embedded payload hashes."
Assert-Contains $iss "GetSHA256OfFile(PayloadMsix)" `
  "MSIX compile-time hash must be embedded in the bootstrapper."
Assert-Contains $iss "GetSHA256OfFile(InstallerScript)" `
  "Installer-helper compile-time hash must be embedded in the bootstrapper."
Assert-DoesNotMatch $iss 'Permissions:\s*users-modify' `
  "Elevated Setup must not write logs or payloads into user-writable paths."
Assert-DoesNotMatch $iss 'DestDir:\s*"\{commonappdata\}' `
  "Executable payloads must never stage in public ProgramData."
Assert-DoesNotMatch $iss '\{commonappdata\}' `
  "Elevated Setup and helper processes must never write through ProgramData."
Assert-Contains $iss "{autopf}\Perfect Installer Logs" `
  "Elevated helper logs must stay in an administrator-owned location."

# Correct UAC/original-user split. This is required for standard users who
# supply a different administrator's credentials at the UAC prompt.
Assert-Contains $iss "ExecAsOriginalUser(" `
  "MSIX registration must execute with the initiating user's token."
Assert-Contains $iss "BuildPowerShellParameters('InstallPackage')" `
  "Original-user process must run only the InstallPackage phase."
Assert-Contains $iss "InvokeElevatedPhase('MachineTrust'" `
  "Machine trust must run in elevated Setup context."
Assert-Contains $iss "InvokeElevatedPhase('RemoveTrust'" `
  "Trust rollback must run in elevated Setup context."
Assert-Contains $iss "TrustAddedByThisRun" `
  "Rollback must be gated on trust added by the current run."
Assert-Contains $iss "TrustAddedExitCode = 10" `
  "Machine phase must explicitly distinguish new and existing trust."
Assert-Contains $iss "No existing Perfect package or app data was removed." `
  "Failure UX must state the data-preservation boundary."
Assert-Contains $iss "__PERFECT_ORIGINAL_USER_LOG__" `
  "Original-user logging must resolve inside the original user's environment."
Assert-Contains $installer "if (`$LogPath -ceq `"__PERFECT_ORIGINAL_USER_LOG__`")" `
  "PowerShell must resolve the user log after switching to the original token."

# Public-certificate and package fail-closed validation.
foreach ($required in @(
  'Cert:\LocalMachine\TrustedPeople',
  'Import-Certificate',
  '2.5.29.19',
  'CertificateAuthority',
  '2.5.29.15',
  'DigitalSignature',
  '2.5.29.37',
  '1.3.6.1.5.5.7.3.3',
  'AppxManifest.xml',
  'AppxBlockMap.xml',
  'AppxSignature.p7x',
  'MSIX must expose exactly one launch application.',
  'MSIX must contain exactly one perfect protocol registration.',
  'System.Security.Cryptography.Pkcs.SignedCms',
  'CheckSignature($true)',
  'ExpectedPackageIdentityName',
  'ExpectedPublisher',
  'ExpectedVersion',
  '"ValidatePayload" { 0 }',
  'Get-AppxPackage -Name $ExpectedPackageIdentityName',
  'Add-AppxPackage',
  'Perfect launch executable is absent after package registration.',
  'PackageFamilyName',
  'LocalState'
)) {
  Assert-Contains $installer $required `
    "Installer contract is missing required evidence: $required"
}
Assert-Contains $installer "(-not `$basic.CertificateAuthority)" `
  "BasicConstraints must explicitly require CA=false."
Assert-Contains $installer `
  "Rolled back trust after machine-phase validation failed." `
  "Machine phase must internally rollback a partially successful import."
Assert-Contains $installer "`$beforeVersion -gt `$script:ExpectedPackageVersion" `
  "A newer installed package must never be downgraded."
Assert-Contains $installer "`$beforeVersion -eq `$script:ExpectedPackageVersion" `
  "Same-version reruns must be idempotent."

# These strings would create a dangerous or identity-breaking installer.
Assert-DoesNotMatch $installer 'Cert:\\(?:LocalMachine|CurrentUser)\\Root' `
  "Installer must never read, import, or remove from a Root store."
Assert-DoesNotMatch $installer 'Cert:\\CurrentUser\\TrustedPeople' `
  "Private publisher trust must use machine TrustedPeople only."
Assert-DoesNotMatch $installer '\bRemove-AppxPackage\b' `
  "Upgrade and failure paths must never unregister the existing app."
Assert-DoesNotMatch $installer '\bAdd-AppxProvisionedPackage\b' `
  "Bootstrapper must not provision the app for unrelated users."
Assert-DoesNotMatch $installer '\bForceUpdateFromAnyVersion\b' `
  "Bootstrapper must not opt into downgrade behavior."
Assert-DoesNotMatch $installer '\bAllowUnsigned\b' `
  "Bootstrapper must reject unsigned packages."
Assert-DoesNotMatch $installer 'Get-AppxPackage[^\r\n]*-AllUsers' `
  "Package state must be scoped to the initiating user."
Assert-DoesNotMatch $iss 'runascurrentuser' `
  "Elevated current-user execution would install for UAC credential owner."

# Parser proof catches accidental PowerShell syntax regressions without
# touching certificate stores or app packages.
$parseErrors = $null
$null = [Management.Automation.Language.Parser]::ParseFile(
  $scriptPath,
  [ref]$null,
  [ref]$parseErrors
)
Assert-True ($parseErrors.Count -eq 0) (
  "PowerShell parser reported: " +
  (($parseErrors | ForEach-Object { $_.Message }) -join "; ")
)

# If Inno Setup is installed locally, compile a harmless shell with dummy
# embedded public payloads. The payload is never executed; compilation proves
# preprocessor defines, icon wiring, and output shape.
$isccCandidates = @(
  (Get-Command ISCC.exe -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
  (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 7\ISCC.exe"),
  (Join-Path $env:ProgramFiles "Inno Setup 7\ISCC.exe"),
  (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
  (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
  Select-Object -Unique

if (@($isccCandidates).Count -gt 0) {
  $iscc = @($isccCandidates)[0]
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) (
    "perfect-installer-contract-" + [Guid]::NewGuid().ToString("N")
  )
  $output = Join-Path $tempRoot "output"
  $dummyMsix = Join-Path $tempRoot "dummy.msix"
  $dummyCer = Join-Path $tempRoot "dummy.cer"
  try {
    $null = New-Item -ItemType Directory -Path $output -Force
    [IO.File]::WriteAllBytes($dummyMsix, [byte[]](1, 2, 3))
    [IO.File]::WriteAllBytes($dummyCer, [byte[]](4, 5, 6))
    $iconPath = Join-Path $repositoryRoot "windows\runner\resources\app_icon.ico"
    $arguments = @(
      "/Qp",
      "/DPayloadMsix=$dummyMsix",
      "/DPayloadCertificate=$dummyCer",
      "/DInstallerScript=$scriptPath",
      "/DArtifactVersion=contract-test",
      "/DMsixVersion=1.1.0.1",
      "/DCertificateThumbprint=0123456789ABCDEF0123456789ABCDEF01234567",
      "/DCertificateSubject=CN=K1 Perfect Private",
      "/DPackageIdentityName=com.k1tvkli2003.perfect",
      "/DPackagePublisher=CN=K1 Perfect Private",
      "/DSetupIcon=$iconPath",
      "/DOutputDirectory=$output",
      $issPath
    )
    & $iscc @arguments
    Assert-True ($LASTEXITCODE -eq 0) `
      "ISCC failed to compile the bootstrapper contract shell."
    $compiled = @(Get-ChildItem -LiteralPath $output -Filter "*.exe" -File)
    Assert-True ($compiled.Count -eq 1) `
      "ISCC must emit exactly one user-facing setup EXE."
    $versionInfo = $compiled[0].VersionInfo
    Assert-True ($versionInfo.FileVersion.Trim() -ceq "1.1.0.1") `
      "Compiled Setup must carry the exact four-part MSIX file version."
    Assert-True ($versionInfo.ProductVersion.Trim() -ceq "1.1.0.1") `
      "Compiled Setup must carry the exact four-part MSIX product version."
    Assert-True ($versionInfo.ProductName.Trim() -ceq "Perfect!") `
      "Compiled Setup must carry the Perfect! product identity."
    $stream = [IO.File]::OpenRead($compiled[0].FullName)
    $reader = [IO.BinaryReader]::new($stream)
    try {
      $stream.Position = 0x3c
      $peOffset = $reader.ReadInt32()
      $stream.Position = $peOffset
      $peSignature = $reader.ReadUInt32()
      $machine = $reader.ReadUInt16()
      Assert-True ($peSignature -eq 0x00004550) `
        "Compiled Setup must be a valid PE image."
      Assert-True ($machine -eq 0x8664) `
        "Compiled Setup must be a native x64 executable."
    } finally {
      $reader.Dispose()
      $stream.Dispose()
    }
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
  }
} else {
  Write-Host "ISCC not installed; static/preprocessor contract retained for CI."
}

Write-Host "PASS: Windows installer contract"
