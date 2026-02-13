import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:project1_flutter/app/service/app_messanger.dart';
import 'package:project1_flutter/app/service/socket_repository.dart';
import 'package:project1_flutter/app/service/webrtc_service.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({
    super.key,
    required this.fromDevice,
    required this.fromEmail,
    required this.toDevice,
    required this.toEmail,
  });

  final String fromDevice;
  final String fromEmail;
  final String toDevice;
  final String toEmail;

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final WebRTCService _webRTCService = WebRTCService();
  final SocketRepository _socketRepository = SocketRepository();

  MediaStream? _remoteStream;
  WebRTCConnectionState _connectionState = WebRTCConnectionState.idle;
  bool _isConnecting = true;
  String? _errorMessage;

  // RTC video renderer
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // Stream subscriptions
  StreamSubscription? _sdpAnswerSubscription;
  StreamSubscription? _iceCandidateSubscription;
  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _remoteStreamSubscription;
  StreamSubscription? _localIceCandidateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    try {
      // Initialize video renderer
      await _remoteRenderer.initialize();
      print('CanvasScreen: Remote renderer initialized');

      // Check if there's already a stream from a previous connection
      if (_webRTCService.currentRemoteStream != null) {
        print('CanvasScreen: Found existing remote stream, assigning to renderer');
        if (mounted) {
          setState(() {
            _remoteStream = _webRTCService.currentRemoteStream;
            _remoteRenderer.srcObject = _remoteStream;
          });
        }
      }

      // Listen to connection state changes
      _connectionStateSubscription = _webRTCService.connectionState.listen((
        state,
      ) {
        print('CanvasScreen: Connection state listener fired: $state');
        if (mounted) {
          setState(() {
            _connectionState = state;
            if (state == WebRTCConnectionState.connected) {
              _isConnecting = false;
            } else if (state == WebRTCConnectionState.failed) {
              _isConnecting = false;
              _errorMessage = 'Connection failed';
            }
          });
        }
      });

      // Listen to remote stream - THIS IS CRITICAL
      _remoteStreamSubscription = _webRTCService.remoteStream.listen((stream) {
        print('CanvasScreen: Remote stream listener fired - stream is ${stream != null ? "NOT NULL" : "NULL"}');
        if (stream != null) {
          print('CanvasScreen: Remote stream has ${stream.getTracks().length} tracks');
          for (var track in stream.getTracks()) {
            print('CanvasScreen: Track - kind: ${track.kind}, enabled: ${track.enabled}');
          }
        }
        
        if (mounted) {
          setState(() {
            _remoteStream = stream;
            if (stream != null) {
              print('CanvasScreen: Assigning stream to renderer');
              _remoteRenderer.srcObject = stream;
              print('CanvasScreen: Stream assigned to renderer, srcObject type: ${_remoteRenderer.srcObject.runtimeType}');
              
              // Force a rebuild with a small delay to ensure renderer is updated
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    print('CanvasScreen: Force rebuild after stream assignment');
                  });
                }
              });
            }
          });
        }
      });

      // Listen to local ICE candidates and send to sharer
      _localIceCandidateSubscription = _webRTCService.iceCandidates.listen((
        candidate,
      ) {
        print('CanvasScreen: Sending ICE candidate to sharer');
        _socketRepository.sendIceCandidate(
          widget.toEmail,
          widget.toDevice,
          candidate.candidate!,
          candidate.sdpMid!,
          candidate.sdpMLineIndex!,
        );
      });

      // Listen for SDP answers from sharer
      _sdpAnswerSubscription = _socketRepository.sdpAnswers.listen(
        _handleSdpAnswer,
      );

      // Listen for ICE candidates from sharer
      _iceCandidateSubscription = _socketRepository.iceCandidates.listen(
        _handleIceCandidate,
      );

      // Listen for user left event
      _userLeftSubscription = _socketRepository.userLeft.listen(
        _handleUserLeft,
      );

      // Create and send SDP offer (viewer initiates)
      print('CanvasScreen: Creating SDP offer...');
      print(
        'CanvasScreen: fromEmail=${widget.fromEmail}, fromDevice=${widget.fromDevice}',
      );
      print(
        'CanvasScreen: toEmail=${widget.toEmail}, toDevice=${widget.toDevice}',
      );

      final offer = await _webRTCService.createOffer();
      if (offer != null) {
        print('CanvasScreen: SDP offer created successfully');
        _socketRepository.sendSdpOffer(
          widget.toEmail,
          widget.toDevice,
          offer.sdp!,
          offer.type!,
        );
        print('CanvasScreen: SDP offer sent to ${widget.toEmail}');
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Failed to create connection offer';
        });
      }
    } catch (e) {
      print('CanvasScreen: Error initializing WebRTC: $e');
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  void _handleSdpAnswer(Map<String, dynamic> data) {
    try {
      final fromEmail = data['from_email']?.toString();
      final fromDevice = data['from_device']?.toString();

      print('CanvasScreen: Received SDP answer from $fromEmail/$fromDevice');
      print('CanvasScreen: Expected from ${widget.toEmail}/${widget.toDevice}');

      // Verify this answer is from our target
      if (fromEmail != widget.toEmail || fromDevice != widget.toDevice) {
        print('CanvasScreen: Ignoring answer - not from our target');
        return;
      }

      final payload = data['payload'];
      if (payload == null) return;

      final sdp = payload['sdp']?.toString();
      final type = payload['type']?.toString();

      if (sdp != null && type != null) {
        print('CanvasScreen: Processing SDP answer');
        _webRTCService.handleAnswer(sdp, type);
      }
    } catch (e) {
      print('CanvasScreen: Error handling SDP answer: $e');
    }
  }

  void _handleIceCandidate(Map<String, dynamic> data) {
    try {
      final fromEmail = data['from_email']?.toString();
      final fromDevice = data['from_device']?.toString();

      // Verify this candidate is from our target
      if (fromEmail != widget.toEmail || fromDevice != widget.toDevice) {
        return;
      }

      final payload = data['payload'];
      if (payload == null) return;

      final candidate = payload['candidate']?.toString();
      final sdpMid = payload['sdpMid']?.toString();
      final sdpMLineIndex = payload['sdpMLineIndex'];

      if (candidate != null && sdpMid != null && sdpMLineIndex != null) {
        _webRTCService.addIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex is int
              ? sdpMLineIndex
              : int.tryParse(sdpMLineIndex.toString()) ?? 0,
        );
      }
    } catch (e) {
      print('CanvasScreen: Error handling ICE candidate: $e');
    }
  }

  void _handleUserLeft(Map<String, dynamic> data) {
    final email = data['email']?.toString();
    final device = data['device']?.toString();

    if (email == widget.toEmail && device == widget.toDevice) {
      print('CanvasScreen: User left - closing connection');
      _endConnection();
      AppMessenger.showBanner(
        message: 'Connection ended - user disconnected',
        backgroundColor: Colors.orange,
      );
    }
  }

  void _endConnection() {
    // Send disconnect event
    _socketRepository.disconnect();

    // Close WebRTC connection
    _webRTCService.close();

    // Navigate back
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _sdpAnswerSubscription?.cancel();
    _iceCandidateSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    _localIceCandidateSubscription?.cancel();

    _remoteRenderer.dispose();
    _webRTCService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen remote video - always render the video view
          Container(
            color: Colors.black,
            child: _remoteStream != null
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isConnecting) ...[
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Connecting...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for ${widget.toEmail}',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ] else if (_errorMessage != null) ...[
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Go Back'),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.screen_share,
                            color: Colors.white54,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Waiting for screen share...',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),

          // End Connection button overlay
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _endConnection,
                icon: const Icon(Icons.call_end),
                label: const Text('End Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),

          // Connection status indicator (subtle)
          if (_connectionState == WebRTCConnectionState.connected)
            Positioned(
              top: 40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
