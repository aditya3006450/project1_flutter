import 'package:bloc/bloc.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_events.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_state.dart';
import 'package:project1_flutter/core/repositories/connection_repository.dart';
import 'package:project1_flutter/core/storage/hive_storage.dart';
import 'package:project1_flutter/core/storage/storage_keys.dart';

class ConnectionManagementBloc
    extends Bloc<ConnectionManagementEvents, ConnectionManagementState> {
  final ConnectionRepository repository;

  ConnectionManagementBloc(this.repository)
    : super(ConnectionManagementInitial()) {
    on<LoadConnections>((event, emit) async {
      emit(ConnectionManagementLoading());
      try {
        final connectedTo = await repository.getConnectedTo();
        final connectedFrom = await repository.getConnectedFrom();
        emit(ConnectionManagementLoaded(connectedTo, connectedFrom));
      } catch (e) {
        emit(ConnectionManagementError(e.toString()));
      }
    });

    on<Logout>((event, emit) async {
      await HiveStorage().remove(StorageKeys.authToken);
      emit(LogoutSuccess());
    });
  }
}
