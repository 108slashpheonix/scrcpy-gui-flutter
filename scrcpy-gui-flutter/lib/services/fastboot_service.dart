import 'dart:io';

class FastbootService {
  String? _customPath;

  void setCustomPath(String? path) => _customPath = path;
  String? get customPath => _customPath;

  String get fastbootPath => _getFastbootPath();

  String _getFastbootPath() {
    if (_customPath != null && _customPath!.isNotEmpty) {
      final ext = Platform.isWindows ? '.exe' : '';
      // Assuming fastboot is in the same directory as adb if custom path is set for ADB
      // But FastbootService might need its own path setter or share with ADB.
      // For now, let's assume if adb path is customized, fastboot might be there too.
      // Actually, let's just use the strict path if provided, or default to 'fastboot'

      // If the custom path points to a directory (platform-tools), we append fastboot
      if (FileSystemEntity.isDirectorySync(_customPath!)) {
        final fullPath = '$_customPath${Platform.pathSeparator}fastboot$ext';
        if (File(fullPath).existsSync()) return fullPath;
      }
    }

    // Check common paths on macOS/Linux if not in PATH
    if (Platform.isMacOS || Platform.isLinux) {
      const commonPaths = [
        '/opt/homebrew/bin/fastboot',
        '/usr/local/bin/fastboot',
        '/usr/bin/fastboot',
      ];
      for (final path in commonPaths) {
        if (File(path).existsSync()) return path;
      }
    }

    return 'fastboot';
  }

  Future<List<String>> getDevices() async {
    try {
      final result = await Process.run(_getFastbootPath(), ['devices']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split(RegExp(r'[\r\n]+'));
      return lines
          .where((l) => l.contains('fastboot'))
          .map((l) => l.split(RegExp(r'\s+'))[0].trim())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> reboot(String deviceId) async {
    return _runCommand(deviceId, ['reboot']);
  }

  Future<Map<String, dynamic>> rebootBootloader(String deviceId) async {
    return _runCommand(deviceId, ['reboot', 'bootloader']);
  }

  Future<Map<String, dynamic>> rebootRecovery(String deviceId) async {
    return _runCommand(deviceId, ['reboot', 'recovery']);
  }

  // Generic command runner
  Future<Map<String, dynamic>> _runCommand(
    String deviceId,
    List<String> args,
  ) async {
    try {
      final finalArgs = ['-s', deviceId, ...args];
      final result = await Process.run(_getFastbootPath(), finalArgs);

      return {
        'success': result.exitCode == 0,
        'message': result.exitCode == 0
            ? (result.stdout as String).trim().isEmpty
                  ? 'Command executed successfully'
                  : (result.stdout as String).trim()
            : (result.stderr as String).trim(),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
