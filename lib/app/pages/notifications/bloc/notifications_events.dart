import 'package:project1_flutter/app/models/notification_model.dart';

abstract class NotificationsEvent {}

class LoadNotifications extends NotificationsEvent {}

class RefreshNotifications extends NotificationsEvent {}

class AcceptConnection extends NotificationsEvent {
  final String toEmail;

  AcceptConnection(this.toEmail);
}

class AddLocalNotification extends NotificationsEvent {
  final NotificationModel notification;

  AddLocalNotification(this.notification);
}
