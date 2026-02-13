import 'dart:async';
import 'package:flutter/material.dart';

class AppMessenger {
  static final GlobalKey<ScaffoldMessengerState> _key =
      GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get key => _key;
  static ScaffoldMessengerState? get _state => _key.currentState;

  static Timer? _bannerTimer;

  static void showBanner({
    required String message,
    IconData? icon,
    Color? backgroundColor,
    VoidCallback? onDismiss,
    VoidCallback? onAccept,
    Duration duration = const Duration(seconds: 30),
  }) {
    _bannerTimer?.cancel();

    _state?.showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        leading: icon != null ? Icon(icon) : Icon(Icons.notifications),
        backgroundColor: backgroundColor ?? Colors.blueAccent,
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  _bannerTimer?.cancel();
                  _state?.hideCurrentMaterialBanner();
                  onDismiss?.call();
                },
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  _bannerTimer?.cancel();
                  _state?.hideCurrentMaterialBanner();
                  onAccept?.call();
                },
                child: const Text(
                  'Accept',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    _bannerTimer = Timer(duration, () {
      _state?.hideCurrentMaterialBanner();
      onDismiss?.call();
    });
  }

  static void hideBanner() {
    _bannerTimer?.cancel();
    _state?.hideCurrentMaterialBanner();
  }

  static void clearBanners() {
    _bannerTimer?.cancel();
    _state?.clearMaterialBanners();
  }

  static void showSnackBar(String message) {
    _state?.showSnackBar(SnackBar(content: Text(message)));
  }
}

