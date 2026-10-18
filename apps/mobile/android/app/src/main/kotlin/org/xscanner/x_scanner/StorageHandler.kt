package org.xscanner.x_scanner

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class StorageHandler(
    private val availableBytes: () -> Long,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "availableBytes") {
            result.notImplemented()
            return
        }
        if (call.arguments != null) {
            result.error("invalid_arguments", "Arguments must be null.", null)
            return
        }

        val capacity = try {
            availableBytes()
        } catch (_: Exception) {
            null
        }
        if (capacity == null || capacity < 0) {
            result.error("capacity_unavailable", "Storage capacity is unavailable.", null)
        } else {
            result.success(capacity)
        }
    }
}
