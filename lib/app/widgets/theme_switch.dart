import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/core/theme/theme_cubit.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (BuildContext _, theme) {
        IconData themeIcon = Icons.sunny;
        if (theme == ThemeMode.light) {
          themeIcon = Icons.dark_mode;
        } else if (theme == ThemeMode.dark) {
          themeIcon = Icons.light_mode;
        } else {
          themeIcon = Icons.contrast;
        }
        return IconButton(
          onPressed: () {
            context.read<ThemeCubit>().toogle();
          },
          icon: Icon(themeIcon),
        );
      },
    );
  }
}
