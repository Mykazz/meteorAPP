// lib/pages/webview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
            url: WebUri('http://localhost:8080/three_demo/index.html'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            isInspectable: true,
            cacheEnabled: true,
            transparentBackground: false,
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
            useShouldInterceptFetchRequest: false,
          ),
          onWebViewCreated: (c) => _controller = c,
          onConsoleMessage: (controller, msg) {
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
