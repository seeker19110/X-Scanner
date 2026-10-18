package org.xscanner.x_scanner

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

private const val SENSITIVE_MARKER = "synthetic-private-capacity-marker"
private const val FIVE_GIB = 5L * 1024 * 1024 * 1024

private sealed class Reply {
    data class Success(val value: Any?) : Reply()
    data class Failure(
        val code: String,
        val message: String?,
        val details: Any?,
    ) : Reply()
    object NotImplemented : Reply()
}

private class RecordingResult : MethodChannel.Result {
    val replies = mutableListOf<Reply>()

    override fun success(result: Any?) {
        replies.add(Reply.Success(result))
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        replies.add(Reply.Failure(errorCode, errorMessage, errorDetails))
    }

    override fun notImplemented() {
        replies.add(Reply.NotImplemented)
    }
}

class StorageHandlerTest {
    private val capacityUnavailable = Reply.Failure(
        "capacity_unavailable",
        "Storage capacity is unavailable.",
        null,
    )

    @Test
    fun preservesZeroCapacity() {
        assertSuccess(0L)
    }

    @Test
    fun preservesOrdinaryCapacityAsLong() {
        assertSuccess(4096L)
    }

    @Test
    fun preservesCapacityLargerThan32Bits() {
        assertSuccess(FIVE_GIB)
    }

    @Test
    fun readsFreshCapacityForEveryInvocation() {
        var calls = 0
        val handler = StorageHandler {
            calls++
            if (calls == 1) FIVE_GIB else 0L
        }
        val first = RecordingResult()
        val second = RecordingResult()

        handler.onMethodCall(MethodCall("availableBytes", null), first)
        handler.onMethodCall(MethodCall("availableBytes", null), second)

        assertEquals(listOf(Reply.Success(FIVE_GIB)), first.replies)
        assertEquals(listOf(Reply.Success(0L)), second.replies)
        assertEquals(2, calls)
    }

    @Test
    fun rejectsNegativeCapacity() {
        val result = RecordingResult()
        StorageHandler { -1L }.onMethodCall(MethodCall("availableBytes", null), result)

        assertEquals(listOf(capacityUnavailable), result.replies)
    }

    @Test
    fun sanitizesRuntimeFailures() {
        val failures = listOf(
            IllegalArgumentException(SENSITIVE_MARKER),
            SecurityException(SENSITIVE_MARKER),
            IllegalStateException(SENSITIVE_MARKER),
        )
        for (failure in failures) {
            val result = RecordingResult()
            StorageHandler { throw failure }
                .onMethodCall(MethodCall("availableBytes", null), result)

            assertEquals(listOf(capacityUnavailable), result.replies)
        }
    }

    @Test
    fun sanitizesOtherExceptions() {
        val result = RecordingResult()
        StorageHandler { throw IOException(SENSITIVE_MARKER) }
            .onMethodCall(MethodCall("availableBytes", null), result)

        assertEquals(listOf(capacityUnavailable), result.replies)
    }

    @Test
    fun doesNotCatchJvmErrors() {
        val fatal = AssertionError(SENSITIVE_MARKER)
        val result = RecordingResult()
        val handler = StorageHandler { throw fatal }

        val thrown = assertThrows(AssertionError::class.java) {
            handler.onMethodCall(MethodCall("availableBytes", null), result)
        }

        assertSame(fatal, thrown)
        assertTrue(result.replies.isEmpty())
    }

    @Test
    fun rejectsAllNonNullArgumentsWithoutReadingCapacity() {
        var reads = 0
        val handler = StorageHandler {
            reads++
            FIVE_GIB
        }
        val arguments = listOf(
            SENSITIVE_MARKER,
            emptyMap<String, Any>(),
            listOf(SENSITIVE_MARKER),
            0,
            false,
        )
        for (argument in arguments) {
            val result = RecordingResult()
            handler.onMethodCall(MethodCall("availableBytes", argument), result)

            assertEquals(
                listOf(Reply.Failure("invalid_arguments", "Arguments must be null.", null)),
                result.replies,
            )
        }
        assertEquals(0, reads)
    }

    @Test
    fun unknownMethodIsNotImplementedWithoutReadingCapacity() {
        assertUnknownMethod(null)
    }

    @Test
    fun unknownMethodWithArgumentsIsStillNotImplemented() {
        assertUnknownMethod(SENSITIVE_MARKER)
    }

    private fun assertSuccess(capacity: Long) {
        val result = RecordingResult()
        var reads = 0
        StorageHandler {
            reads++
            capacity
        }.onMethodCall(MethodCall("availableBytes", null), result)

        assertEquals(listOf(Reply.Success(capacity)), result.replies)
        assertEquals(1, reads)
    }

    private fun assertUnknownMethod(arguments: Any?) {
        val result = RecordingResult()
        var reads = 0
        StorageHandler {
            reads++
            FIVE_GIB
        }.onMethodCall(MethodCall("unknown", arguments), result)

        assertEquals(listOf(Reply.NotImplemented), result.replies)
        assertEquals(0, reads)
    }
}
