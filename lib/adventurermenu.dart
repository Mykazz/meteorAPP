import 'package:asteroidsim/chooseside.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:asteroidsim/navigation.dart'; // ✅ for Navig screen

class AdventurerPage extends StatefulWidget {
  const AdventurerPage({super.key});

  @override
  State<AdventurerPage> createState() => _AdventurerPageState();
}

class _AdventurerPageState extends State<AdventurerPage> {
  // 🧠 Level-based sentence structure
  final Map<int, List<String>> _levelDialogues = {
    1: [
      'System initializing...',
      'Connecting to orbital sensors...',
      'Asteroid trajectory locked.',
      'You are humanity\'s last hope.',
      'You will have to input interstellar bullet parameters to save us all.',
      'Good luck, Adventurer.',
    ],
    2: [
      'Level 2 systems online.',
      'Neural link established.',
      'Asteroid density calibration in progress...',
      'Beware — new cosmic anomalies detected.',
      'Prepare to face unknown gravitational fields.',
    ],
    3: [
      'Entering asteroid belt...',
      'Sensor interference rising...',
      'Collecting energy fragments...',
      'System overheating — manual control required.',
      'Stay focused, Adventurer.',
    ],
  };

  int _level = 1; // current level
  int _currentSentenceIndex = 0;
  String _displayedText = '';
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _sentenceFinished = false;

  List<String> get _sentences => _levelDialogues[_level] ?? ['---'];

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _isTyping = true;
    _sentenceFinished = false;
    _displayedText = '';
    final sentence = _sentences[_currentSentenceIndex];
    int index = 0;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (index < sentence.length) {
        setState(() {
          _displayedText += sentence[index];
        });
        index++;
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _sentenceFinished = true;
        });
      }
    });
  }

  void _nextSentence() {
    if (_isTyping || !_sentenceFinished) return;

    if (_currentSentenceIndex < _sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
      });
      _startTyping();
    } else {
      if (_level < _levelDialogues.keys.length) {
        setState(() {
          _level++;
          _currentSentenceIndex = 0;
        });
        _startTyping();
      } else {
        setState(() {
          _displayedText = 'Mission complete. Awaiting next update...';
          _sentenceFinished = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  // ✅ Return navigation function
  void _goToNavig() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChooseSide()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ✅ Top app bar with return button
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Mission Terminal",
          style: TextStyle(color: Colors.greenAccent, fontFamily: "monospace"),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent),
            tooltip: "Return to Navigation",
            onPressed: _goToNavig,
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // 🧮 SCORE + LEVEL SECTION
              Column(
                children: [
                  const Text(
                    'SCORE',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '000000',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 28,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LEVEL $_level',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // 🖥 TERMINAL SECTION
              GestureDetector(
                onTap: _nextSentence,
                child: Column(
                  children: [
                    Text(
                      _displayedText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'Courier',
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_sentenceFinished &&
                        _currentSentenceIndex < _sentences.length - 1)
                      const Text(
                        'Click to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'Courier',
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // 🚀 SINGLE LAUNCH BUTTON
              Center(child: _MatrixButton(text: 'LAUNCH MISSION')),

              const SizedBox(height: 40),

              // 🖼️ ASTEROID IMAGE AT BOTTOM
              Image.asset(
                "assets/aster1.png",
                height: 350,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔲 Reusable Matrix-styled button
class _MatrixButton extends StatelessWidget {
  final String text;
  const _MatrixButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 🚀 TODO: implement launch mission navigation here
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.greenAccent,
        side: const BorderSide(color: Colors.greenAccent, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 8,
        shadowColor: Colors.greenAccent.withOpacity(0.3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Courier',
          letterSpacing: 2,
        ),
      ),
    );
  }
}
