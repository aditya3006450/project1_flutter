import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_bloc.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_events.dart';
import 'package:project1_flutter/app/pages/connection_management/bloc/connection_management_state.dart';
import 'package:project1_flutter/app/pages/login/login.dart';

class ConnectionManagement extends StatelessWidget {
  const ConnectionManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: ListView(
            children: [
              ListTile(
                title: Text("Who can access my device"),
                subtitle: Text("View devices that can access your device"),

                leading: Icon(Icons.devices),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectionListPage(
                        showFromEmail: true,
                        title: "Who can access my device",
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text("Whose device can I access"),
                subtitle: Text("View devices you can access"),
                leading: Icon(Icons.devices_other),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectionListPage(
                        showFromEmail: false,
                        title: "Whose device can I access",
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text("Logout", style: TextStyle(color: Colors.red)),
                subtitle: Text(
                  "Sign out of your account",
                  style: TextStyle(color: Colors.red),
                ),
                leading: Icon(Icons.logout, color: Colors.red),
                onTap: () {
                  BlocProvider.of<ConnectionManagementBloc>(
                    context,
                  ).add(Logout());
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => Login()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectionListPage extends StatelessWidget {
  final bool showFromEmail;
  final String title;

  const ConnectionListPage({
    super.key,
    required this.showFromEmail,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocListener<ConnectionManagementBloc, ConnectionManagementState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          }
        },
        child: BlocBuilder<ConnectionManagementBloc, ConnectionManagementState>(
          builder: (context, state) {
            if (state is ConnectionManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ConnectionManagementError) {
              return Center(child: Text(state.message));
            }
            if (state is ConnectionManagementLoaded) {
              final connections = showFromEmail
                  ? state.connectedFrom
                  : state.connectedTo;
              if (connections.isEmpty) {
                return const Center(child: Text("No connections"));
              }
              return ListView.builder(
                itemCount: connections.length,
                itemBuilder: (context, index) {
                  final conn = connections[index];
                  final email = showFromEmail
                      ? conn['from_email']
                      : conn['to_email'];
                  final isAccepted = conn['is_accepted'] as bool;
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(email),
                    subtitle: Text(isAccepted ? "Connected" : "Pending"),
                    trailing: Icon(
                      isAccepted ? Icons.check_circle : Icons.hourglass_empty,
                      color: isAccepted ? Colors.green : Colors.orange,
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
