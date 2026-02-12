import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/models/notification_model.dart';
import 'package:project1_flutter/app/pages/notifications/bloc/notifications_bloc.dart';
import 'package:project1_flutter/app/pages/notifications/bloc/notifications_events.dart';
import 'package:project1_flutter/app/pages/notifications/bloc/notifications_state.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<NotificationsBloc>().add(LoadNotifications());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationsBloc>().add(
                        LoadNotifications(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(state.allNotifications, context),
                _buildNotificationList(
                  state.receivedRequests,
                  context,
                  showActions: true,
                ),
                _buildNotificationList(state.sentRequests, context),
              ],
            );
          }

          return const Center(child: Text('No notifications'));
        },
      ),
    );
  }

  Widget _buildNotificationList(
    List<NotificationModel> notifications,
    BuildContext context, {
    bool showActions = false,
  }) {
    if (notifications.isEmpty) {
      return const Center(child: Text('No notifications'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationsBloc>().add(RefreshNotifications());
      },
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification, context, showActions);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    BuildContext context,
    bool showActions,
  ) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.sent:
        iconData = Icons.send;
        iconColor = Colors.blue;
        break;
      case NotificationType.received:
        iconData = Icons.person_add;
        iconColor = Colors.green;
        break;
      case NotificationType.local:
        iconData = Icons.notifications;
        iconColor = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notification.title ?? 'Notification',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message ?? ''),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: showActions && notification.type == NotificationType.received
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      context.read<NotificationsBloc>().add(
                        AcceptConnection(notification.fromEmail),
                      );
                    },
                  ),
                ],
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
