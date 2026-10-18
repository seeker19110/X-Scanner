package org.xscanner.x_scanner

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val appFilesPath = applicationContext.filesDir.path
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.xscanner/storage")
            .setMethodCallHandler(StorageHandler { StatFs(appFilesPath).availableBytes })
    }
}
