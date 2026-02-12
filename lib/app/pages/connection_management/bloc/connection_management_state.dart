abstract class ConnectionManagementState {}

class ConnectionManagementInitial extends ConnectionManagementState {}

class ConnectionManagementLoading extends ConnectionManagementState {}

class ConnectionManagementLoaded extends ConnectionManagementState {
  final List<Map<String, dynamic>> connectedTo;
  final List<Map<String, dynamic>> connectedFrom;

  ConnectionManagementLoaded(this.connectedTo, this.connectedFrom);
}

class ConnectionManagementError extends ConnectionManagementState {
  final String message;

  ConnectionManagementError(this.message);
}

class LogoutSuccess extends ConnectionManagementState {}
