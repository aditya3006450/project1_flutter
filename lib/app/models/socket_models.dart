import 'dart:convert';

class DeviceInfo {
  final String socketId;
  final String deviceName;
  final String deviceType;

  DeviceInfo({
    required this.socketId,
    required this.deviceName,
    required this.deviceType,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      socketId: json['socket_id']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? '',
      deviceType: json['device_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'socket_id': socketId,
      'device_name': deviceName,
      'device_type': deviceType,
    };
  }
}

class OnlineUser {
  final String email;
  final List<DeviceInfo> devices;

  OnlineUser({required this.email, required this.devices});

  factory OnlineUser.fromJson(Map<String, dynamic> json) {
    final List<dynamic> devicesList = json['devices'] ?? [];
    return OnlineUser(
      email: json['email']?.toString() ?? '',
      devices: devicesList.map((d) => DeviceInfo.fromJson(d)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'devices': devices.map((d) => d.toJson()).toList()};
  }
}

class SdpMessage {
  final String sdp;
  final String type;

  SdpMessage({required this.sdp, required this.type});

  factory SdpMessage.fromJson(Map<String, dynamic> json) {
    return SdpMessage(
      sdp: json['sdp']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'sdp': sdp, 'type': type};
  }
}

class IceCandidateMessage {
  final String candidate;
  final String sdpMid;
  final int sdpMLineIndex;

  IceCandidateMessage({
    required this.candidate,
    required this.sdpMid,
    required this.sdpMLineIndex,
  });

  factory IceCandidateMessage.fromJson(Map<String, dynamic> json) {
    return IceCandidateMessage(
      candidate: json['candidate']?.toString() ?? '',
      sdpMid: json['sdpMid']?.toString() ?? '',
      sdpMLineIndex: json['sdpMLineIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    };
  }
}

class SocketMessage {
  final String fromEmail;
  final String fromToken;
  final String fromDevice;
  final String toEmail;
  final String toDevice;
  final String event;
  final Map<String, dynamic> payload;

  SocketMessage({
    required this.fromEmail,
    required this.fromToken,
    required this.fromDevice,
    required this.toEmail,
    required this.toDevice,
    required this.event,
    required this.payload,
  });

  factory SocketMessage.fromJson(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw);
    return SocketMessage(
      fromEmail: json['from_email']?.toString() ?? '',
      fromToken: json['from_token']?.toString() ?? '',
      fromDevice: json['from_device']?.toString() ?? '',
      toEmail: json['to_email']?.toString() ?? '',
      toDevice: json['to_device']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_email': fromEmail,
      'from_token': fromToken,
      'from_device': fromDevice,
      'to_email': toEmail,
      'to_device': toDevice,
      'event': event,
      'payload': payload,
    };
  }
}
