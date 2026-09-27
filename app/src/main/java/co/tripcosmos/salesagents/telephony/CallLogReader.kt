package co.tripcosmos.salesagents.telephony

import android.content.Context
import android.provider.CallLog
import co.tripcosmos.salesagents.util.Format

/**
 * Reads what the phone itself recorded for a finished call. This is the source of truth: the phone-state
 * broadcast alone cannot tell "answered" from "rang out", and gives no number for outgoing calls.
 * Needs READ_CALL_LOG; without it every function returns null and the caller falls back to timers.
 */
object CallLogReader {

    data class Entry(val number: String, val type: Int, val durationSeconds: Int, val dateMillis: Long) {
        val isMissedIncoming: Boolean get() = type == CallLog.Calls.MISSED_TYPE || type == CallLog.Calls.REJECTED_TYPE || type == CallLog.Calls.BLOCKED_TYPE
        val isIncoming: Boolean get() = type == CallLog.Calls.INCOMING_TYPE || isMissedIncoming
        val isOutgoing: Boolean get() = type == CallLog.Calls.OUTGOING_TYPE
    }

    /**
     * Newest call-log row at or after [sinceMillis]. When [numberKey] (last 10 digits) is given the row must
     * match it, so a second call that ended a moment earlier is never picked up by mistake.
     */
    fun latest(context: Context, sinceMillis: Long, numberKey: String? = null): Entry? {
        return try {
            context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.TYPE, CallLog.Calls.DURATION, CallLog.Calls.DATE),
                "${CallLog.Calls.DATE} >= ?",
                arrayOf(sinceMillis.toString()),
                "${CallLog.Calls.DATE} DESC"
            )?.use { c ->
                while (c.moveToNext()) {
                    val number = c.getString(0).orEmpty()
                    if (numberKey.isNullOrBlank() || Format.phoneKey(number) == numberKey) {
                        return Entry(number, c.getInt(1), c.getInt(2), c.getLong(3))
                    }
                }
                null
            }
        } catch (e: SecurityException) {
            null // READ_CALL_LOG not granted
        } catch (e: Exception) {
            null
        }
    }
}
