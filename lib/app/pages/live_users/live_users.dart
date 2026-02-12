import 'package:flutter/material.dart';
import 'package:project1_flutter/app/models/socket_models.dart';
import 'package:project1_flutter/app/service/socket_repository.dart';
import 'package:project1_flutter/app/widgets/user_card.dart';

class LiveUsers extends StatefulWidget {
  const LiveUsers({super.key});

  @override
  State<LiveUsers> createState() => _LiveUsersState();
}

class _LiveUsersState extends State<LiveUsers> {
  final SocketRepository _socketRepo = SocketRepository();
  List<OnlineUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _socketRepo.onlineDevices.listen((users) {
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    });
    _refresh();
  }

  Future<void> _refresh() async {
    _socketRepo.checkOnlineDevices();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading users...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No users online',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GridView.extent(
              padding: const EdgeInsets.only(bottom: 86),
              childAspectRatio: 0.65,
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _users.map((user) => UserCard(user: user)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
