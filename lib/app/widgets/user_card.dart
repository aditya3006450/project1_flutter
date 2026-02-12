import 'package:flutter/material.dart';
import 'package:project1_flutter/app/models/socket_models.dart';
import 'package:project1_flutter/app/widgets/device_row.dart';

class UserCard extends StatefulWidget {
  final OnlineUser user;

  const UserCard({super.key, required this.user});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.user.email.isNotEmpty
                    ? widget.user.email[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.user.email,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.user.devices.length} device(s) connected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.user.devices.map(
                    (device) => DeviceRow(
                      device: device,
                      targetEmail: widget.user.email,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
