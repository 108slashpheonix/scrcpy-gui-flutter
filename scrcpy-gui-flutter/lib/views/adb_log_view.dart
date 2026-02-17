import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/shared.dart';

class AdbLogView extends StatelessWidget {
  const AdbLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADB Logs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Terminal Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.terminal_rounded,
                          size: 14,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LOG OUTPUT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        _TerminalAction(
                          icon: Icons.content_copy_rounded,
                          onTap: () {
                            final logs = appState.logs
                                .map((l) => l.message)
                                .join('\n');
                            Clipboard.setData(ClipboardData(text: logs));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logs copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                width: 280,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _TerminalAction(
                          icon: Icons.delete_outline_rounded,
                          onTap: () => appState.clearLogs(),
                        ),
                      ],
                    ),
                  ),
                  // Terminal Content
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: ListView.builder(
                        reverse: true,
                        itemCount: appState.logs.length,
                        itemBuilder: (context, index) {
                          final log = appState.logs.reversed.toList()[index];
                          final timeStr =
                              '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '[$timeStr] ',
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: TextStyle(
                                      color: _getLogColor(log.type),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.error:
        return const Color(0xFFF87171);
      case LogType.success:
        return const Color(0xFF10B981);
      case LogType.warning:
        return const Color(0xFFFBBF24);
      default:
        return Colors.white70;
    }
  }
}

class _TerminalAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TerminalAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: Colors.white60),
        ),
      ),
    );
  }
}
