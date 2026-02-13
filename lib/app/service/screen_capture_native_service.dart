import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Service to handle native screen capture permission requests
class ScreenCaptureNativeService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.project1_flutter/screen_capture',
  );

  /// Request screen capture permission from Android system
  /// This will show the system dialog asking user to allow screen recording
  static Future<bool> requestScreenCapturePermission() async {
    if (!Platform.isAndroid) {
      return true; // iOS handles this differently
    }

    try {
      print(
        'ScreenCaptureNativeService: Requesting screen capture permission...',
      );
      final bool result = await _channel.invokeMethod('requestScreenCapture');
      print(
        'ScreenCaptureNativeService: Screen capture permission result: $result',
      );
      return result;
    } on PlatformException catch (e) {
      print(
        'ScreenCaptureNativeService: Error requesting permission: ${e.message}',
      );
      return false;
    } catch (e) {
      print('ScreenCaptureNativeService: Unexpected error: $e');
      return false;
    }
  }
}
