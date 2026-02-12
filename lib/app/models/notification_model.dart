import 'package:project1_flutter/app/models/connection_request_model.dart';

enum NotificationType { sent, received, local }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String fromEmail;
  final String toEmail;
  final bool isAccepted;
  final DateTime createdAt;
  final String? title;
  final String? message;

  NotificationModel({
    required this.id,
    required this.type,
    required this.fromEmail,
    required this.toEmail,
    required this.isAccepted,
    required this.createdAt,
    this.title,
    this.message,
  });

  factory NotificationModel.fromConnectionRequest(
    ConnectionRequestModel request,
    NotificationType type,
  ) {
    return NotificationModel(
      id: '${request.fromEmail}_${request.toEmail}',
      type: type,
      fromEmail: request.fromEmail,
      toEmail: request.toEmail,
      isAccepted: request.isAccepted,
      createdAt: DateTime.now(),
      title: type == NotificationType.sent
          ? 'Connection Request Sent'
          : 'Connection Request Received',
      message: type == NotificationType.sent
          ? 'You sent a connection request to ${request.toEmail}'
          : '${request.fromEmail} wants to connect with you',
    );
  }

  factory NotificationModel.local({
    required String id,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id,
      type: NotificationType.local,
      fromEmail: '',
      toEmail: '',
      isAccepted: false,
      createdAt: DateTime.now(),
      title: title,
      message: message,
    );
  }
}
