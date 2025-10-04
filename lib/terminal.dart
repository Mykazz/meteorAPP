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
      case "start":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Navig()),
        );
        break;
      case "help":
        setState(() {
          output.addAll([
            "Available commands:",
            " - start : launch simulation",
            " - help  : show this list",
            " - exit  : quit terminal",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fullscreen terminal background
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Center(
          // <-- Center the entire terminal block
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Shrink-wrap terminal
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
