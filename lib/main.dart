import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/pages/login/login.dart';
import 'package:project1_flutter/core/storage/hive_storage.dart';
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
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (BuildContext _, mode) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const Login(),
      ),
    );
  }
}
