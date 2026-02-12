import 'package:project1_flutter/app/models/socket_models.dart';
import 'package:project1_flutter/app/service/socket_handler.dart';
import 'package:project1_flutter/app/service/socket_service.dart';

class SocketRepository {
  final SocketHandler _handler;
  final SocketService _service;

  SocketRepository({SocketHandler? handler, SocketService? service})
    : _handler = handler ?? SocketService().handler,
      _service = service ?? SocketService();

  Stream<bool> get registrationStatus => _handler.registrationStatus;
  Stream<bool> get connectionStatus => _handler.connectionStateStatus;
  Stream<List<OnlineUser>> get onlineDevices => _handler.onlineDevices;
  Stream<Map<String, dynamic>> get connectionRequests =>
      _handler.connectionRequests;
  Stream<Map<String, dynamic>> get sdpOffers => _handler.sdpOffers;
  Stream<Map<String, dynamic>> get sdpAnswers => _handler.sdpAnswers;
  Stream<Map<String, dynamic>> get iceCandidates => _handler.iceCandidates;
  Stream<Map<String, dynamic>> get targetNotFound => _handler.targetNotFound;
  Stream<Map<String, dynamic>> get userLeft => _handler.userLeft;
  Stream<bool> get connectionState => _service.connectionStatus;
  Stream<String?> get socketId => _service.socketIdStream;

  bool get isConnected => _service.isConnected;

  void connect() {
    _service.connect();
  }

  void disconnect() {
    _handler.disconnect();
    _service.disconnect();
  }

  void register(String email, String token, String deviceId) {
    _service.setCredentials(email, token, deviceId);
    _handler.register(email, token, deviceId);
  }

  void confirmConnection() {
    _handler.confirmConnection();
  }

  void checkOnlineDevices() {
    _handler.checkDevices();
  }

  void initiateConnection(String targetEmail, String targetDevice) {
    _handler.tryConnect(targetEmail, targetDevice);
  }

  void respondToConnection(
    String targetEmail,
    String targetDevice,
    bool accept,
  ) {
    _handler.respondToConnect(targetEmail, targetDevice, accept);
  }

  void sendSdpOffer(
    String targetEmail,
    String targetDevice,
    String sdp,
    String type,
  ) {
    _handler.sendSdpOffer(targetEmail, targetDevice, sdp, type);
  }

  void sendSdpAnswer(
    String targetEmail,
    String targetDevice,
    String sdp,
    String type,
  ) {
    _handler.sendSdpAnswer(targetEmail, targetDevice, sdp, type);
  }

  void sendIceCandidate(
    String targetEmail,
    String targetDevice,
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) {
    _handler.sendIceCandidate(
      targetEmail,
      targetDevice,
      candidate,
      sdpMid,
      sdpMLineIndex,
    );
  }

  void cancelReconnect() {
    _service.cancelReconnect();
  }

  void dispose() {
    _handler.dispose();
    _service.dispose();
  }
}
