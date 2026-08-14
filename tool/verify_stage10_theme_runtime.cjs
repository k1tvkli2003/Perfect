#!/usr/bin/env node

const assert = require('assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');

function absolute(relativePath) {
  const resolved = path.resolve(projectRoot, relativePath);
  assert.ok(
    resolved === projectRoot || resolved.startsWith(projectRoot + path.sep),
    'Path escaped project root: ' + relativePath,
  );
  return resolved;
}

function read(relativePath) {
  return fs.readFileSync(absolute(relativePath), 'utf8')
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n');
}

function readJson(relativePath) {
  return JSON.parse(read(relativePath));
}

function exists(relativePath) {
  assert.ok(fs.existsSync(absolute(relativePath)), 'Missing ' + relativePath);
}

function sha256(relativePath) {
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(absolute(relativePath)))
    .digest('hex');
}

function walk(relativeDirectory, predicate) {
  const root = absolute(relativeDirectory);
  const output = [];
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const file = path.join(root, entry.name);
    if (entry.isDirectory()) {
      output.push(
        ...walk(path.relative(projectRoot, file).replaceAll('\\', '/'), predicate),
      );
    } else if (!predicate || predicate(file)) {
      output.push(file);
    }
  }
  return output;
}

function relative(file) {
  return path.relative(projectRoot, file).replaceAll('\\', '/');
}

function assertContains(source, fragment, owner) {
  assert.ok(source.includes(fragment), owner + ' is missing: ' + fragment);
}

function verifyDartThemeRuntime() {
  const dartFiles = walk('lib', (file) => file.endsWith('.dart'));
  const violations = [];
  const rawColorPattern =
    /PerfectColors\.|Colors\.(?:white|black)(?:\d{0,2})?\b|\bColor\s*\(\s*0x/;

  for (const file of dartFiles) {
    const filePath = relative(file);
    if (
      filePath === 'lib/presentation/perfect_theme.dart' ||
      filePath.endsWith('.g.dart')
    ) {
      continue;
    }
    const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
    lines.forEach((line, index) => {
      if (rawColorPattern.test(line)) {
        violations.push(filePath + ':' + (index + 1) + ' ' + line.trim());
      }
    });
  }
  assert.deepEqual(
    violations,
    [],
    'Reusable UI bypassed semantic theme roles:\n' + violations.join('\n'),
  );

  const theme = read('lib/presentation/perfect_theme.dart');
  const expectedThemeIds = [
    'theme-light-daylight',
    'theme-dark-graphite-bloom',
    'theme-hc-light-clarity',
    'theme-hc-dark-clarity',
  ];
  const actualThemeIds = [...theme.matchAll(/id:\s*'(theme-[^']+)'/g)]
    .map((match) => match[1]);
  assert.deepEqual(actualThemeIds, expectedThemeIds);
  for (const fragment of [
    'class PerfectSemanticTheme extends ThemeExtension<PerfectSemanticTheme>',
    'abstract final class PerfectContrast',
    'static ThemeData highContrastLight()',
    'static ThemeData highContrastDark()',
    'scrim: semantic.ink.withValues',
    'barrierColor: scheme.scrim',
    'backgroundColor: scheme.inverseSurface',
  ]) {
    assertContains(theme, fragment, 'Perfect theme registry');
  }
  assert.match(
    theme,
    /static const highContrastLight = PerfectSurfaceTheme\([\s\S]*?glassBlur:\s*0,[\s\S]*?glassBlurStrong:\s*0,/,
  );
  assert.match(
    theme,
    /static const highContrastDark = PerfectSurfaceTheme\([\s\S]*?glassBlur:\s*0,[\s\S]*?glassBlurStrong:\s*0,/,
  );

  const main = read('lib/main.dart');
  for (const fragment of [
    'highContrastTheme: PerfectTheme.highContrastLight()',
    'highContrastDarkTheme: PerfectTheme.highContrastDark()',
    'PerfectSystemAppearanceProjection(',
    'final forcedHighContrast = _contrastMode == PerfectContrastMode.high',
  ]) {
    assertContains(main, fragment, 'MaterialApp appearance wiring');
  }

  const preferences = read('lib/app/perfect_preferences.dart');
  assertContains(
    preferences,
    'enum PerfectContrastMode { system, high }',
    'Appearance preferences',
  );
  assertContains(preferences, 'saveContrastMode', 'Appearance preferences');

  const bridge = read('lib/app/perfect_system_appearance.dart');
  for (const fragment of [
    'MethodChannel(',
    "'com.k1tvkli2003.perfect/system_appearance'",
    'PerfectSystemAppearanceSnapshot? _lastSnapshot',
    'if (_lastSnapshot == snapshot) return',
    "'themeId': themeId",
    "'highContrast': highContrast",
    "'canvasArgb': _argb(canvas)",
    "'inkArgb': _argb(ink)",
    "'outlineArgb': _argb(outline)",
  ]) {
    assertContains(bridge, fragment, 'Native appearance projection');
  }

  const motion = read('lib/presentation/perfect_motion.dart');
  assertContains(
    motion,
    'Theme.of(context).colorScheme.scrim',
    'Dialog motion contract',
  );
  assert.ok(!rawColorPattern.test(motion), 'Dialog motion has a raw color');

  const pulse = read('lib/presentation/today_pulse.dart');
  for (const fragment of [
    'PerfectSemanticTheme.of(context)',
    'semantic.highContrast',
    'TodayPulseState.resolving',
    "ValueKey<String>('today-pulse-compact')",
    "ValueKey<String>('today-pulse-wide')",
  ]) {
    assertContains(pulse, fragment, 'Today Pulse appearance wiring');
  }

  const continuityTest = read(
    'test/presentation/perfect_workspace_page_test.dart',
  );
  for (const fragment of [
    'theme and contrast switches preserve page identity, draft, focus, scroll and destination',
    'Keep this private draft',
    "'theme-hc-light-clarity'",
    "'theme-hc-dark-clarity'",
  ]) {
    assertContains(continuityTest, fragment, 'Appearance continuity test');
  }

  return { dartFiles: dartFiles.length, themeIds: actualThemeIds.length };
}

function verifyAndroidAppearance() {
  const provider = read(
    'android/app/src/main/kotlin/com/k1tvkli2003/perfect/PerfectTodayWidgetProvider.kt',
  );
  for (const fragment of [
    'internal data class PerfectNativeAppearance',
    'PerfectNativeAppearance.resolve(context, data)',
    'appearance.widgetSurfaceResource',
    'appearance.markResource',
    'appearance.wordmarkResource',
    'highContrast && dark',
    'perfect_widget_status_completed_hc_dark',
    'perfect_widget_status_pending_hc_light',
    'perfect_widget_status_partial_dark',
  ]) {
    assertContains(provider, fragment, 'Android widget appearance');
  }

  const mainActivity = read(
    'android/app/src/main/kotlin/com/k1tvkli2003/perfect/MainActivity.kt',
  );
  for (const fragment of [
    'com.k1tvkli2003.perfect/system_appearance',
    'perfect_appearance_theme_id',
    'perfect_appearance_high_contrast',
    'setApplicationNightMode',
    'PerfectTodayWidgetProvider.refresh(this)',
  ]) {
    assertContains(mainActivity, fragment, 'Android appearance channel');
  }

  const quickAdd = read(
    'android/app/src/main/kotlin/com/k1tvkli2003/perfect/PerfectWidgetQuickAddActivity.kt',
  );
  for (const fragment of [
    'applyAppearance(PerfectNativeAppearance.resolve',
    'appearance.highContrast',
    'appearance.markResource',
    'appearance.focus',
    'appearance.onPrimary',
  ]) {
    assertContains(quickAdd, fragment, 'Android Quick Add appearance');
  }

  const densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
  const suffixes = ['', '_dark', '_hc_light', '_hc_dark'];
  const states = ['pending', 'completed', 'partial', 'missed'];
  const layouts = ['small', 'tall', 'wide', 'large'];
  let rasters = 0;
  let statusIcons = 0;

  for (const density of densities) {
    for (const suffix of suffixes) {
      exists(
        'android/app/src/main/res/drawable-' +
          density +
          '/perfect_widget_mark' +
          suffix +
          '_raster.png',
      );
      exists(
        'android/app/src/main/res/drawable-' +
          density +
          '/perfect_widget_wordmark' +
          suffix +
          '_raster.png',
      );
      rasters += 2;
    }
  }
  for (const suffix of suffixes) {
    exists(
      'android/app/src/main/res/drawable/perfect_widget_surface' +
        suffix +
        '.xml',
    );
    for (const state of states) {
      exists(
        'android/app/src/main/res/drawable/perfect_widget_status_' +
          state +
          suffix +
          '.xml',
      );
      statusIcons += 1;
    }
  }
  for (const layoutName of layouts) {
    const layout = read(
      'android/app/src/main/res/layout/perfect_today_widget_' +
        layoutName +
        '.xml',
    );
    for (const fragment of [
      'android:id="@+id/widget_root"',
      'android:id="@+id/widget_brand_mark"',
      'android:id="@+id/widget_open_today"',
      'android:id="@+id/widget_quick_add"',
      '<ListView',
    ]) {
      assertContains(layout, fragment, 'Android ' + layoutName + ' widget');
    }
  }
  assert.equal(rasters, 40);
  assert.equal(statusIcons, 16);
  return { layouts: layouts.length, rasters, statusIcons, surfaces: suffixes.length };
}

function verifyWindowsAppearance() {
  const flutterWindow = read('windows/runner/flutter_window.cpp');
  for (const fragment of [
    '#include <variant>',
    'com.k1tvkli2003.perfect/system_appearance',
    'std::get_if<flutter::EncodableMap>',
    'ApplyAppTheme(read_bool("dark", false)',
    'result->Success()',
  ]) {
    assertContains(flutterWindow, fragment, 'Windows appearance channel');
  }

  const win32Window = read('windows/runner/win32_window.cpp');
  for (const fragment of [
    'DWMWA_USE_IMMERSIVE_DARK_MODE',
    'DWMWA_BORDER_COLOR',
    'DWMWA_CAPTION_COLOR',
    'DWMWA_TEXT_COLOR',
    'SPI_GETHIGHCONTRAST',
    'GetSysColor(COLOR_WINDOW)',
    'GetSysColor(COLOR_WINDOWTEXT)',
    'GetSysColor(COLOR_WINDOWFRAME)',
    'void Win32Window::ApplyAppTheme',
  ]) {
    assertContains(win32Window, fragment, 'Windows frame appearance');
  }
  const cmake = read('windows/runner/CMakeLists.txt');
  assertContains(cmake, 'target_link_libraries', 'Windows runner link contract');
  assertContains(cmake, '"dwmapi.lib"', 'Windows runner link contract');
  return { channel: 1, frameRoles: 3 };
}

function verifyAuthoredAssets() {
  const manifests = [
    ['assets/brand/perfect-mark-manifest.json', 40],
    ['assets/brand/perfect-wordmark-manifest.json', 28],
  ];
  let declaredOutputs = 0;
  for (const [manifestPath, expectedCount] of manifests) {
    const manifest = readJson(manifestPath);
    assert.equal(manifest.outputs.length, expectedCount, manifestPath);
    for (const output of manifest.outputs) {
      exists(output.path);
      if (output.hash_basis === 'bytes-v1') {
        assert.equal(sha256(output.path), output.sha256, output.path + ' drift');
      }
      declaredOutputs += 1;
    }
  }

  return { declaredOutputs };
}

function verifyAndroidRuntimeEvidence() {
  const root =
    'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/' +
    'design/01-foundations/stage10-theme/runtime/android/';
  const manifest = readJson(root + 'runtime-manifest.json');
  assert.equal(manifest.package, 'com.k1tvkli2003.perfect.preview');
  assert.equal(manifest.install_contract.previous_version_code, 2061);
  assert.equal(manifest.install_contract.installed_version_code, 2062);
  assert.equal(manifest.install_contract.method, 'adb install -r');
  assert.equal(
    manifest.install_contract.first_install_time_before,
    manifest.install_contract.first_install_time_after,
  );
  assert.equal(manifest.install_contract.result, 'pass');
  assert.equal(manifest.disposable_apk.committed, false);
  assert.equal(manifest.artifacts.length, 13);
  for (const artifact of manifest.artifacts) {
    const artifactPath = root + artifact.file;
    exists(artifactPath);
    assert.equal(
      fs.statSync(absolute(artifactPath)).size,
      artifact.bytes,
      artifact.file + ' byte length drift',
    );
    assert.equal(sha256(artifactPath), artifact.sha256, artifact.file + ' drift');
  }
  const appearanceXml = read(
    root + 'perfect-stage10-android-appearance-clarity-light-build2062.xml',
  );
  for (const fragment of [
    'content-desc="Appearance',
    'content-desc="Light"',
    'content-desc="Dark"',
    'content-desc="System contrast"',
    'content-desc="Clarity"',
    'selected="true"',
  ]) {
    assertContains(appearanceXml, fragment, 'Android appearance runtime');
  }
  return { artifacts: manifest.artifacts.length, installedBuild: 2062 };
}

function main() {
  const dart = verifyDartThemeRuntime();
  const android = verifyAndroidAppearance();
  const windows = verifyWindowsAppearance();
  const assets = verifyAuthoredAssets();
  const runtime = verifyAndroidRuntimeEvidence();
  const summary = [
    'themes=' + dart.themeIds,
    'dartFiles=' + dart.dartFiles,
    'rawColorViolations=0',
    'androidLayouts=' + android.layouts,
    'nativeRasters=' + android.rasters,
    'statusIcons=' + android.statusIcons,
    'widgetSurfaces=' + android.surfaces,
    'windowsChannel=' + windows.channel,
    'assetOutputs=' + assets.declaredOutputs,
    'todayPulseLayouts=2',
    'androidRuntimeArtifacts=' + runtime.artifacts,
    'installedPreviewBuild=' + runtime.installedBuild,
  ].join(' ');
  process.stdout.write('STAGE10_THEME_RUNTIME_VERIFY_PASS ' + summary + '\n');
}

main();
