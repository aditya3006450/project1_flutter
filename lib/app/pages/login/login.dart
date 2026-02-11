import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/pages/home/home.dart';
import 'package:project1_flutter/app/pages/login/bloc/login_bloc.dart';
import 'package:project1_flutter/app/pages/login/bloc/login_events.dart';
import 'package:project1_flutter/app/pages/login/bloc/login_state.dart';
import 'package:project1_flutter/app/pages/signup/signup.dart';
import 'package:project1_flutter/app/widgets/theme_switch.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<LoginBloc, LoginStates>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Home()),
          );
        } else if (state is LoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "Login Failed",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: const [ThemeSwitch()],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_person_rounded, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      "Welcome Back",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextField(
                      onChanged: (email) {
                        context.read<LoginBloc>().add(EmailChanged(email));
                      },
                      decoration: InputDecoration(
                        hintText: "Email address",
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (password) {
                        context.read<LoginBloc>().add(
                          PasswordChanged(password),
                        );
                      },
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Password",
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        context.read<LoginBloc>().add(LoginSubmitted());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: BlocBuilder<LoginBloc, LoginStates>(
                        builder: (context, state) {
                          if (state is LoginLoading) {
                            return CircularProgressIndicator();
                          } else {
                            return Text("Login");
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("or"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => SignUp()),
                                  );
                                },
                                child: const Text(
                                  "Sign up",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
