import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/shared.dart';
import '../widgets/embedded_shell.dart';

class AdbShellView extends StatelessWidget {
  const AdbShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADB Shell',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          if (appState.selectedDevice != null) ...[
            Container(
              height: 500, // Fixed height for the shell in this view
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F11),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              clipBehavior: Clip.antiAlias,
              child: EmbeddedShell(
                key: ValueKey(appState.selectedDevice!),
                deviceId: appState.selectedDevice!,
              ),
            ),
          ] else ...[
            GlassCard(
              child: Text(
                "Please select a device in Dashboard first.",
                style: TextStyle(color: theme.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
