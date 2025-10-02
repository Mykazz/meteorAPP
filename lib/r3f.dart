import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class R3F extends StatefulWidget {
  const R3F({Key? key}) : super(key: key);

  @override
  State<R3F> createState() => _R3FState();
}

class _R3FState extends State<R3F> {
  InAppWebViewController? _controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('http://localhost:8080/r3f_demo/index.html'),
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
