import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrcpy_gui/services/album_art_service.dart';
import '../providers/app_state.dart';
import '../services/adb_service.dart';

class DeviceControlView extends StatefulWidget {
  const DeviceControlView({super.key});

  @override
  State<DeviceControlView> createState() => _DeviceControlViewState();
}

class _DeviceControlViewState extends State<DeviceControlView> {
  Timer? _pollingTimer;
  Map<String, String> _mediaMetadata = {};
  String? _artworkUrl;
  String? _lastTitle;
  String? _lastArtist;

  final AlbumArtService _albumArtService = AlbumArtService();

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMetadata();
    });
    _fetchMetadata(); // Initial fetch
  }

  Future<void> _fetchMetadata() async {
    final appState = context.read<AppState>();
    final deviceId = appState.selectedDevice;

    if (deviceId == null) return;

    final adbService = AdbService();

    final metadata = await adbService.getMediaSessionInfo(deviceId);
    if (mounted) {
      final title = metadata['title'];
      final artist = metadata['artist'];

      // Only fetch art if track changed
      if (title != _lastTitle || artist != _lastArtist) {
        _lastTitle = title;
        _lastArtist = artist;
        if (title != null && artist != null) {
          _fetchArtwork(title, artist);
        } else {
          setState(() => _artworkUrl = null);
        }
      }

      setState(() {
        _mediaMetadata = metadata;
      });
    }
  }

  Future<void> _fetchArtwork(String title, String artist) async {
    // Reset first to avoid showing old art for new song temporarily if slow
    // But maybe keeping old art is better than flicker?
    // Let's keep old art until new one loads or fails.

    final url = await _albumArtService.fetchArtwork(title, artist);
    if (mounted) {
      if (_lastTitle == title && _lastArtist == artist) {
        setState(() => _artworkUrl = url);
      }
    }
  }

  Future<void> _sendKey(int keycode) async {
    final appState = context.read<AppState>();
    final deviceId = appState.selectedDevice;
    if (deviceId == null) return;

    final adbService = AdbService();
    await adbService.sendKeyEvent(deviceId, keycode);

    if (keycode == 85 || keycode == 87 || keycode == 88) {
      Future.delayed(const Duration(milliseconds: 500), _fetchMetadata);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    if (appState.selectedDevice == null) {
      return Center(
        child: Text(
          'No device connected',
          style: TextStyle(color: theme.textMuted),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Media Control',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connected to: ${appState.getDeviceDisplayName(appState.selectedDevice!)}',
              style: TextStyle(color: theme.textMuted),
            ),
            const SizedBox(height: 32),

            // Media Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Album Art
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.glassBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (_artworkUrl != null)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _artworkUrl != null
                          ? Image.network(
                              _artworkUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => Icon(
                                Icons.music_note_rounded,
                                size: 64,
                                color: theme.textMuted.withOpacity(0.3),
                              ),
                            )
                          : Icon(
                              Icons.music_note_rounded,
                              size: 64,
                              color: theme.accentPrimary.withOpacity(0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metadata
                  Text(
                    _mediaMetadata['title'] ?? 'Not Playing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mediaMetadata['artist'] ??
                        (_mediaMetadata['album'] ?? 'Unknown Artist'),
                    style: TextStyle(fontSize: 14, color: theme.textMuted),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MediaButton(
                        icon: Icons.skip_previous_rounded,
                        onTap: () => _sendKey(88), // KEYCODE_MEDIA_PREVIOUS
                      ),
                      const SizedBox(width: 24),
                      _MediaButton(
                        icon: _mediaMetadata['isPlaying'] == 'true'
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 64,
                        isPrimary: true,
                        onTap: () => _sendKey(85), // KEYCODE_MEDIA_PLAY_PAUSE
                      ),
                      const SizedBox(width: 24),
                      _MediaButton(
                        icon: Icons.skip_next_rounded,
                        onTap: () => _sendKey(87), // KEYCODE_MEDIA_NEXT
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Volume Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _sendKey(25), // KEYCODE_VOLUME_DOWN
                        icon: Icon(
                          Icons.volume_down_rounded,
                          color: theme.textMuted,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Volume',
                          style: TextStyle(color: theme.textMuted),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _sendKey(24), // KEYCODE_VOLUME_UP
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool isPrimary;

  const _MediaButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPrimary ? theme.accentPrimary : theme.glassBg,
            shape: BoxShape.circle,
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: theme.accentPrimary.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : theme.textMain,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
