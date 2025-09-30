import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final server = InAppLocalhostServer(
    documentRoot:
        'assets/three_demo', // must match pubspec asset key (case-sensitive)
    port: 8080,
  );
  await server.start();
  // ignore: avoid_print
  print('Server running on http://localhost:8080');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            // bump ?v= when you change HTML/JS to bust any caching
            url: WebUri('http://localhost:8080/index.html'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            isInspectable: true, // enable chrome://inspect
            cacheEnabled: true, // avoid stale assets while debugging
            transparentBackground: false,
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
            // Let module fetches go through normally
            useShouldInterceptFetchRequest: false,
          ),
          onWebViewCreated: (c) => _controller = c,
          onConsoleMessage: (controller, msg) {
            // mirror browser console to Flutter logs
            // ignore: avoid_print
            print('[console] ${msg.message}');
          },
          onLoadError: (controller, url, code, message) {
            // ignore: avoid_print
            print('LOAD ERROR $code for $url: $message');
          },
          onLoadHttpError: (controller, url, statusCode, description) {
            // ignore: avoid_print
            print('HTTP ERROR $statusCode for $url: $description');
          },
        ),
      ),
    );
  }
}
