import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/shared.dart';

class FastbootView extends StatefulWidget {
  const FastbootView({super.key});

  @override
  State<FastbootView> createState() => _FastbootViewState();
}

class _FastbootViewState extends State<FastbootView> {
  List<String> _fastbootDevices = [];
  String? _selectedFastbootDevice;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    setState(() => _scanning = true);
    final appState = context.read<AppState>();
    final devices = await appState.fastbootService.getDevices();
    setState(() {
      _fastbootDevices = devices;
      if (devices.isNotEmpty) {
        _selectedFastbootDevice = devices.first;
      } else {
        _selectedFastbootDevice = null;
      }
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fastboot Controls',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _scanning ? null : _refreshDevices,
                icon: _scanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Fastboot Devices',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Device Selection
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('CONNECTED DEVICES (FASTBOOT)'),
                const SizedBox(height: 12),
                if (_fastbootDevices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        _scanning
                            ? 'Scanning...'
                            : 'No devices in fastboot mode found.\nPut your device in fastboot mode and click refresh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textMuted),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: _fastbootDevices.map((device) {
                        final isSelected = device == _selectedFastbootDevice;
                        return InkWell(
                          onTap: () =>
                              setState(() => _selectedFastbootDevice = device),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.accentPrimary.withValues(alpha: 0.2)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.smartphone_rounded,
                                  color: isSelected
                                      ? theme.accentPrimary
                                      : Colors.white38,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  device,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.textMuted,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.accentPrimary,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('ACTIONS', accent: true),
                const SizedBox(height: 12),
                const Text(
                  'WARNING: Use these commands with caution. Incorrect usage may verify brick your device or cause data loss. Proceed at your own risk.',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: _selectedFastbootDevice == null ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: _selectedFastbootDevice == null,
                    child: Row(
                      children: [
                        Expanded(
                          child: _FastbootButton(
                            label: 'REBOOT SYSTEM',
                            color: const Color(0xFF10B981),
                            onTap: () => _confirmFastbootAction(
                              context,
                              appState,
                              'Reboot System',
                              'Are you sure you want to reboot the device to System?',
                              () => appState.fastbootService.reboot(
                                _selectedFastbootDevice!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FastbootButton(
                            label: 'BOOTLOADER',
                            color: const Color(0xFFF59E0B),
                            onTap: () => _confirmFastbootAction(
                              context,
                              appState,
                              'Reboot to Bootloader',
                              'Are you sure you want to reboot to Bootloader mode?',
                              () => appState.fastbootService.rebootBootloader(
                                _selectedFastbootDevice!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FastbootButton(
                            label: 'RECOVERY',
                            color: const Color(0xFFEF4444),
                            onTap: () => _confirmFastbootAction(
                              context,
                              appState,
                              'Reboot to Recovery',
                              'Are you sure you want to reboot to Recovery mode?',
                              () => appState.fastbootService.rebootRecovery(
                                _selectedFastbootDevice!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmFastbootAction(
    BuildContext context,
    AppState appState,
    String title,
    String message,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('PROCEED'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await action();
      if (mounted) {
        appState.addLog(
          result['message'] ?? 'Action completed',
          result['success'] ? LogType.success : LogType.error,
        );
        // Refresh devices after action (e.g., reboot might remove it)
        _refreshDevices();
      }
    }
  }
}

class _FastbootButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FastbootButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
