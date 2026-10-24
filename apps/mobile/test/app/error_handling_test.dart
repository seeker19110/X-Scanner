import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/app/error_handling.dart';

/// Synthetic private content: a title and an app path that must never
/// reach a release log.
const String _secret = 'TIEU-DE-RIENG /data/user/0/org.xscanner/files/x';

void main() {
  group('handlers', () {
    late FlutterExceptionHandler? oldFlutter;
    late ErrorCallback? oldPlatform;
    late ErrorWidgetBuilder oldBuilder;
    late DebugPrintCallback oldPrint;
    late List<String> logs;
    late FlutterExceptionHandler oldPresent;
    late List<FlutterErrorDetails> presented;

    void restore() {
      FlutterError.onError = oldFlutter;
      PlatformDispatcher.instance.onError = oldPlatform;
      ErrorWidget.builder = oldBuilder;
      debugPrint = oldPrint;
      FlutterError.presentError = oldPresent;
    }

    setUp(() {
      oldFlutter = FlutterError.onError;
      oldPlatform = PlatformDispatcher.instance.onError;
      oldBuilder = ErrorWidget.builder;
      oldPrint = debugPrint;
      oldPresent = FlutterError.presentError;
      logs = [];
      presented = [];
      debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    });
    tearDown(restore);

    group('release build (BASE-ERR-002)', () {
      test('a framework error logs one line with its type only', () {
        installErrorHandlers(release: true);
        FlutterError.onError!(
          FlutterErrorDetails(
            exception: StateError(_secret),
            stack: StackTrace.current,
            library: 'x_scanner test',
          ),
        );
        expect(logs, hasLength(1));
        expect(logs.single, contains('StateError'));
        expect(logs.single, isNot(contains('TIEU-DE')));
        expect(logs.single, isNot(contains('/data/')));
        expect(logs.single, isNot(contains('error_handling_test')));
      });

      test('an uncaught async error is handled, so the app keeps running, '
          'and logs its type only', () {
        installErrorHandlers(release: true);
        final handled = PlatformDispatcher.instance.onError!(
          const FileSystemException(_secret, '/data/user/0/org.xscanner/x'),
          StackTrace.current,
        );
        expect(handled, isTrue);
        expect(logs, hasLength(1));
        expect(logs.single, contains('FileSystemException'));
        expect(logs.single, isNot(contains('TIEU-DE')));
        expect(logs.single, isNot(contains('/data/')));
      });
    });

    group('debug build', () {
      test('a framework error is still shown in full to the developer', () {
        FlutterError.presentError = presented.add;
        installErrorHandlers(release: false);
        FlutterError.onError!(
          FlutterErrorDetails(
            exception: StateError('developer detail'),
            stack: StackTrace.current,
          ),
        );
        expect('${presented.single.exception}', contains('developer detail'));
        expect(presented.single.stack, isNotNull);
      });

      test('an uncaught async error is handled and shown in full', () {
        FlutterError.presentError = presented.add;
        installErrorHandlers(release: false);
        final handled = PlatformDispatcher.instance.onError!(
          StateError('developer detail'),
          StackTrace.current,
        );
        expect(handled, isTrue);
        expect('${presented.single.exception}', contains('developer detail'));
        expect(presented.single.stack, isNotNull);
      });
    });
  });

  testWidgets('release: a widget that fails to build shows a generic '
      'message', (tester) async {
    // Saved here, not in setUp: the binding installs its own handlers
    // for the duration of a widget test.
    final builder = ErrorWidget.builder;
    final flutterError = FlutterError.onError;
    final platformError = PlatformDispatcher.instance.onError;
    installErrorHandlers(release: true);
    final shown = ErrorWidget.builder(
      FlutterErrorDetails(exception: StateError(_secret)),
    );
    ErrorWidget.builder = builder;
    FlutterError.onError = flutterError;
    PlatformDispatcher.instance.onError = platformError;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: shown)));
    expect(find.text(brokenWidgetText), findsOneWidget);
    expect(find.textContaining('TIEU-DE'), findsNothing);
  });
}
