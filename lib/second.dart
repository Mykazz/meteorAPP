import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});
  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  InAppWebViewController? _ctrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('http://localhost:8080/cesium_demo/cesium.html'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            isInspectable: true,
            allowsInlineMediaPlayback: true,
          ),
          onWebViewCreated: (c) => _ctrl = c,
          onConsoleMessage: (_, msg) => print('[Cesium] ${msg.message}'),
          onLoadError: (_, url, code, message) =>
              print('LOAD ERROR $code for $url: $message'),
          onLoadHttpError: (_, url, status, desc) =>
              print('HTTP ERROR $status for $url: $desc'),
        ),
      ),
    );
  }
}
