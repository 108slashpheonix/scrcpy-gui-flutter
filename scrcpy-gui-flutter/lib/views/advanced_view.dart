import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/shared.dart';

class AdvancedView extends StatelessWidget {
  const AdvancedView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 48, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              "Advanced Options Moved",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check the sidebar 'Advanced' dropdown\nfor Shell, Fastboot, and Logs.",
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
