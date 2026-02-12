import 'package:flutter/material.dart';
import 'package:project1_flutter/app/models/socket_models.dart';

class DeviceRow extends StatelessWidget {
  final DeviceInfo device;
  final String targetEmail;
  final VoidCallback? onTap;

  const DeviceRow({
    super.key,
    required this.device,
    required this.targetEmail,
    this.onTap,
  });

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
    final truncatedSocketId = device.socketId.length > 12
        ? '${device.socketId.substring(0, 12)}...'
        : device.socketId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(device.deviceType),
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName.isNotEmpty
                      ? device.deviceName
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
          IconButton(
            icon: Icon(
              Icons.link,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: onTap,
            tooltip: 'Connect',
          ),
        ],
      ),
    );
  }
}
