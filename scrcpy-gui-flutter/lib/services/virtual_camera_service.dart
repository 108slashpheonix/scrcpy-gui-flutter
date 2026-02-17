import 'package:flutter/services.dart';

class VirtualCameraService {
  static const MethodChannel _channel = MethodChannel(
    'com.scrcpy.gui/virtual_camera',
  );

  Future<void> start(String windowTitle) async {
    try {
      await _channel.invokeMethod('start', {'windowTitle': windowTitle});
    } on PlatformException catch (e) {
      throw e.message ?? 'Unknown error starting virtual camera';
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      throw e.message ?? 'Unknown error stopping virtual camera';
    }
  }
}
