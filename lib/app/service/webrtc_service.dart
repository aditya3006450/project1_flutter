import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum WebRTCConnectionState { idle, connecting, connected, disconnected, failed }

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;

  final _connectionStateController =
      StreamController<WebRTCConnectionState>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();

  Stream<WebRTCConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<MediaStream?> get remoteStream => _remoteStreamController.stream;
  Stream<RTCIceCandidate> get iceCandidates => _iceCandidateController.stream;

  WebRTCConnectionState _currentState = WebRTCConnectionState.idle;

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  static const Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  WebRTCConnectionState get currentState => _currentState;
  MediaStream? get currentRemoteStream => _remoteStream;

  void _updateConnectionState(WebRTCConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// Initialize peer connection and create SDP offer (called by viewer)
  Future<RTCSessionDescription?> createOffer() async {
    try {
      _updateConnectionState(WebRTCConnectionState.connecting);

      // Create peer connection
      _peerConnection = await createPeerConnection(
        _configuration,
        _constraints,
      );

      // Set up event handlers
      _setupPeerConnectionHandlers();

      // Create data channel (optional, for future use)
      _peerConnection!.createDataChannel('data', RTCDataChannelInit());

      // CRITICAL: Add transceiver to force video/audio m-lines in SDP
      // This ensures the offer includes video and audio media lines
      // even if no local stream is available yet
      try {
        await _peerConnection!.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.RecvOnly,
          ),
        );
        print('WebRTC: Added video transceiver (recv-only)');
      } catch (e) {
        print('WebRTC: Could not add video transceiver: $e');
      }

      try {
        await _peerConnection!.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.RecvOnly,
          ),
        );
        print('WebRTC: Added audio transceiver (recv-only)');
      } catch (e) {
        print('WebRTC: Could not add audio transceiver: $e');
      }

      // Create offer
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      print('WebRTC: Offer SDP:');
      final offerLines = offer.sdp?.split('\n') ?? [];
      for (var line in offerLines) {
        if (line.isNotEmpty) {
          print('WebRTC: $line');
        }
      }

      // Set local description
      await _peerConnection!.setLocalDescription(offer);

      return offer;
    } catch (e) {
      print('WebRTC: Error creating offer: $e');
      _updateConnectionState(WebRTCConnectionState.failed);
      return null;
    }
  }

  void _setupPeerConnectionHandlers() {
    if (_peerConnection == null) return;

    print('WebRTC: Setting up peer connection handlers');

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('WebRTC: Generated ICE candidate');
      _iceCandidateController.add(candidate);
    };

    // Handle remote stream (older API - still important for some cases)
    _peerConnection!.onAddStream = (MediaStream stream) {
      print('WebRTC: onAddStream fired - Remote stream added');
      print('WebRTC: Stream has ${stream.getTracks().length} tracks');
      for (var track in stream.getTracks()) {
        print('WebRTC: onAddStream - Track kind: ${track.kind}, enabled: ${track.enabled}');
      }
      _remoteStream = stream;
      _remoteStreamController.add(stream);
      _updateConnectionState(WebRTCConnectionState.connected);
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('WebRTC: Connection state changed: $state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateConnectionState(WebRTCConnectionState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _updateConnectionState(WebRTCConnectionState.disconnected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _updateConnectionState(WebRTCConnectionState.failed);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _updateConnectionState(WebRTCConnectionState.disconnected);
          break;
        default:
          break;
      }
    };

    // Handle ICE connection state
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('WebRTC: ICE connection state: $state');
    };

    // Handle track events (newer API - unified-plan)
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print('WebRTC: onTrack fired - Track event');
      print('WebRTC: Track kind: ${event.track.kind}');
      print('WebRTC: Track enabled: ${event.track.enabled}');
      print('WebRTC: Number of streams: ${event.streams.length}');
      
      if (event.streams.isNotEmpty) {
        print('WebRTC: Using stream from onTrack');
        _remoteStream = event.streams[0];
        print('WebRTC: Remote stream set from onTrack, has ${_remoteStream!.getTracks().length} tracks');
        for (var track in _remoteStream!.getTracks()) {
          print('WebRTC: onTrack stream track - kind: ${track.kind}, enabled: ${track.enabled}');
        }
        _remoteStreamController.add(_remoteStream);
        _updateConnectionState(WebRTCConnectionState.connected);
      }
    };
  }

  /// Get all pending ICE candidates
  Future<List<RTCIceCandidate>> getPendingIceCandidates() async {
    final candidates = <RTCIceCandidate>[];

    if (_peerConnection == null) return candidates;

    // Note: flutter_webrtc handles ICE gathering automatically
    // We need to listen to onIceCandidate to collect them
    return candidates;
  }

  /// Handle received SDP answer (viewer receives this from sharer)
  Future<void> handleAnswer(String sdp, String type) async {
    try {
      if (_peerConnection == null) {
        print('WebRTC: Peer connection is null when handling answer');
        return;
      }

      print('WebRTC: Received answer SDP:');
      final answerLines = sdp.split('\n');
      for (var line in answerLines) {
        if (line.isNotEmpty) {
          print('WebRTC: $line');
        }
      }

      final answer = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(answer);
      print('WebRTC: Remote description (answer) set successfully');
    } catch (e) {
      print('WebRTC: Error handling answer: $e');
      _updateConnectionState(WebRTCConnectionState.failed);
    }
  }

  /// Handle incoming ICE candidate
  Future<void> addIceCandidate(
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) async {
    try {
      if (_peerConnection == null) {
        print('WebRTC: Peer connection is null when adding ICE candidate');
        return;
      }

      final iceCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
      await _peerConnection!.addCandidate(iceCandidate);
      print('WebRTC: ICE candidate added');
    } catch (e) {
      print('WebRTC: Error adding ICE candidate: $e');
    }
  }

  /// Close the connection
  Future<void> close() async {
    try {
      if (_remoteStream != null) {
        _remoteStream!.getTracks().forEach((track) {
          track.stop();
        });
        await _remoteStream!.dispose();
        _remoteStream = null;
      }

      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }

      _updateConnectionState(WebRTCConnectionState.disconnected);
      print('WebRTC: Connection closed');
    } catch (e) {
      print('WebRTC: Error closing connection: $e');
    }
  }

  void dispose() {
    close();
    _connectionStateController.close();
    _remoteStreamController.close();
    _iceCandidateController.close();
  }
}
