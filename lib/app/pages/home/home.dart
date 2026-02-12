import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_bloc.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_events.dart';
import 'package:project1_flutter/app/pages/live_users/live_users.dart';
import 'package:project1_flutter/app/pages/login/login.dart';
import 'package:project1_flutter/app/pages/notifications/notifications.dart';
import 'package:project1_flutter/app/pages/connection_management/connection_management.dart';
import 'package:project1_flutter/app/pages/search/search.dart';
import 'package:project1_flutter/app/service/socket_repository.dart';
import 'package:project1_flutter/app/widgets/theme_switch.dart';
import 'package:project1_flutter/app/widgets/floating_nav_bar.dart';
import 'package:project1_flutter/core/storage/hive_storage.dart';
import 'package:project1_flutter/core/storage/storage_keys.dart';
import 'package:uuid/uuid.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final SocketRepository _socketRepo = SocketRepository();
  String _deviceId = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription<bool>? _registrationSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _registrationSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await HiveStorage().init();

      final storedDeviceId = HiveStorage().get<String>(StorageKeys.deviceId);
      if (storedDeviceId != null) {
        _deviceId = storedDeviceId;
      } else {
        _deviceId = const Uuid().v4();
        await HiveStorage().set(StorageKeys.deviceId, _deviceId);
      }

      final email = HiveStorage().get<String>(StorageKeys.email);
      final token = HiveStorage().get<String>(StorageKeys.authToken);

      if (email == null || token == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Authentication required. Please log in again.';
        });
        return;
      }

      _socketRepo.connect();
      _socketRepo.register(email, token, _deviceId);

      _registrationSub = _socketRepo.registrationStatus.listen(
        (success) {
          if (!mounted) return;

          setState(() => _isLoading = false);

          if (success) {
            _socketRepo.confirmConnection();
            _socketRepo.checkOnlineDevices();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connected successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            if (!mounted) return;
            setState(() {
              _hasError = true;
              _errorMessage = 'Connection failed. Tap to retry.';
            });
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = error.toString();
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to initialize: ${e.toString()}';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const LiveUsers();
      case 1:
        return const Search();
      case 2:
        return const Notifications();
      case 3:
        return const ConnectionManagement();
      default:
        return const LiveUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Connecting...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Connection Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _init,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<ConnectionManagementBloc>().add(
                            Logout(),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => Login()),
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(elevation: 0, actions: const [ThemeSwitch()]),
      body: Stack(
        children: [
          _getPage(_selectedIndex),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingNavBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
