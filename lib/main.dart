import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_bloc.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_events.dart';
import 'package:project1_flutter/app/pages/home/home.dart';
import 'package:project1_flutter/app/pages/login/bloc/login_bloc.dart';
import 'package:project1_flutter/app/pages/login/login.dart';
import 'package:project1_flutter/app/pages/notifications/bloc/notifications_bloc.dart';
import 'package:project1_flutter/app/pages/signup/bloc/signup_bloc.dart';
import 'package:project1_flutter/app/service/app_messanger.dart';
import 'package:project1_flutter/app/service/permission_service.dart';
import 'package:project1_flutter/core/repositories/auth_repository.dart';
import 'package:project1_flutter/core/repositories/connection_repository.dart';
import 'package:project1_flutter/core/storage/hive_storage.dart';
import 'package:project1_flutter/core/storage/storage_keys.dart';
import 'package:project1_flutter/core/theme/app_theme.dart';
import 'package:project1_flutter/core/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage().init();
  runApp(
    BlocProvider(
      create: (_) => ThemeCubit(),
      child: Builder(builder: (context) => MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var authToken = HiveStorage().get(StorageKeys.authToken);

    return MultiRepositoryProvider(
      providers: [RepositoryProvider(create: (_) => ConnectionRepository())],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SignupBloc(AuthRepository())),
          BlocProvider(create: (_) => LoginBloc(AuthRepository())),
          BlocProvider(
            create: (_) => NotificationsBloc(ConnectionRepository()),
          ),
          BlocProvider(
            create: (context) => ConnectionManagementBloc(
              RepositoryProvider.of<ConnectionRepository>(context),
            )..add(LoadConnections()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (BuildContext _, mode) => MaterialApp(
            navigatorKey: AppMessenger.navigatorKey,
            scaffoldMessengerKey: AppMessenger.key,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: PermissionWrapper(
              child: authToken == null || authToken.toString().isEmpty
                  ? Login()
                  : Home(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget to request permissions after MaterialApp is initialized
class PermissionWrapper extends StatefulWidget {
  final Widget child;
  const PermissionWrapper({super.key, required this.child});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  final PermissionService _permissionService = PermissionService();
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    // Request permissions after first frame when MaterialApp is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_permissionsRequested) {
        _permissionsRequested = true;
        _permissionService.requestPermissions(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
