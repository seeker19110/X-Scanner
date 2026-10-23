import 'dart:io';

import 'package:flutter/services.dart';

import 'p1_migration.dart';

/// Available capacity on the Android app's internal storage volume.
class AndroidStorage implements Storage {
  AndroidStorage({
    required Directory appRoot,
    this._channel = const MethodChannel('org.xscanner/storage'),
  }) : _root = appRoot.absolute.path;

  final String _root;
  final MethodChannel _channel;
  static const _unavailable = FileSystemException(
    'Storage capacity is unavailable.',
    null,
  );

  @override
  Future<int> freeBytes(Directory dir) async {
    if (dir.absolute.path != _root) throw _unavailable;

    final Object? capacity;
    try {
      capacity = await _channel.invokeMethod<Object?>('availableBytes');
    } on PlatformException {
      throw _unavailable;
    } on MissingPluginException {
      throw _unavailable;
    }
    if (capacity is! int || capacity < 0) throw _unavailable;
    return capacity;
  }
}
