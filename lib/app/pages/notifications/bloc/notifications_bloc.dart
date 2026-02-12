import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/models/connection_request_model.dart';
import 'package:project1_flutter/app/models/notification_model.dart';
import 'package:project1_flutter/app/pages/notifications/bloc/notifications_events.dart';
import 'package:project1_flutter/app/pages/notifications/bloc/notifications_state.dart';
import 'package:project1_flutter/core/repositories/connection_repository.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final ConnectionRepository _connectionRepository;
  List<NotificationModel> _localNotifications = [];

  NotificationsBloc(this._connectionRepository)
    : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<AcceptConnection>(_onAcceptConnection);
    on<AddLocalNotification>(_onAddLocalNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    await _fetchNotifications(emit);
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    await _fetchNotifications(emit);
  }

  Future<void> _fetchNotifications(Emitter<NotificationsState> emit) async {
    try {
      final sentData = await _connectionRepository.getSentRequests();
      final receivedData = await _connectionRepository.getReceivedRequests();

      final sentRequests = sentData
          .map((json) => ConnectionRequestModel.fromJson(json))
          .where((request) => request.isValid)
          .map(
            (request) => NotificationModel.fromConnectionRequest(
              request,
              NotificationType.sent,
            ),
          )
          .toList();

      final receivedRequests = receivedData
          .map((json) => ConnectionRequestModel.fromJson(json))
          .where((request) => request.isValid && !request.isAccepted)
          .map(
            (request) => NotificationModel.fromConnectionRequest(
              request,
              NotificationType.received,
            ),
          )
          .toList();

      emit(
        NotificationsLoaded(
          sentRequests: sentRequests,
          receivedRequests: receivedRequests,
          localNotifications: _localNotifications,
        ),
      );
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onAcceptConnection(
    AcceptConnection event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      emit(AcceptingConnection(event.toEmail));

      try {
        await _connectionRepository.acceptConnection(event.toEmail);

        // Refresh the list after accepting
        await _fetchNotifications(emit);
      } catch (e) {
        emit(NotificationsError('Failed to accept connection: $e'));
        // Re-emit the previous state so UI stays consistent
        emit(currentState);
      }
    }
  }

  void _onAddLocalNotification(
    AddLocalNotification event,
    Emitter<NotificationsState> emit,
  ) {
    _localNotifications.add(event.notification);

    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      emit(
        NotificationsLoaded(
          sentRequests: currentState.sentRequests,
          receivedRequests: currentState.receivedRequests,
          localNotifications: List.from(_localNotifications),
        ),
      );
    }
  }
}
