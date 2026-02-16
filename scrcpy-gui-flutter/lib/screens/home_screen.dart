import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/app_state.dart';
import '../widgets/header.dart';
import '../widgets/device_panel.dart';
import '../widgets/engine_panel.dart';
import '../widgets/session_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Column(
        children: [
          // Custom title bar area
          GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            child: Container(
              height: 32,
              color: theme.bgColor,
              child: Row(
                children: [
                  const SizedBox(width: 78), // space for macOS traffic lights
                  Expanded(
                    child: Center(
                      child: Text(
                        'Scrcpy GUI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 78),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const AppHeader(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left sidebar
                        const SizedBox(
                          width: 280,
                          child: DevicePanel(),
                        ),
                        const SizedBox(width: 20),
                        // Center
                        const Expanded(
                          child: EnginePanel(),
                        ),
                        const SizedBox(width: 20),
                        // Right sidebar
                        const SizedBox(
                          width: 260,
                          child: SessionPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
