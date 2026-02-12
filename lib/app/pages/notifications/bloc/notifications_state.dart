import 'package:project1_flutter/app/models/notification_model.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> sentRequests;
  final List<NotificationModel> receivedRequests;
  final List<NotificationModel> localNotifications;

  NotificationsLoaded({
    required this.sentRequests,
    required this.receivedRequests,
    this.localNotifications = const [],
  });

  List<NotificationModel> get allNotifications => [
    ...localNotifications,
    ...receivedRequests,
    ...sentRequests,
  ];
}

class NotificationsError extends NotificationsState {
  final String message;

  NotificationsError(this.message);
}

class AcceptingConnection extends NotificationsState {
  final String toEmail;

  AcceptingConnection(this.toEmail);
}
