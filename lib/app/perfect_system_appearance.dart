import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:perfect/app/perfect_preferences.dart';
import 'package:perfect/presentation/perfect_theme.dart';

typedef PerfectAppearanceInvoker =
    Future<Object?> Function(String method, Map<String, Object?> arguments);

/// Non-blocking projection of the effective Flutter appearance into native
/// Android and Windows surfaces. Native failure never blocks local planner UI.
class PerfectSystemAppearanceBridge {
  PerfectSystemAppearanceBridge({PerfectAppearanceInvoker? invoker})
    : _invoker = invoker ?? _invokePlatform;

  static const MethodChannel _channel = MethodChannel(
    'com.k1tvkli2003.perfect/system_appearance',
  );

  final PerfectAppearanceInvoker _invoker;
  PerfectSystemAppearanceSnapshot? _lastSnapshot;

  static Future<Object?> _invokePlatform(
    String method,
    Map<String, Object?> arguments,
  ) => _channel.invokeMethod<Object?>(method, arguments);

  Future<void> apply(PerfectSystemAppearanceSnapshot snapshot) async {
    if (_lastSnapshot == snapshot) return;
    _lastSnapshot = snapshot;
    try {
      await _invoker('apply', snapshot.toArguments());
    } on MissingPluginException {
      // Tests and unsupported embedding hosts intentionally have no channel.
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Perfect system appearance',
          context: ErrorDescription('while projecting the effective theme'),
        ),
      );
    }
  }
}

@immutable
class PerfectSystemAppearanceSnapshot {
  const PerfectSystemAppearanceSnapshot({
    required this.themeMode,
    required this.dark,
    required this.highContrast,
    required this.themeId,
    required this.canvas,
    required this.ink,
    required this.outline,
  });

  final ThemeMode themeMode;
  final bool dark;
  final bool highContrast;
  final String themeId;
  final Color canvas;
  final Color ink;
  final Color outline;

  Map<String, Object?> toArguments() => <String, Object?>{
    'themeMode': themeMode.name,
    'dark': dark,
    'highContrast': highContrast,
    'themeId': themeId,
    'canvasArgb': _argb(canvas),
    'inkArgb': _argb(ink),
    'outlineArgb': _argb(outline),
  };

  static int _argb(Color color) =>
      ((color.a * 255).round() << 24) |
      ((color.r * 255).round() << 16) |
      ((color.g * 255).round() << 8) |
      (color.b * 255).round();

  @override
  bool operator ==(Object other) =>
      other is PerfectSystemAppearanceSnapshot &&
      other.themeMode == themeMode &&
      other.dark == dark &&
      other.highContrast == highContrast &&
      other.themeId == themeId &&
      other.canvas == canvas &&
      other.ink == ink &&
      other.outline == outline;

  @override
  int get hashCode =>
      Object.hash(themeMode, dark, highContrast, themeId, canvas, ink, outline);
}

class PerfectSystemAppearanceProjection extends StatefulWidget {
  const PerfectSystemAppearanceProjection({
    super.key,
    required this.themeMode,
    required this.contrastMode,
    required this.child,
    this.bridge,
  });

  final ThemeMode themeMode;
  final PerfectContrastMode contrastMode;
  final Widget child;
  final PerfectSystemAppearanceBridge? bridge;

  @override
  State<PerfectSystemAppearanceProjection> createState() =>
      _PerfectSystemAppearanceProjectionState();
}

class _PerfectSystemAppearanceProjectionState
    extends State<PerfectSystemAppearanceProjection> {
  late final PerfectSystemAppearanceBridge _bridge =
      widget.bridge ?? PerfectSystemAppearanceBridge();
  PerfectSystemAppearanceSnapshot? _queued;

  @override
  Widget build(BuildContext context) {
    final semantic = PerfectSemanticTheme.of(context);
    final snapshot = PerfectSystemAppearanceSnapshot(
      themeMode: widget.themeMode,
      dark: semantic.brightness == Brightness.dark,
      highContrast: semantic.highContrast || MediaQuery.highContrastOf(context),
      themeId: semantic.id,
      canvas: semantic.canvas,
      ink: semantic.ink,
      outline: semantic.outline,
    );
    if (_queued != snapshot) {
      _queued = snapshot;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _queued != snapshot) return;
        unawaited(_bridge.apply(snapshot));
      });
    }
    return widget.child;
  }
}
