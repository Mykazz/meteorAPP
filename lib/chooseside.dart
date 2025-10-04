import 'package:asteroidsim/adventurermenu.dart';
import 'package:asteroidsim/terminal.dart';
import 'package:flutter/material.dart';

class ChooseSide extends StatelessWidget {
  const ChooseSide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // ensure full-screen taps register
        onTapDown: (TapDownDetails details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapX = details.localPosition.dx;

          if (tapX < screenWidth / 2) {
            // 👈 LEFT side tapped → Adventurer
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdventurerPage()));
          } else {
            // 👉 RIGHT side tapped → Advanced
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InteractiveTerminal()),
            );
          }
        },
        child: Stack(
          children: [
            // Background image that covers the full screen
            Positioned.fill(
              child: Image.asset('assets/boy.png', fit: BoxFit.cover),
            ),

            // Optional visual hint overlay
            Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: Text(
                        'Adventurer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: Text(
                        'Advanced User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
