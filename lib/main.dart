import 'package:asteroidsim/chooseside.dart';
import 'package:asteroidsim/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'intro_screen.dart'; // import the intro screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final server = InAppLocalhostServer(documentRoot: 'assets', port: 8080);
  await server.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChooseSide(), // Start with intro
    );
  }
}
