import 'dart:async';
import 'dart:convert';
import 'package:project1_flutter/app/service/socket_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:project1_flutter/constants/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;

  final _messageController = StreamController<dynamic>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<dynamic> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool get isConnected => _channel != null;

  late final SocketHandler _handler = SocketHandler(this);

  SocketHandler get handler => _handler;

  void connect() {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(Uri.parse(WS_URL));

    _socketSub = _channel!.stream.listen(
      (data) {
        _connectionController.add(true);
        _messageController.add(data);
      },
      onDone: _handleDisconnect,
      onError: (_) => _handleDisconnect(),
    );

    _handler.init();
  }

  void send(dynamic data) {
    if (_channel == null) return;
    _channel!.sink.add(data is String ? data : jsonEncode(data));
  }

  void _handleDisconnect() {
    _connectionController.add(false);
    _socketSub?.cancel();
    _channel = null;
  }

  void disconnect() {
    _socketSub?.cancel();
    _channel?.sink.close();
    _handleDisconnect();
  }

  void dispose() {
    _messageController.close();
    _connectionController.close();
    _handler.dispose();
  }
}

