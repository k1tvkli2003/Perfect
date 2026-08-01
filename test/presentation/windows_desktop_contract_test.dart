import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows host restores placement and enforces a usable minimum', () {
    final main = File('windows/runner/main.cpp').readAsStringSync();
    final header = File('windows/runner/win32_window.h').readAsStringSync();
    final implementation = File(
      'windows/runner/win32_window.cpp',
    ).readAsStringSync();
    final workspace = File(
      'lib/presentation/perfect_workspace_page.dart',
    ).readAsStringSync();

    expect(main, contains('ReadSavedPlacement'));
    expect(main, contains('SetInitialMaximized'));
    expect(main, contains('L"Perfect!"'));
    expect(header, contains('SetInitialMaximized'));
    expect(implementation, contains('WM_GETMINMAXINFO'));
    final minimumWidth = int.parse(
      RegExp(
        r'kMinimumWindowWidth\s*=\s*(\d+)',
      ).firstMatch(implementation)!.group(1)!,
    );
    final minimumHeight = int.parse(
      RegExp(
        r'kMinimumWindowHeight\s*=\s*(\d+)',
      ).firstMatch(implementation)!.group(1)!,
    );
    expect(minimumWidth, lessThan(640));
    expect(minimumHeight, lessThan(520));
    expect(workspace, contains('constraints.maxWidth < 640'));
    expect(workspace, contains('constraints.maxHeight < 520'));
    expect(implementation, contains('MinimumTrackSizeForWindow(hwnd)'));
    expect(implementation, contains('MonitorFromWindow'));
    expect(implementation, contains('work.right - work.left'));
    expect(implementation, contains('work.bottom - work.top'));
    expect(implementation, contains('minimum_physical_width'));
    expect(implementation, contains('minimum_physical_height'));
    expect(implementation, contains('SavePlacement(hwnd)'));
    expect(implementation, contains('MONITOR_DEFAULTTONULL'));
    expect(implementation, contains('origin.x - static_cast<int>(work.left)'));
    expect(implementation, contains('(saved.left - work.left) / scale_factor'));
  });

  test('Windows manifest advertises only the supported host contract', () {
    final manifest = File(
      'windows/runner/runner.exe.manifest',
    ).readAsStringSync();

    expect(manifest, contains('PerMonitorV2'));
    expect(manifest, contains('{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}'));
    for (final unsupportedId in <String>[
      '{1f676c76-80e1-4239-95bb-83d0f6d0da78}',
      '{4a2f28e3-53b9-4441-ba9c-d69d4a4a6e38}',
      '{35138b9a-5d96-4fbd-8e2d-a2440225f93a}',
    ]) {
      expect(manifest, isNot(contains(unsupportedId)));
    }
  });

  test('Windows notification and package identities remain stable', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final reminderScheduler = File(
      'lib/planner/notifications/planner_reminder_scheduler.dart',
    ).readAsStringSync();

    const identity = 'com.k1tvkli2003.perfect';
    expect(pubspec, contains('identity_name: $identity'));
    expect(pubspec, contains('protocol_activation: perfect'));
    expect(reminderScheduler, contains("appName: 'Perfect!'"));
    expect(reminderScheduler, contains("appUserModelId: '$identity'"));
    expect(
      reminderScheduler,
      contains("guid: '108331c7-e6f0-489c-8b2d-bf974da97210'"),
    );
  });

  test('private CI emits clean portable and self-contained Windows setup', () {
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final contract = File(
      '.github/private-build-contract.yml',
    ).readAsStringSync();
    final installer = File(
      'tool/windows/Install-Perfect.ps1',
    ).readAsStringSync();
    final bootstrap = File(
      'tool/windows/PerfectBootstrap.iss',
    ).readAsStringSync();
    final packageStep = workflow.substring(
      workflow.indexOf('- name: Package signed private MSIX'),
      workflow.indexOf('- name: Preserve signed private Windows installer'),
    );
    final installOverStep = workflow.substring(
      workflow.indexOf('- name: Prove MSIX install-over preserves LocalState'),
    );

    expect(workflow, contains('Complete and package the portable Windows'));
    expect(workflow, contains('Verify Windows installer source contract'));
    expect(workflow, contains('PerfectBootstrap.iss'));
    expect(workflow, contains('ISCC.exe'));
    expect(workflow, contains('innosetup-7.0.2-x64.exe'));
    expect(
      workflow,
      contains(
        '5AD54CA3DEF786F8F4212552E54CC6D8D61329E2D24A1CFEE0571D42C2684FF1',
      ),
    );
    expect(workflow, contains('Official Inno Setup installer signature'));
    expect(workflow, contains('Prove self-contained Setup clean install'));
    expect(workflow, contains('ci-setup-update-marker.json'));
    expect(workflow, contains('Setup proof passed'));
    expect(
      workflow.indexOf('Preserve private Windows build'),
      lessThan(workflow.indexOf('Package signed private MSIX')),
    );
    expect(
      workflow,
      contains(r'Microsoft Visual Studio\Installer\vswhere.exe'),
    );
    expect(workflow, contains('msvcp140.dll'));
    expect(workflow, contains('vcruntime140.dll'));
    expect(workflow, contains('vcruntime140_1.dll'));
    expect(workflow, contains('-Filter "Microsoft.VC*.CRT"'));
    expect(workflow, contains('-Recurse'));
    expect(workflow, contains('v145'));
    expect(workflow, isNot(contains(r'[version]$_.Name')));
    expect(workflow, isNot(contains(r'Cert:\CurrentUser\TrustedPeople')));
    expect(workflow, isNot(contains(r'Cert:\CurrentUser\Root')));
    expect(workflow, isNot(contains('X509Store]::new')));
    expect(workflow, contains('Starting signed MSIX packaging'));
    expect(workflow, contains('Signed MSIX packaging completed'));
    expect(workflow, isNot(contains('certutil.exe')));
    expect(workflow, contains('AppxBlockMap.xml'));
    expect(workflow, contains('xmlenc#sha256'));
    expect(workflow, contains('SignedCms]::new'));
    expect(workflow, contains(r'$signedCms.CheckSignature($true)'));
    expect(workflow, contains('"PKCX"'));
    expect(workflow, contains('The signature is timestamped:\\s+'));
    expect(workflow, contains('Timestamp Verified by:\\s+'));
    expect(workflow, contains('DigiCert'));
    expect(workflow, contains('Number of errors:\\s+1'));
    expect(workflow, contains('private publisher trust remains'));
    expect(workflow, contains(r'$global:LASTEXITCODE = 0'));
    expect(workflow, contains('SHA256SUMS.txt'));
    expect(workflow, contains('Portable release ZIP contains a CI-only'));
    expect(workflow, contains('Perfect-*-Windows-Portable.zip'));
    expect(workflow, contains('-windows-x64-portable-'));
    expect(
      workflow,
      contains("if: needs.prepare.outputs.trusted_build == 'true'"),
    );
    expect(workflow, contains(r'--version $msixVersion'));
    expect(workflow, contains('AppxManifest.xml'));
    expect(workflow, contains('AppxSignature.p7x'));
    expect(workflow, contains('com.k1tvkli2003.perfect'));
    expect(workflow, contains('CN=K1 Perfect Private'));
    expect(packageStep, isNot(contains('Import-Certificate')));
    expect(packageStep, isNot(contains('TrustedPeople')));
    expect(packageStep, isNot(contains(r'Cert:\LocalMachine\Root')));
    expect(packageStep, contains('X509BasicConstraintsExtension'));
    expect(packageStep, contains(r'$basicConstraints.CertificateAuthority'));
    expect(installOverStep, contains('Import-Certificate'));
    expect(
      installOverStep,
      contains(r"Cert:\LocalMachine\TrustedPeople\$expectedThumbprint"),
    );
    expect(installOverStep, contains('X509BasicConstraintsExtension'));
    expect(
      installOverStep,
      contains(r'$basicConstraints.CertificateAuthority'),
    );
    expect(workflow, contains('did not mutate Root'));
    expect(workflow, contains(r'-FilePath $Path'));
    expect(workflow, contains('-WindowStyle Hidden'));
    expect(workflow, contains(r'$process.ExitCode'));
    expect(
      workflow,
      contains('Certificate stores did not return to their exact baseline'),
    );
    expect(workflow, contains('signtool.exe'));
    expect(workflow, contains('PERFECT_WINDOWS_CERT_THUMBPRINT'));
    expect(workflow, contains(r'Perfect-$env:PERFECT_ARTIFACT_VERSION'));
    expect(workflow, contains('Signed Windows checksum coverage'));
    expect(
      workflow,
      contains('043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1'),
    );
    expect(
      workflow,
      contains('1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0'),
    );
    expect(contract, contains('self-contained-msix-bootstrap-exe'));
    expect(contract, contains('portable-runtime-zip'));
    expect(contract, contains('excludes CI-only checksum manifests'));
    expect(bootstrap, contains('ExecAsOriginalUser('));
    expect(bootstrap, contains('PrivilegesRequired=admin'));
    expect(installer, contains(r'Cert:\LocalMachine\TrustedPeople'));
    expect(installer, isNot(contains(r'Cert:\LocalMachine\Root')));
    expect(installer, contains(r'$beforeVersion -gt'));
    expect(installer, contains(r'$beforeVersion -eq'));
    expect(contract, contains('application-local Visual C++ runtime'));
    expect(
      contract,
      contains(
        'pubspec semantic version plus Android epoch and the deterministic '
        'GitHub Actions run number',
      ),
    );
    expect(
      contract,
      contains(
        'Pull requests and manual runs outside main never receive Supabase or '
        'signing',
      ),
    );
  });
}
