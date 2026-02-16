import 'dart:convert';
import 'dart:io';

class AdbService {
  String? _customPath;
  
  void setCustomPath(String? path) => _customPath = path;
  String? get customPath => _customPath;

  String _getAdbPath() {
    if (_customPath != null && _customPath!.isNotEmpty) {
      final ext = Platform.isWindows ? '.exe' : '';
      final fullPath = '$_customPath${Platform.pathSeparator}adb$ext';
      if (File(fullPath).existsSync()) return fullPath;
    }
    return 'adb';
  }

  Future<List<String>> getDevices() async {
    try {
      final result = await Process.run(_getAdbPath(), ['devices']);
      if (result.exitCode != 0) return [];
      
      final lines = (result.stdout as String).split(RegExp(r'[\r\n]+'));
      return lines
          .skip(1)
          .where((l) => l.contains('\tdevice'))
          .map((l) => l.split('\t')[0].trim())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> connect(String ip) async {
    try {
      final result = await Process.run(_getAdbPath(), ['connect', ip]);
      final output = '${result.stdout}${result.stderr}'.trim();
      
      if (result.exitCode != 0 || output.contains('cannot connect')) {
        return {'success': false, 'message': output};
      }
      return {'success': true, 'message': output};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> pair(String ip, String code) async {
    try {
      final result = await Process.run(_getAdbPath(), ['pair', ip, code]);
      return {'success': true, 'message': (result.stdout as String).trim()};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> shell(String deviceId, String command) async {
    try {
      final args = ['-s', deviceId, 'shell', ...command.split(' ')];
      final result = await Process.run(_getAdbPath(), args);
      return {'success': result.exitCode == 0, 'output': result.stdout};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> installApk(String deviceId, String filePath) async {
    try {
      final result = await Process.run(
        _getAdbPath(), ['-s', deviceId, 'install', filePath],
      );
      if (result.exitCode != 0) {
        return {'success': false, 'message': (result.stderr as String).trim()};
      }
      return {'success': true, 'message': (result.stdout as String).trim()};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> pushFile(String deviceId, String filePath) async {
    try {
      final result = await Process.run(
        _getAdbPath(), ['-s', deviceId, 'push', filePath, '/sdcard/Download/'],
      );
      return {
        'success': result.exitCode == 0,
        'message': result.exitCode == 0 ? 'File pushed to Downloads' : 'Transfer failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> takeScreenshot(String deviceId) async {
    try {
      final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[:\s.]'), '_');
      final picturesDir = Platform.isMacOS
          ? '${Platform.environment['HOME']}/Pictures'
          : '${Platform.environment['USERPROFILE']}\\Pictures';
      final pcPath = '$picturesDir${Platform.pathSeparator}scrcpy_shot_$timestamp.png';

      await Process.run(
        _getAdbPath(), ['-s', deviceId, 'shell', 'screencap', '-p', '/sdcard/screen.png'],
      );
      await Process.run(
        _getAdbPath(), ['-s', deviceId, 'pull', '/sdcard/screen.png', pcPath],
      );
      return {'success': true, 'path': pcPath};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> killAdb() async {
    try {
      await Process.run(_getAdbPath(), ['kill-server']);
      if (Platform.isMacOS || Platform.isLinux) {
        await Process.run('killall', ['adb']);
      } else if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/IM', 'adb.exe', '/T']);
      }
    } catch (_) {}
  }
}
