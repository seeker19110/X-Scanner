import 'package:flutter/material.dart';

import 'app/theme.dart';

void main() => runApp(const XScannerApp());

class XScannerApp extends StatelessWidget {
  const XScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'X-Scanner',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(title: const Text('X-Scanner')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Bản nền P0 — chưa có chức năng chụp.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
