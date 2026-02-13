import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  bool _hasRequestedPermissions = false;

  /// Request all required permissions for WebRTC
  Future<bool> requestPermissions(BuildContext context) async {
    if (_hasRequestedPermissions) return true;

    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.notification,
      Permission.bluetoothConnect, // For Android 12+ Bluetooth audio
    ];

    final statuses = await permissions.request();

    bool allGranted = true;
    List<String> deniedPermissions = [];

    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
        deniedPermissions.add(_getPermissionName(permission));
      }
    });

    _hasRequestedPermissions = true;

    if (!allGranted && context.mounted) {
      _showPermissionDialog(context, deniedPermissions);
    }

    return allGranted;
  }

  /// Request screen capture permission (for screen sharing)
  /// Note: This will trigger Android's MediaProjection dialog when getDisplayMedia is called
  Future<bool> requestScreenCapturePermission() async {
    // Screen capture permission is handled by the system when getDisplayMedia is called
    // We just need to make sure foreground service permission is granted
    final foregroundService = await Permission.notification.status;
    if (foregroundService.isGranted) {
      return true;
    }
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Check if all required permissions are granted
  Future<bool> checkPermissions() async {
    final camera = await Permission.camera.status;
    final microphone = await Permission.microphone.status;
    final bluetoothConnect = await Permission.bluetoothConnect.status;

    return camera.isGranted && microphone.isGranted && bluetoothConnect.isGranted;
  }

  /// Show a dialog explaining why permissions are needed
  void _showPermissionDialog(BuildContext context, List<String> denied) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text(
          'The following permissions are required for full functionality:\n\n'
          '${denied.join("\n")}\n\n'
          'Camera and microphone are needed for screen sharing and video calls.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Anyway'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.photos:
        return 'Photos/Storage';
      case Permission.bluetoothConnect:
        return 'Bluetooth';
      default:
        return permission.toString();
    }
  }
}
