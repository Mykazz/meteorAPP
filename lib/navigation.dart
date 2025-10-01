// lib/pages/navig.dart
// ignore_for_file: prefer_const_constructors, file_names

import 'package:asteroidsim/webview1.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// ✅ import the moved screen here
import 'package:asteroidsim/second.dart'; // your Settings()

class Navig extends StatefulWidget {
  const Navig({Key? key}) : super(key: key);

  @override
  State<Navig> createState() => _NavigState();
}

class _NavigState extends State<Navig> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = const WebViewScreen();
        break;
      case 1:
        body = const Settings();
        break;
      default:
        body = const SizedBox.shrink();
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: GNav(
        iconSize: 25,
        backgroundColor: Colors.white,
        color: const Color.fromARGB(255, 112, 112, 112),
        activeColor: const Color.fromARGB(255, 24, 81, 138),
        tabBackgroundColor: const Color.fromARGB(255, 204, 221, 243),
        padding: const EdgeInsets.all(16),
        gap: 8,
        tabMargin: const EdgeInsets.symmetric(horizontal: 50),
        mainAxisAlignment: MainAxisAlignment.center,
        tabs: const [
          GButton(icon: Icons.home, text: 'Home'),
          GButton(icon: Icons.calendar_month, text: 'Programme'),
        ],
        selectedIndex: _selectedIndex,
        onTabChange: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
