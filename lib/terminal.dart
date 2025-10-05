import 'package:asteroidsim/asteroids.dart';
import 'package:asteroidsim/biggest.dart';
import 'package:asteroidsim/chooseside.dart';
import 'package:asteroidsim/closest.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:asteroidsim/navigation.dart'; // your main app page

class InteractiveTerminal extends StatefulWidget {
  const InteractiveTerminal({super.key});

  @override
  State<InteractiveTerminal> createState() => _InteractiveTerminalState();
}

class _InteractiveTerminalState extends State<InteractiveTerminal> {
  final List<String> output = [
    "Asteroid Simulation Terminal v1.0",
    "Type 'help' for available commands.",
  ];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _handleCommand(String cmd) {
    setState(() {
      output.add("> $cmd"); // echo user input
    });

    switch (cmd.toLowerCase().trim()) {
      case "near":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClosestAsteroidsScreen()),
        );
        break;
      case "big":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BiggestAsteroidsScreen()),
        );
        break;
      case "help":
        setState(() {
          output.addAll([
            "Commands for help",
            " - danger : lists dangerous asteroids",
            " - big    : lists biggest asteroids",
            " - near   : lists near earth asteroids",
            " - random : lists random asteroids",
            " - mymath : you create your own asteroid",
            " - start  : launch simulation",
            " - help   : show this list",
            " - story  : go to story mode",
          ]);
        });
        break;
      case "exit":
        setState(() {
          output.add("Session ended.");
        });
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop();
        });
        break;
      default:
        setState(() {
          output.add("Unknown command: '$cmd'");
        });
    }

    _controller.clear();
  }

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

      // ✅ AppBar with return button
      appBar: AppBar(
        title: const Text(
          "Interactive Terminal",
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

      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scrollable terminal output
                  Flexible(
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in output)
                            Text(
                              line,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Input line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "> ",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 18,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 18,
                          ),
                          cursorColor: Colors.greenAccent,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                          ),
                          onSubmitted: _handleCommand,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
