import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown in release builds in place of a widget that failed to build.
const String brokenWidgetText = 'Đã xảy ra lỗi. Hãy quay lại rồi thử lại.';

/// Installs the app-wide error handlers (BASE-ERR-002).
///
/// Framework errors ([FlutterError.onError]) and uncaught asynchronous
/// errors ([PlatformDispatcher.onError]) are handled, so the app keeps
/// running. In a [release] build only one line with the error's type is
/// logged: messages and stacks can hold file paths or document titles
/// (CLAUDE.md: never log user content), and a widget that fails to build
/// shows [brokenWidgetText] instead of the grey release box. Other builds
/// show the full error to the developer, as Flutter does by default.
void installErrorHandlers({bool release = kReleaseMode}) {
  void report(FlutterErrorDetails details) {
    if (release) {
      debugPrint(
        'X-Scanner: unhandled error (${details.exception.runtimeType})',
      );
    } else {
      FlutterError.presentError(details);
    }
  }

  FlutterError.onError = report;
  PlatformDispatcher.instance.onError = (error, stack) {
    report(FlutterErrorDetails(exception: error, stack: stack));
    return true;
  };
  if (release) {
    ErrorWidget.builder = (_) => const _BrokenWidget();
  }
}

/// A plain, readable message that works without any app ancestors.
class _BrokenWidget extends StatelessWidget {
  const _BrokenWidget();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        brokenWidgetText,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
    ),
  );
}
