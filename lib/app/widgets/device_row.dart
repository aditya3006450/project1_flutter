import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project1_flutter/app/models/socket_models.dart';
import 'package:project1_flutter/app/service/socket_handler.dart';
import 'package:project1_flutter/app/service/socket_repository.dart';
import 'package:project1_flutter/core/storage/hive_storage.dart';
import 'package:project1_flutter/core/storage/storage_keys.dart';

class DeviceRow extends StatefulWidget {
  final DeviceInfo device;
  final String targetEmail;
  final VoidCallback? onTap;

  const DeviceRow({
    super.key,
    required this.device,
    required this.targetEmail,
    this.onTap,
  });

  @override
  State<DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<DeviceRow> {
  final SocketRepository _socketRepo = SocketRepository();
  bool _isConnecting = false;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _socketRepo.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isConnecting = state == ConnectionStateEnum.connecting;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'mobile':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      default:
        return Icons.computer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final truncatedSocketId = widget.device.socketId.length > 12
        ? '${widget.device.socketId.substring(0, 12)}...'
        : widget.device.socketId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(widget.device.deviceType),
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.deviceName.isNotEmpty
                      ? widget.device.deviceName
                      : 'Unknown Device',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  truncatedSocketId,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (_isConnecting)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.link, size: 20),
              onPressed: () {
                widget.onTap?.call();
                _socketRepo.initiateConnection(
                  widget.targetEmail,
                  widget.device.deviceId,
                );
              },
              tooltip: 'Connect',
            ),
        ],
      ),
    );
  }
}
