import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(DramaticApp());

class DramaticApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DramaticScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DramaticScreen extends StatefulWidget {
  @override
  _DramaticScreenState createState() => _DramaticScreenState();
}

class _DramaticScreenState extends State<DramaticScreen> {
  int currentIndex = 0;

  final List<String> messages = [
    "You are the last person who is able to do this",
    "It will be difficult",
    "But you can",
  ];

  @override
  void initState() {
    super.initState();
    // Auto-transition every 3 seconds
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (currentIndex < messages.length - 1) {
        setState(() => currentIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedSwitcher(
          duration: Duration(seconds: 2),
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Dramatic fade + slight zoom
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            messages[currentIndex],
            key: ValueKey<int>(currentIndex),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
