import 'dart:async';
import 'dart:convert';
import 'package:project1_flutter/app/service/socket_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:project1_flutter/constants/constants.dart';

enum ConnectionState { disconnected, connecting, connected, reconnecting }

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;

  final _messageController = StreamController<dynamic>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _socketIdController = StreamController<String?>.broadcast();

  Stream<dynamic> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  Stream<String?> get socketIdStream => _socketIdController.stream;

  bool get isConnected =>
      _channel != null && _connectionState == ConnectionState.connected;
  ConnectionState get connectionState => _connectionState;

  String? get socketId => _socketId;

  late final SocketHandler _handler = SocketHandler(this);
  SocketHandler get handler => _handler;

  String? _currentEmail;
  String? _currentToken;
  String? _currentDeviceId;
  String? _socketId;

  ConnectionState _connectionState = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;

  void setCredentials(String email, String token, String deviceId) {
    _currentEmail = email;
    _currentToken = token;
    _currentDeviceId = deviceId;
  }

  void connect() {
    if (_connectionState == ConnectionState.connecting ||
        _connectionState == ConnectionState.connected) {
      return;
    }

    _updateConnectionState(ConnectionState.connecting);
    _channel = WebSocketChannel.connect(Uri.parse(WS_URL));

    _socketSub = _channel!.stream.listen(
      (data) {
        _updateConnectionState(ConnectionState.connected);
        _reconnectAttempts = 0;
        _messageController.add(data);
      },
      onDone: _handleDisconnect,
      onError: (_) => _handleDisconnect(),
    );

    _handler.init();
  }

  void _updateConnectionState(ConnectionState state) {
    _connectionState = state;
    _connectionController.add(state == ConnectionState.connected);
  }

  void _handleDisconnect() {
    _channel = null;
    _socketSub?.cancel();
    _socketSub = null;

    if (_connectionState == ConnectionState.connected) {
      _updateConnectionState(ConnectionState.disconnected);
      _attemptReconnect();
    } else {
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _reconnectTimer?.cancel();
      return;
    }

    _updateConnectionState(ConnectionState.reconnecting);
    _reconnectAttempts++;

    final delay = _initialReconnectDelay * _reconnectAttempts;
    _reconnectTimer = Timer(delay, () {
      if (_currentEmail != null &&
          _currentToken != null &&
          _currentDeviceId != null) {
        connect();
        _handler.register(_currentEmail!, _currentToken!, _currentDeviceId!);
      } else {
        connect();
      }
    });
  }

  void cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = _maxReconnectAttempts;
  }

  void setSocketId(String socketId) {
    _socketId = socketId;
    _socketIdController.add(socketId);
  }

  void send(dynamic data) {
    if (_channel == null) {
      return;
    }
    final encoded = data is String ? data : jsonEncode(data);
    _channel!.sink.add(encoded);
  }

  void disconnect() {
    cancelReconnect();
    _socketSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateConnectionState(ConnectionState.disconnected);
    _reconnectAttempts = 0;
  }

  void dispose() {
    cancelReconnect();
    _messageController.close();
    _connectionController.close();
    _socketIdController.close();
    _handler.dispose();
  }
}
