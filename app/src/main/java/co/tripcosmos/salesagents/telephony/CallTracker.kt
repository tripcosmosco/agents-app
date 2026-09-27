package co.tripcosmos.salesagents.telephony

import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.util.Format
import com.google.gson.Gson

/**
 * Turns the raw phone-state events (RINGING / OFFHOOK / IDLE) into one finished-call record.
 *
 * Kept free of Android types so the decision logic can be unit-tested. State is persisted, not held in
 * statics: Android may kill this process between "ringing" and "idle", and a static would lose the call.
 */
data class CallState(
    val phase: String = "idle",            // idle | ringing | active
    val incoming: Boolean = false,
    val number: String = "",
    val startedAt: Long = 0,               // when the call connected (OFFHOOK) or, for a miss, when it rang
    val ringedAt: Long = 0
)

/** A finished call, ready to send to the server and to show in the post-call sheet. */
data class FinishedCall(
    val callId: String,
    val number: String,
    /** "incoming", "outgoing" or "missed" (the server's vocabulary). */
    val callType: String,
    val durationSeconds: Int,
    /** False when an outgoing call rang out, or an incoming call was missed/rejected. */
    val answered: Boolean,
    val at: Long
) {
    val note: String
        get() = when {
            callType == "missed" -> "Missed call"
            !answered -> "Outgoing call, not answered"
            else -> ""
        }
}

object CallTracker {

    const val PREF_STATE = "tc_call_state"
    const val PREF_PENDING_OUT = "tc_pending_outgoing"
    const val PREF_LAST_CALL = "tc_last_call"

    /** A number the app is about to dial: remembered so the finished call can be attributed to it. */
    private const val PENDING_TTL_MS = 3 * 60 * 1000L

    private val gson = Gson()

    // ---- persisted state ----------------------------------------------------------------

    fun load(): CallState = try {
        gson.fromJson(AppConfig.getString(PREF_STATE), CallState::class.java) ?: CallState()
    } catch (e: Exception) { CallState() }

    fun save(state: CallState) = AppConfig.putString(PREF_STATE, gson.toJson(state))

    fun noteOutgoing(number: String, now: Long = System.currentTimeMillis()) {
        AppConfig.putString(PREF_PENDING_OUT, "$now|$number")
    }

    fun pendingOutgoing(now: Long = System.currentTimeMillis()): String {
        val raw = AppConfig.getString(PREF_PENDING_OUT)
        val cut = raw.indexOf('|')
        if (cut < 0) return ""
        val at = raw.substring(0, cut).toLongOrNull() ?: return ""
        return if (now - at <= PENDING_TTL_MS) raw.substring(cut + 1) else ""
    }

    fun clearPendingOutgoing() = AppConfig.putString(PREF_PENDING_OUT, "")

    // ---- state machine (pure) ------------------------------------------------------------

    fun onRinging(state: CallState, number: String, now: Long): CallState =
        state.copy(phase = "ringing", incoming = true, number = number.ifBlank { state.number }, ringedAt = now, startedAt = 0)

    fun onOffHook(state: CallState, pendingOutgoing: String, now: Long): CallState {
        val incoming = state.phase == "ringing"
        val number = if (incoming) state.number else pendingOutgoing.ifBlank { state.number }
        return state.copy(phase = "active", incoming = incoming, number = number, startedAt = now)
    }

    /** IDLE: returns null when there was no call to finish (e.g. a duplicate IDLE broadcast). */
    fun onIdle(state: CallState, now: Long): FinishedCall? {
        return when (state.phase) {
            "active" -> {
                val seconds = ((now - state.startedAt) / 1000).toInt().coerceAtLeast(0)
                FinishedCall(
                    callId = id(state.startedAt, state.number),
                    number = state.number,
                    callType = if (state.incoming) "incoming" else "outgoing",
                    // For an outgoing call OFFHOOK starts at dialling, so this is an upper bound; CallLogReader corrects it.
                    durationSeconds = seconds,
                    answered = true,
                    at = state.startedAt
                )
            }
            "ringing" -> FinishedCall(
                callId = id(state.ringedAt, state.number),
                number = state.number,
                callType = "missed",
                durationSeconds = 0,
                answered = false,
                at = state.ringedAt
            )
            else -> null
        }
    }

    /**
     * Replaces the timer guess with what the phone's call log says. Returns [call] unchanged when there is no
     * matching entry (permission denied, or the log row has not been written yet).
     */
    fun reconcile(call: FinishedCall, entry: CallLogReader.Entry?): FinishedCall {
        if (entry == null) return call
        val number = entry.number.ifBlank { call.number }
        return when {
            entry.isMissedIncoming -> call.copy(number = number, callType = "missed", durationSeconds = 0, answered = false, at = entry.dateMillis)
            entry.isOutgoing -> call.copy(
                number = number, callType = "outgoing", durationSeconds = entry.durationSeconds,
                answered = entry.durationSeconds > 0, at = entry.dateMillis
            )
            entry.isIncoming -> call.copy(number = number, callType = "incoming", durationSeconds = entry.durationSeconds, answered = true, at = entry.dateMillis)
            else -> call
        }
    }

    /** Stable across retries and across the timer-vs-call-log difference in start time (bucketed to the minute). */
    fun id(startMillis: Long, number: String): String = "${startMillis / 60000}-${Format.phoneKey(number)}"

    // ---- last finished call, for the post-call sheet ---------------------------------------

    fun saveLastCall(call: FinishedCall) = AppConfig.putString(PREF_LAST_CALL, gson.toJson(call))

    fun lastCall(): FinishedCall? = try {
        gson.fromJson(AppConfig.getString(PREF_LAST_CALL), FinishedCall::class.java)
    } catch (e: Exception) { null }

    fun clearLastCall() = AppConfig.putString(PREF_LAST_CALL, "")
}
