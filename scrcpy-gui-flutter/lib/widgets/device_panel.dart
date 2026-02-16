import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import 'shared.dart';

class DevicePanel extends StatefulWidget {
  const DevicePanel({super.key});

  @override
  State<DevicePanel> createState() => _DevicePanelState();
}

class _DevicePanelState extends State<DevicePanel> {
  String _activeTab = 'usb';
  final _pairIpCtrl = TextEditingController();
  final _pairCodeCtrl = TextEditingController();
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Devices card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.phone_android, size: 16, color: theme.accentPrimary),
                    const SizedBox(width: 6),
                    Text('DEVICES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.accentPrimary, letterSpacing: -0.5)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await appState.killAdb();
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text('Kill ADB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        setState(() => _refreshing = true);
                        await appState.scanDevices();
                        setState(() => _refreshing = false);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _refreshing ? 1 : 0,
                              duration: const Duration(seconds: 1),
                              child: Icon(Icons.refresh, size: 14, color: theme.accentPrimary),
                            ),
                            const SizedBox(width: 3),
                            Text('Refresh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.accentPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: Color(0xFF27272A), height: 20),
                // Device selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel('Active Device Selection'),
                    GestureDetector(
                      onTap: () => _renameDevice(context),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text('Set Nickname', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFA1A1AA))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StyledDropdown(
                  value: appState.selectedDevice ?? '',
                  items: appState.devices.isEmpty
                      ? [const DropdownMenuItem(value: '', child: Text('No devices detected'))]
                      : appState.devices.map((d) => DropdownMenuItem(value: d, child: Text(appState.getDeviceDisplayName(d), style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => appState.setSelectedDevice(v),
                ),
                const SizedBox(height: 10),
                // Tabs
                Row(
                  children: [
                    _TabBtn(label: 'USB', active: _activeTab == 'usb', onTap: () => setState(() => _activeTab = 'usb'), theme: theme),
                    _TabBtn(label: 'Wireless', active: _activeTab == 'wireless', onTap: () => setState(() => _activeTab = 'wireless'), theme: theme),
                  ],
                ),
                Divider(color: Color(0xFF27272A), height: 1),
                const SizedBox(height: 10),

                if (_activeTab == 'usb') ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: theme.accentPrimary),
                            const SizedBox(width: 4),
                            Text('USB SETUP TIP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.accentPrimary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enable Developer Options and USB Debugging on your phone.',
                          style: TextStyle(fontSize: 10, color: theme.textMuted, fontStyle: FontStyle.italic, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_activeTab == 'wireless') ...[
                  SectionLabel('1. Connection', accent: true),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: StyledTextField(
                          hintText: '192.168.1.x:5555',
                          value: appState.wirelessIp,
                          onChanged: (v) { appState.wirelessIp = v; appState.saveSettings(); },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          SizedBox(
                            height: 14, width: 14,
                            child: Checkbox(
                              value: appState.autoConnect,
                              onChanged: (v) { appState.autoConnect = v ?? false; appState.saveSettings(); },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Auto', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => appState.connectWireless(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF27272A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('CONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (appState.recentIps.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const SectionLabel('History'),
                    const SizedBox(height: 4),
                    ...appState.recentIps.map((ip) => GestureDetector(
                      onTap: () { appState.wirelessIp = ip; appState.saveSettings(); setState(() {}); },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF09090B).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: theme.accentSoft),
                          ),
                          child: Text(ip, style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: const Color(0xFFA1A1AA))),
                        ),
                      ),
                    )),
                  ],
                  const SizedBox(height: 12),
                  Divider(color: Color(0xFF27272A)),
                  const SizedBox(height: 6),
                  SectionLabel('2. Pairing (Android 11+)', accent: true),
                  const SizedBox(height: 6),
                  StyledTextField(hintText: 'IP:Port', onChanged: (v) => _pairIpCtrl.text = v),
                  const SizedBox(height: 6),
                  StyledTextField(hintText: 'Code', onChanged: (v) => _pairCodeCtrl.text = v),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => appState.pairDevice(_pairIpCtrl.text, _pairCodeCtrl.text),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF3F3F46)),
                        foregroundColor: const Color(0xFFA1A1AA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('PAIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Drop zone  
          _DropZone(theme: theme),
        ],
      ),
    );
  }

  void _renameDevice(BuildContext context) {
    final appState = context.read<AppState>();
    final dev = appState.selectedDevice;
    if (dev == null) return;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appState.theme.surfaceColor,
        title: Text('Nickname for $dev', style: TextStyle(color: appState.theme.textMain, fontSize: 14)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: appState.theme.textMain),
          decoration: InputDecoration(hintText: 'Enter nickname', hintStyle: TextStyle(color: appState.theme.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: appState.theme.textMuted))),
          TextButton(
            onPressed: () { appState.renameDevice(dev, controller.text); Navigator.pop(ctx); },
            child: Text('Save', style: TextStyle(color: appState.theme.accentPrimary)),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final dynamic theme;

  const _TabBtn({required this.label, required this.active, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: active ? theme.accentPrimary : Colors.transparent, width: 2)),
            ),
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? theme.accentPrimary : theme.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropZone extends StatefulWidget {
  final dynamic theme;
  const _DropZone({required this.theme});

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) context.read<AppState>().handleFile(path);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _dragging ? theme.accentPrimary : theme.accentSoft,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_download_outlined, size: 28, color: theme.accentPrimary),
              const SizedBox(height: 8),
              Text('QUICK PUSH / INSTALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFE4E4E7), letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(
                'Click to select any file or APK to push to phone',
                style: TextStyle(fontSize: 10, color: theme.textMuted, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
