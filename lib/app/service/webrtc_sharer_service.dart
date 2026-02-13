import 'dart:async';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'screen_capture_native_service.dart';

/// Service for the SHARER side (receives offers, sends answers, shares screen)
class WebRTCSharerService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCRtpTransceiver? _videoTransceiver;
  RTCRtpTransceiver? _audioTransceiver;
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _isSettingUp = false;

  final _connectionStateController = StreamController<bool>.broadcast();
  final _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();
  final _localStreamController = StreamController<MediaStream?>.broadcast();
  final _screenShareStateController = StreamController<bool>.broadcast();

  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<RTCIceCandidate> get iceCandidates => _iceCandidateController.stream;
  Stream<MediaStream?> get localStream => _localStreamController.stream;
  Stream<bool> get screenShareState => _screenShareStateController.stream;

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Handle incoming SDP offer and create answer
  Future<RTCSessionDescription?> handleOffer(
    String sdp,
    String type, {
    bool enableScreenShare = false,
  }) async {
    try {
      print('WebRTCSharer: Handling offer');
      _isSettingUp = true;

      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration, {});

      // Set up handlers
      _setupPeerConnectionHandlers();

      // Set remote description (the offer) FIRST
      final offer = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(offer);
      print('WebRTCSharer: Remote description (offer) set');
      print('WebRTCSharer: Offer SDP: ${offer.sdp}');

      // Check if offer has video m-line
      final hasVideoInOffer = offer.sdp?.contains('m=video') ?? false;
      print('WebRTCSharer: Offer has video m-line: $hasVideoInOffer');

      // Start screen sharing only if requested and supported
      if (enableScreenShare) {
        print('WebRTCSharer: Starting screen share...');
        await startScreenShare();
        print('WebRTCSharer: Screen share started');
        final senders = await _peerConnection!.getSenders();
        print('WebRTCSharer: Peer connection senders: ${senders.length}');
        for (int i = 0; i < senders.length; i++) {
          print('WebRTCSharer: Sender $i - kind: ${senders[i].track?.kind}, enabled: ${senders[i].track?.enabled}');
        }
        
        // Also check transceivers
        final transceivers = await _peerConnection!.getTransceivers();
        print('WebRTCSharer: Peer connection transceivers: ${transceivers.length}');
        for (int i = 0; i < transceivers.length; i++) {
          final t = transceivers[i];
          print('WebRTCSharer: Transceiver $i - mid: ${t.mid}, sender track kind: ${t.sender.track?.kind}');
        }
      } else {
        print('WebRTCSharer: Screen sharing disabled (data channel only mode)');
      }

      // Create answer with explicit audio/video configuration
      // For video to be included in answer, we must tell it to receive
      final answerConstraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      };
      
      print('WebRTCSharer: Creating answer with constraints: $answerConstraints');
      final answer = await _peerConnection!.createAnswer(answerConstraints);
      
      print('WebRTCSharer: ========== FULL ANSWER SDP START ==========');
      print(answer.sdp ?? 'NULL SDP');
      print('WebRTCSharer: ========== FULL ANSWER SDP END ==========');
      
      await _peerConnection!.setLocalDescription(answer);
      print('WebRTCSharer: Answer created and set as local description');

      // Process any pending ICE candidates
      _isSettingUp = false;
      _processPendingIceCandidates();

      _connectionStateController.add(true);
      return answer;
    } catch (e) {
      print('WebRTCSharer: Error handling offer: $e');
      _isSettingUp = false;
      return null;
    }
  }

  /// Process any ICE candidates that arrived before peer connection was ready
  void _processPendingIceCandidates() {
    if (_peerConnection == null || _pendingIceCandidates.isEmpty) return;

    print(
      'WebRTCSharer: Processing ${_pendingIceCandidates.length} pending ICE candidates',
    );
    for (final candidate in _pendingIceCandidates) {
      try {
        _peerConnection!.addCandidate(candidate);
        print('WebRTCSharer: Added pending ICE candidate');
      } catch (e) {
        print('WebRTCSharer: Error adding pending ICE candidate: $e');
      }
    }
    _pendingIceCandidates.clear();
  }

  /// Start screen sharing
  Future<void> startScreenShare() async {
    try {
      if (_peerConnection == null) {
        print(
          'WebRTCSharer: Cannot start screen share - peer connection is null',
        );
        return;
      }

      print('WebRTCSharer: Starting screen capture...');

      // Check if running on desktop (Linux, macOS, Windows)
      final isDesktop = !Platform.isAndroid && !Platform.isIOS;

      if (isDesktop) {
        // For desktop, use getDisplayMedia with proper constraints
        print('WebRTCSharer: Using desktop screen capture...');
        await _startDesktopScreenShare();
      } else {
        // For mobile, request screen capture permission through native channel
        print('WebRTCSharer: Requesting screen capture permission...');
        final permissionGranted =
            await ScreenCaptureNativeService.requestScreenCapturePermission();

        if (!permissionGranted) {
          print('WebRTCSharer: Screen capture permission denied by user');
          print('WebRTCSharer: Falling back to camera...');
          await _startCameraFallback();
          return;
        }

        print(
          'WebRTCSharer: Screen capture permission granted, starting capture...',
        );
        await _startMobileScreenShare();
      }
    } catch (e) {
      print('WebRTCSharer: Error starting screen share: $e');
      _screenShareStateController.add(false);
    }
  }

  /// Start screen sharing on desktop (Linux, macOS, Windows)
  Future<void> _startDesktopScreenShare() async {
    try {
      print('WebRTCSharer: Requesting display media for desktop...');

      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': '1280',
            'minHeight': '720',
            'minFrameRate': '15',
          },
          'optional': [
            {'maxWidth': '1920'},
            {'maxHeight': '1080'},
            {'maxFrameRate': '30'},
          ],
        },
      };

      try {
        print('WebRTCSharer: Calling getDisplayMedia with timeout of 30 seconds...');
        print('WebRTCSharer: A system dialog should appear - please select a screen/window to share');

        // Add timeout to catch stuck calls
        _localStream = await navigator.mediaDevices
            .getDisplayMedia(mediaConstraints)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () async {
                print('WebRTCSharer: getDisplayMedia timed out after 30 seconds');
                throw TimeoutException(
                  'getDisplayMedia timed out - user may have cancelled the dialog',
                );
              },
            );

        if (_localStream == null || _localStream!.getTracks().isEmpty) {
          print('WebRTCSharer: getDisplayMedia returned empty stream');
          throw Exception('No tracks in display media stream');
        }

        print('WebRTCSharer: Screen capture started successfully');
        print(
          'WebRTCSharer: Stream has ${_localStream!.getTracks().length} tracks',
        );

        for (var track in _localStream!.getTracks()) {
          print('WebRTCSharer: Track kind: ${track.kind}, id: ${track.id}');

          // Handle track ended (when user stops screen sharing)
          track.onEnded = () {
            print('WebRTCSharer: Track ${track.kind} ended by user');
          };
        }

        // Add tracks to peer connection via addTrack (simpler and more reliable)
        print('WebRTCSharer: Adding ${_localStream!.getTracks().length} tracks to peer connection');
        for (var track in _localStream!.getTracks()) {
          try {
            final sender = await _peerConnection!.addTrack(track, _localStream!);
            print('WebRTCSharer: Successfully added ${track.kind} track');
            print('WebRTCSharer: Sender has track: ${sender.track?.kind}');
          } catch (e) {
            print('WebRTCSharer: Error adding ${track.kind} track: $e');
          }
        }

        _localStreamController.add(_localStream);
        _screenShareStateController.add(true);
        print('WebRTCSharer: Local stream added to controller');
        print('WebRTCSharer: Screen sharing is now active!');
      } on TimeoutException catch (e) {
        print('WebRTCSharer: Screen selection timeout: $e');
        print('WebRTCSharer: User may have cancelled the dialog. Trying camera as fallback...');
        await _startCameraFallback();
      } catch (e) {
        print('WebRTCSharer: Desktop screen capture failed: $e');
        print('WebRTCSharer: Error type: ${e.runtimeType}');
        print('WebRTCSharer: Trying camera as fallback...');
        await _startCameraFallback();
      }
    } catch (e) {
      print('WebRTCSharer: Error in desktop screen share: $e');
      _screenShareStateController.add(false);
    }
  }

  /// Start screen sharing on mobile (Android, iOS)
  Future<void> _startMobileScreenShare() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': '720',
            'minHeight': '1280',
            'minFrameRate': '15',
          },
          'optional': [
            {'maxWidth': '1280'},
            {'maxHeight': '720'},
            {'maxFrameRate': '30'},
          ],
        },
      };

      try {
        print('WebRTCSharer: Requesting display media for mobile...');

        _localStream = await navigator.mediaDevices.getDisplayMedia(
          mediaConstraints,
        );

        print('WebRTCSharer: Mobile screen capture started successfully');
        print(
          'WebRTCSharer: Stream has ${_localStream!.getTracks().length} tracks',
        );

        for (var track in _localStream!.getTracks()) {
          print('WebRTCSharer: Track kind: ${track.kind}, id: ${track.id}');

          track.onEnded = () {
            print('WebRTCSharer: Track ${track.kind} ended by user');
          };
        }

        _localStream!.getTracks().forEach((track) async {
          try {
            final sender = await _peerConnection!.addTrack(track, _localStream!);
            print('WebRTCSharer: Successfully added ${track.kind} track');
            print('WebRTCSharer: Sender has track: ${sender.track?.kind}');
          } catch (e) {
            print('WebRTCSharer: Error adding ${track.kind} track: $e');
          }
        });

        _localStreamController.add(_localStream);
        _screenShareStateController.add(true);
        print('WebRTCSharer: Mobile screen sharing is now active!');
      } catch (e) {
        print('WebRTCSharer: Mobile screen capture failed: $e');
        print('WebRTCSharer: Trying camera as fallback...');
        await _startCameraFallback();
      }
    } catch (e) {
      print('WebRTCSharer: Error in mobile screen share: $e');
      _screenShareStateController.add(false);
    }
  }

  /// Fallback to camera if screen capture fails
  Future<void> _startCameraFallback() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '15',
          },
          'optional': [
            {'maxWidth': '1280'},
            {'maxHeight': '720'},
          ],
        },
      });
      print('WebRTCSharer: Camera stream started as fallback');

      // Add tracks to peer connection
      print('WebRTCSharer: Adding ${_localStream!.getTracks().length} tracks from camera to peer connection');
      _localStream!.getTracks().forEach((track) async {
        try {
          final sender = await _peerConnection!.addTrack(track, _localStream!);
          print('WebRTCSharer: Successfully added ${track.kind} track from camera');
          print('WebRTCSharer: Sender has track: ${sender.track?.kind}');
        } catch (e) {
          print('WebRTCSharer: Error adding ${track.kind} track from camera: $e');
        }
      });

      _localStreamController.add(_localStream);
      _screenShareStateController.add(true);
      print('WebRTCSharer: Camera fallback active - connection established');
    } catch (cameraError) {
      print('WebRTCSharer: Camera also failed: $cameraError');
      _screenShareStateController.add(false);
    }
  }

  void _setupPeerConnectionHandlers() {
    if (_peerConnection == null) return;

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('WebRTCSharer: Generated ICE candidate');
      _iceCandidateController.add(candidate);
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('WebRTCSharer: Connection state: $state');
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('WebRTCSharer: ICE state: $state');
    };
  }

  /// Add ICE candidate
  Future<void> addIceCandidate(
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) async {
    try {
      final iceCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);

      // If peer connection isn't ready yet, queue the candidate
      if (_peerConnection == null || _isSettingUp) {
        print('WebRTCSharer: Queuing ICE candidate (connection not ready)');
        _pendingIceCandidates.add(iceCandidate);
        return;
      }

      await _peerConnection!.addCandidate(iceCandidate);
      print('WebRTCSharer: ICE candidate added');
    } catch (e) {
      print('WebRTCSharer: Error adding ICE: $e');
    }
  }

  /// Close connection
  Future<void> close() async {
    try {
      _pendingIceCandidates.clear();
      _isSettingUp = false;
      if (_localStream != null) {
        _localStream!.getTracks().forEach((t) => t.stop());
        await _localStream!.dispose();
        _localStream = null;
      }
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      print('WebRTCSharer: Connection closed');
    } catch (e) {
      print('WebRTCSharer: Error closing: $e');
    }
  }

  void dispose() {
    close();
    _connectionStateController.close();
    _iceCandidateController.close();
    _localStreamController.close();
    _screenShareStateController.close();
  }
}
