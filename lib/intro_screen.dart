import 'dart:async';
import 'package:flutter/material.dart';
import 'package:asteroidsim/navigation.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int currentIndex = 0;

  final List<String> messages = [
    "You are the last person who is able to do this",
    "It will be difficult",
    "But you can",
  ];

  @override
  void initState() {
    super.initState();

    // Step through messages every 3 seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (currentIndex < messages.length - 1) {
        setState(() => currentIndex++);
      } else {
        timer.cancel();
        // After last message -> navigate to Navig()
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Navig()),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(seconds: 2),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            messages[currentIndex],
            key: ValueKey<int>(currentIndex),
            textAlign: TextAlign.center,
            style: const TextStyle(
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
