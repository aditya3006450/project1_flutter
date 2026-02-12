import 'package:flutter/material.dart';
import 'package:project1_flutter/app/pages/live_users/live_users.dart';
import 'package:project1_flutter/app/pages/notifications/notifications.dart';
import 'package:project1_flutter/app/pages/connection_management/connection_management.dart';
import 'package:project1_flutter/app/pages/search/search.dart';
import 'package:project1_flutter/app/widgets/theme_switch.dart';
import 'package:project1_flutter/app/widgets/floating_nav_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, actions: [const ThemeSwitch()]),
      drawer: Drawer(),
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
}
