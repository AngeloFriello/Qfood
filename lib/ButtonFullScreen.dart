// lib/ui/widget/window_fullscreen_toggle.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

class WindowFullscreenToggle extends StatefulWidget {
  const WindowFullscreenToggle({super.key});

  @override
  State<WindowFullscreenToggle> createState() => _WindowFullscreenToggleState();
}

class _WindowFullscreenToggleState extends State<WindowFullscreenToggle> {
  bool _isFullscreen = true;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> _toggle(bool value) async {
    if (value) {
      // Entra in fullscreen
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
    } else {
      // Esci dal fullscreen 
      await windowManager.setFullScreen(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      await windowManager.maximize();
      await windowManager.setSkipTaskbar(false);
      await windowManager.focus();
    }
    setState(() => _isFullscreen = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _isFullscreen ? Icons.fullscreen : Icons.fullscreen_exit,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Switch(
          value: _isFullscreen,
          onChanged: _toggle,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}