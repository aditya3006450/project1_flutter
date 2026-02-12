import 'dart:async';
import 'dart:convert';

import 'package:project1_flutter/app/service/socket_service.dart';

class SocketHandler {
  final SocketService socket;

  // Local user credentials - set these after login/registration
  String? currentEmail;
  String? currentToken;
  String? currentDeviceId;

  SocketHandler(this.socket);

  StreamSubscription? _sub;
  bool _initialized = false;

  final _registrationController = StreamController<bool>.broadcast();
  final _devicesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _connectionRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sdpOfferController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sdpAnswerController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams for UI/WebRTC logic to listen to
  Stream<bool> get registrationStatus => _registrationController.stream;
  Stream<List<Map<String, dynamic>>> get onlineDevices =>
      _devicesController.stream;
  Stream<Map<String, dynamic>> get connectionRequests =>
      _connectionRequestController.stream;
  Stream<Map<String, dynamic>> get sdpOffers => _sdpOfferController.stream;
  Stream<Map<String, dynamic>> get sdpAnswers => _sdpAnswerController.stream;
  Stream<Map<String, dynamic>> get iceCandidates =>
      _iceCandidateController.stream;

  final List<Map<String, dynamic>> _onlineDevices = [];

  void init() {
    if (_initialized) return;
    _initialized = true;
    _sub = socket.messages.listen(_handleMessage);
  }

  // --- CORE SEND FUNCTION ---

  void send(
    String event, {
    String? toEmail,
    String? toDevice,
    Map<String, dynamic>? payload,
  }) {
    final message = {
      "from_email": currentEmail ?? "",
      "from_token": currentToken ?? "",
      "from_device": currentDeviceId ?? "",
      "to_email": toEmail ?? "",
      "to_device": toDevice ?? "",
      "event": event,
      "payload": payload ?? {},
    };

    SocketService().send(jsonEncode(message));
  }

  // --- OUTBOUND ACTIONS ---

  void register(String email, String token, String deviceId) {
    currentEmail = email;
    currentToken = token;
    currentDeviceId = deviceId;
    send("register");
  }

  void checkDevices() {
    send("check");
  }

  void tryConnect(String targetEmail, String targetDevice) {
    send(
      "try_connect",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"request": true},
    );
  }

  void respondToConnect(String targetEmail, String targetDevice, bool accept) {
    send(
      "try_connect",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"response": accept},
    );
  }

  void sendSdpOffer(String targetEmail, String targetDevice, dynamic sdp) {
    send(
      "sdp_offer",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"sdp": sdp},
    );
  }

  void sendSdpAnswer(String targetEmail, String targetDevice, dynamic sdp) {
    send(
      "sdp_answer",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"sdp": sdp},
    );
  }

  void sendIceCandidate(
    String targetEmail,
    String targetDevice,
    dynamic candidate,
  ) {
    send(
      "ice_candidate",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"candidate": candidate},
    );
  }

  void disconnect() {
    send("disconnect");
  }

  void _handleMessage(dynamic raw) {
    final data = jsonDecode(raw);
    final event = data["event"];

    switch (event) {
      case "register":
        _handleRegister(data);
        break;
      case "check":
        _getConnectedDevices(data);
        break;
      case "try_connect":
        _handleTryConnect(data);
        break;
      case "sdp_offer":
        _sdpOfferController.add(data);
        break;
      case "sdp_answer":
        _sdpAnswerController.add(data);
        break;
      case "ice_candidate":
        _iceCandidateController.add(data);
        break;
      case "error":
        break;
    }
  }

  void _handleRegister(Map<String, dynamic> data) {
    // The backend seems to return status: ok on success based on your notes
    bool success = data["status"] == "ok" || data["payload"]?["status"] == "ok";
    _registrationController.add(success);
  }

  void _getConnectedDevices(Map<String, dynamic> data) {
    if (data["payload"] != null && data["payload"]["devices"] != null) {
      final List devices = data["payload"]["devices"];
      _onlineDevices.clear();
      _onlineDevices.addAll(devices.cast<Map<String, dynamic>>());
      _devicesController.add(_onlineDevices);
    }
  }

  void _handleTryConnect(Map<String, dynamic> data) {
    final payload = data["payload"];
    if (payload != null && payload.containsKey("request")) {
      // Someone is asking to connect to us
      _connectionRequestController.add(data);
    } else if (payload != null && payload.containsKey("response")) {
      // Someone responded to our connection request
      bool accepted = payload["response"] == true;
      print("Connection response: $accepted");
      // You can trigger WebRTC offer generation here if accepted is true
    }
  }

  void dispose() {
    _sub?.cancel();
    _registrationController.close();
    _devicesController.close();
    _connectionRequestController.close();
    _sdpOfferController.close();
    _sdpAnswerController.close();
    _iceCandidateController.close();
  }
}
