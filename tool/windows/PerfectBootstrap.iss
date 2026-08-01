; Perfect! private single-file Windows bootstrap installer.
; All compile-time inputs below are public release metadata or public payloads.

#ifndef PayloadMsix
  #error PayloadMsix define is required
#endif
#ifndef PayloadCertificate
  #error PayloadCertificate define is required
#endif
#ifndef InstallerScript
  #error InstallerScript define is required
#endif
#ifndef ArtifactVersion
  #error ArtifactVersion define is required
#endif
#ifndef MsixVersion
  #error MsixVersion define is required
#endif
#ifndef CertificateThumbprint
  #error CertificateThumbprint define is required
#endif
#ifndef CertificateSubject
  #error CertificateSubject define is required
#endif
#ifndef PackageIdentityName
  #error PackageIdentityName define is required
#endif
#ifndef PackagePublisher
  #error PackagePublisher define is required
#endif
#ifndef SetupIcon
  #error SetupIcon define is required
#endif
#ifndef OutputDirectory
  #error OutputDirectory define is required
#endif

#define EmbeddedMsixName "Perfect.msix"
#define EmbeddedCertificateName "Perfect-private.cer"
#define EmbeddedScriptName "Install-Perfect.ps1"
#define SetupFileName "Perfect-" + ArtifactVersion + "-Windows-Setup"
#define EmbeddedMsixSha256 GetSHA256OfFile(PayloadMsix)
#define EmbeddedCertificateSha256 GetSHA256OfFile(PayloadCertificate)
#define EmbeddedScriptSha256 GetSHA256OfFile(InstallerScript)

[Setup]
AppId={{0BBAF68D-CC30-49FE-BB98-66C813BE6F02}
AppName=Perfect!
AppVersion={#ArtifactVersion}
AppVerName=Perfect! {#ArtifactVersion}
AppPublisher=K1
VersionInfoVersion={#MsixVersion}
VersionInfoCompany=K1
VersionInfoDescription=Perfect! private Windows installer
VersionInfoProductName=Perfect!
VersionInfoProductVersion={#MsixVersion}
DefaultDirName={autopf}\Perfect
CreateAppDir=no
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
DisableWelcomePage=no
OutputDir={#OutputDirectory}
OutputBaseFilename={#SetupFileName}
SetupIconFile={#SetupIcon}
Uninstallable=no
CreateUninstallRegKey=no
PrivilegesRequired=admin
SetupArchitecture=x64
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
WizardResizable=no
SetupLogging=yes
SetupMutex=Global\PerfectBootstrap-0BBAF68D-CC30-49FE-BB98-66C813BE6F02
CloseApplications=no
RestartApplications=no
UsePreviousAppDir=no
RedirectionGuard=yes

[Dirs]
; Elevated helper logs also stay below Program Files. RedirectionGuard applies
; only to Setup itself, not child PowerShell processes, so an elevated child
; must never write through a path a standard user can pre-create or redirect.
Name: "{autopf}\Perfect Installer Logs"
; The payload stage lives below Program Files, whose inherited ACL permits
; standard users to read/execute but not replace files. The unique child name
; comes from Inno's per-run temporary directory and RedirectionGuard remains on.
Name: "{code:GetStagingDirectory}"; Flags: deleteafterinstall

[Files]
Source: "{#PayloadMsix}"; DestDir: "{code:GetStagingDirectory}"; DestName: "{#EmbeddedMsixName}"; Flags: deleteafterinstall ignoreversion overwritereadonly noencryption notimestamp
Source: "{#PayloadCertificate}"; DestDir: "{code:GetStagingDirectory}"; DestName: "{#EmbeddedCertificateName}"; Flags: deleteafterinstall ignoreversion overwritereadonly noencryption notimestamp
Source: "{#InstallerScript}"; DestDir: "{code:GetStagingDirectory}"; DestName: "{#EmbeddedScriptName}"; Flags: deleteafterinstall ignoreversion overwritereadonly noencryption notimestamp

[Code]
const
  TrustAddedExitCode = 10;

var
  TrustAddedByThisRun: Boolean;
  InstallPhaseStarted: Boolean;
  PerRunStagingDirectory: String;

function QuotePowerShellArgument(const Value: String): String;
begin
  if Pos('"', Value) > 0 then
    RaiseException('An installer argument contains an unsupported quote.');
  Result := '"' + Value + '"';
end;

function PowerShellPath(): String;
begin
  Result := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
end;

function InstallerLogPath(): String;
begin
  Result := ExpandConstant(
    '{autopf}\Perfect Installer Logs\Perfect-setup-{#ArtifactVersion}.log'
  );
end;

function GetStagingDirectory(Param: String): String;
begin
  if PerRunStagingDirectory = '' then
    PerRunStagingDirectory :=
      ExpandConstant('{autopf}\Perfect Installer Staging\') +
      ExtractFileName(ExpandConstant('{tmp}'));
  Result := PerRunStagingDirectory;
end;

procedure AssertStagedPayloadHashes();
var
  Stage: String;
begin
  Stage := GetStagingDirectory('');
  if CompareText(
    GetSHA256OfFile(Stage + '\{#EmbeddedMsixName}'),
    '{#EmbeddedMsixSha256}'
  ) <> 0 then
    RaiseException('The staged MSIX changed after Setup extraction.');
  if CompareText(
    GetSHA256OfFile(Stage + '\{#EmbeddedCertificateName}'),
    '{#EmbeddedCertificateSha256}'
  ) <> 0 then
    RaiseException('The staged certificate changed after Setup extraction.');
  if CompareText(
    GetSHA256OfFile(Stage + '\{#EmbeddedScriptName}'),
    '{#EmbeddedScriptSha256}'
  ) <> 0 then
    RaiseException('The staged installer helper changed after Setup extraction.');
end;

function UserLogDisplayPath(): String;
begin
  Result :=
    '%LOCALAPPDATA%\Perfect\InstallerLogs\Perfect-setup-' +
    '{#MsixVersion}-user.log';
end;

function BuildPowerShellParameters(const PhaseName: String): String;
var
  PhaseLogPath: String;
begin
  if PhaseName = 'InstallPackage' then
    PhaseLogPath := '__PERFECT_ORIGINAL_USER_LOG__'
  else
    PhaseLogPath := InstallerLogPath();
  Result :=
    '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' +
    QuotePowerShellArgument(
      GetStagingDirectory('') + '\{#EmbeddedScriptName}'
    ) +
    ' -Phase ' + QuotePowerShellArgument(PhaseName) +
    ' -MsixPath ' +
      QuotePowerShellArgument(
        GetStagingDirectory('') + '\{#EmbeddedMsixName}'
      ) +
    ' -CertificatePath ' +
      QuotePowerShellArgument(
        GetStagingDirectory('') + '\{#EmbeddedCertificateName}'
      ) +
    ' -ExpectedThumbprint ' +
      QuotePowerShellArgument('{#CertificateThumbprint}') +
    ' -ExpectedSubject ' + QuotePowerShellArgument('{#CertificateSubject}') +
    ' -ExpectedPackageIdentityName ' +
      QuotePowerShellArgument('{#PackageIdentityName}') +
    ' -ExpectedPublisher ' + QuotePowerShellArgument('{#PackagePublisher}') +
    ' -ExpectedVersion ' + QuotePowerShellArgument('{#MsixVersion}') +
    ' -LogPath ' + QuotePowerShellArgument(PhaseLogPath);
end;

function InvokeElevatedPhase(
  const PhaseName: String;
  var ResultCode: Integer
): Boolean;
begin
  AssertStagedPayloadHashes();
  Result := Exec(
    PowerShellPath(),
    BuildPowerShellParameters(PhaseName),
    GetStagingDirectory(''),
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
end;

function InvokeOriginalUserInstall(var ResultCode: Integer): Boolean;
begin
  AssertStagedPayloadHashes();
  Result := ExecAsOriginalUser(
    PowerShellPath(),
    BuildPowerShellParameters('InstallPackage'),
    GetStagingDirectory(''),
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
end;

function RollBackTrustIfNeeded(): String;
var
  RollbackCode: Integer;
begin
  Result := '';
  if not TrustAddedByThisRun then
    Exit;

  if not InvokeElevatedPhase('RemoveTrust', RollbackCode) then
  begin
    Result := ' Setup could not start trust rollback.';
    Exit;
  end;
  if RollbackCode <> 0 then
    Result :=
      ' Trust rollback failed with exit code ' + IntToStr(RollbackCode) +
      '; see ' + InstallerLogPath() + '.'
  else
    TrustAddedByThisRun := False;
end;

procedure FailInstallation(const MessageText: String);
var
  RollbackResult: String;
  FullMessage: String;
begin
  RollbackResult := RollBackTrustIfNeeded();
  FullMessage :=
    MessageText + RollbackResult + #13#10 + #13#10 +
    'No existing Perfect package or app data was removed.' + #13#10 +
    'Machine log: ' + InstallerLogPath() + #13#10 +
    'User log: ' + UserLogDisplayPath();
  SuppressibleMsgBox(FullMessage, mbError, MB_OK, IDOK);
  RaiseException(FullMessage);
end;

procedure InitializeWizard();
begin
  WizardForm.WelcomeLabel1.Caption := 'Install or update Perfect!';
  WizardForm.WelcomeLabel2.Caption :=
    'Setup validates the signed Perfect package, adds only its public ' +
    'certificate to Local Machine Trusted People, and installs the MSIX ' +
    'for the Windows user who started Setup.';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  InstallProcessStarted: Boolean;
begin
  if (CurStep <> ssPostInstall) or InstallPhaseStarted then
    Exit;
  InstallPhaseStarted := True;

  WizardForm.StatusLabel.Caption :=
    'Validating the signed package and configuring private publisher trust...';
  if not InvokeElevatedPhase('MachineTrust', ResultCode) then
    FailInstallation('Setup could not start the machine-trust validator.');
  if (ResultCode <> 0) and (ResultCode <> TrustAddedExitCode) then
    FailInstallation(
      'Package or certificate validation failed with exit code ' +
      IntToStr(ResultCode) + '.'
    );
  TrustAddedByThisRun := ResultCode = TrustAddedExitCode;

  WizardForm.StatusLabel.Caption :=
    'Installing Perfect! for the Windows user who started Setup...';
  try
    InstallProcessStarted := InvokeOriginalUserInstall(ResultCode);
  except
    FailInstallation(
      'Windows could not create the original-user installation process.'
    );
  end;
  if not InstallProcessStarted then
    FailInstallation(
      'Setup could not start package registration as the original user.'
    );
  if ResultCode <> 0 then
    FailInstallation(
      'Perfect package installation failed with exit code ' +
      IntToStr(ResultCode) + '.'
    );

  WizardForm.StatusLabel.Caption := 'Perfect! is ready.';
end;
