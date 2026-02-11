import 'package:flutter/material.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (_, index) => ListTile(
        subtitle: Text("$index is index"),
        trailing: Icon(Icons.add),
        title: Text("$index"),
      ),
    );
  }
}
