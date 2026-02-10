import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/pages/home/home.dart';
import 'package:project1_flutter/app/pages/login/bloc/login_bloc.dart';
import 'package:project1_flutter/app/pages/login/login.dart';
import 'package:project1_flutter/app/pages/signup/bloc/signup_bloc.dart';
import 'package:project1_flutter/core/repositories/auth_repository.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SignupBloc(AuthRepository())),
        BlocProvider(create: (_) => LoginBloc(AuthRepository())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (BuildContext _, mode) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: authToken == null || authToken.toString().isEmpty
              ? Login()
              : Home(),
        ),
      ),
    );
  }
}
