import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:project1_flutter/app/service/app_messanger.dart';
import 'package:uuid/uuid.dart';
import 'package:project1_flutter/app/models/socket_models.dart';
import 'package:project1_flutter/app/service/socket_service.dart';

class SocketHandler {
  final SocketService socket;

  String? currentEmail;
  String? currentToken;
  String? currentDeviceId;
  String? socketId;

  SocketHandler(this.socket);

  StreamSubscription? _sub;
  bool _initialized = false;

  final _registrationController = StreamController<bool>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _devicesController = StreamController<List<OnlineUser>>.broadcast();
  final _connectionRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sdpOfferController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sdpAnswerController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _targetNotFoundController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _userLeftController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get registrationStatus => _registrationController.stream;
  Stream<bool> get connectionStateStatus => _connectionStateController.stream;
  Stream<List<OnlineUser>> get onlineDevices => _devicesController.stream;
  Stream<Map<String, dynamic>> get connectionRequests =>
      _connectionRequestController.stream;
  Stream<Map<String, dynamic>> get sdpOffers => _sdpOfferController.stream;
  Stream<Map<String, dynamic>> get sdpAnswers => _sdpAnswerController.stream;
  Stream<Map<String, dynamic>> get iceCandidates =>
      _iceCandidateController.stream;
  Stream<Map<String, dynamic>> get targetNotFound =>
      _targetNotFoundController.stream;
  Stream<Map<String, dynamic>> get userLeft => _userLeftController.stream;

  final List<OnlineUser> _onlineUsers = [];

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  String _deviceName = 'Unknown';
  String _deviceType = 'desktop';

  Future<void> _initDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        _deviceName = '${info.manufacturer} ${info.model}';
        _deviceType = 'mobile';
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        _deviceName = info.name;
        _deviceType = 'mobile';
      } else if (Platform.isMacOS) {
        _deviceName = 'Mac';
        _deviceType = 'desktop';
      } else if (Platform.isWindows) {
        _deviceName = 'Windows PC';
        _deviceType = 'desktop';
      } else if (Platform.isLinux) {
        _deviceName = 'Linux PC';
        _deviceType = 'desktop';
      } else {
        final info = await _deviceInfoPlugin.webBrowserInfo;
        _deviceName = info.browserName.name;
        _deviceType = 'desktop';
      }
    } catch (_) {
      _deviceName = 'Unknown Device';
      _deviceType = 'desktop';
    }
  }

  void init() {
    if (_initialized) return;
    _initialized = true;
    _sub = socket.messages.listen(_handleMessage);
  }

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

  Future<void> register(String email, String token, String deviceId) async {
    currentEmail = email;
    currentToken = token;
    currentDeviceId = deviceId;

    await _initDeviceInfo();

    final payload = {"device_name": _deviceName, "device_type": _deviceType};
    send("register", payload: payload);
  }

  void confirmConnection() {
    send("connect");
  }

  void checkDevices() {
    send("check");
  }

  void tryConnect(String targetEmail, String targetDevice) {
    final requestId = const Uuid().v4();
    send(
      "try_connect",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"request_id": requestId},
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

  void sendSdpOffer(
    String targetEmail,
    String targetDevice,
    String sdp,
    String type,
  ) {
    send(
      "sdp_offer",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"sdp": sdp, "type": type},
    );
  }

  void sendSdpAnswer(
    String targetEmail,
    String targetDevice,
    String sdp,
    String type,
  ) {
    send(
      "sdp_answer",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {"sdp": sdp, "type": type},
    );
  }

  void sendIceCandidate(
    String targetEmail,
    String targetDevice,
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) {
    send(
      "ice_candidate",
      toEmail: targetEmail,
      toDevice: targetDevice,
      payload: {
        "candidate": candidate,
        "sdpMid": sdpMid,
        "sdpMLineIndex": sdpMLineIndex,
      },
    );
  }

  void disconnect() {
    send("disconnect");
  }

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return;
      }
      final event = data["event"];
      if (event is! String) {
        return;
      }

      switch (event) {
        case "register":
          _handleRegister(data);
          break;
        case "connected":
          _handleConnected(data);
          break;
        case "check":
          _handleCheck(data);
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
        case "target_not_found":
          _handleTargetNotFound(data);
          break;
        case "user_left":
          _handleUserLeft(data);
          break;
        case "error":
          _handleError(data);
          break;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error handling message: $e');
    }
  }

  void _handleRegister(Map<String, dynamic> data) {
    final status = data["status"];
    final bool success = status == "ok" || status == true;

    final sid = data["socket_id"];
    if (sid != null) {
      final socketIdStr = sid.toString();
      if (socketIdStr.isNotEmpty) {
        socketId = socketIdStr;
        socket.setSocketId(socketIdStr);
      }
    }
    _registrationController.add(success);
  }

  void _handleConnected(Map<String, dynamic> data) {
    _connectionStateController.add(data["status"] == "ok");
  }

  void _handleCheck(dynamic data) {
    try {
      final usersList = data['users'];
      if (usersList is List) {
        _onlineUsers.clear();
        for (final item in usersList) {
          try {
            if (item is Map<String, dynamic>) {
              _onlineUsers.add(OnlineUser.fromJson(item));
            }
          } catch (e) {
            print('Error parsing online user: $e');
          }
        }
        _devicesController.add(List.from(_onlineUsers));
      }
    } catch (e) {
      print('Error in _handleCheck: $e');
    }
  }

  void _handleTryConnect(Map<String, dynamic> data) {
    final payload = data["payload"];
    if (payload != null) {
      if (payload.containsKey("request")) {
        _connectionRequestController.add(data);
        AppMessenger.showBanner(message: "REQUESTED MESSAGE FROM $data");
      } else if (payload.containsKey("response")) {
        final accepted = payload["response"] == true;
        // ignore: avoid_print
        print("Connection response: $accepted");
      }
    }
  }

  void _handleTargetNotFound(Map<String, dynamic> data) {
    _targetNotFoundController.add({
      "event": data["event"],
      "error": data["error"],
      "target_email": data["target_email"],
      "target_device": data["target_device"],
    });
  }

  void _handleUserLeft(Map<String, dynamic> data) {
    _userLeftController.add({
      "event": data["event"],
      "email": data["email"],
      "device": data["device"],
    });
  }

  void _handleError(Map<String, dynamic> data) {
    // ignore: avoid_print
    print('Socket error: ${data["error"]}');
  }

  void dispose() {
    _sub?.cancel();
    _registrationController.close();
    _connectionStateController.close();
    _devicesController.close();
    _connectionRequestController.close();
    _sdpOfferController.close();
    _sdpAnswerController.close();
    _iceCandidateController.close();
    _targetNotFoundController.close();
    _userLeftController.close();
  }
}
