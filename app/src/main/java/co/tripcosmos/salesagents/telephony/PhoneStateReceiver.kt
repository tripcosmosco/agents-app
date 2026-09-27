package co.tripcosmos.salesagents.telephony

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.telephony.TelephonyManager
import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.data.api.ApiClient
import co.tripcosmos.salesagents.data.model.CallLogPayload
import co.tripcosmos.salesagents.data.sync.CallLogSync
import co.tripcosmos.salesagents.notify.Notifier
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Watches carrier calls: shows the caller's CRM card while an unknown-or-known number rings, and when the
 * call ends logs it to the CRM and prompts the agent for notes.
 *
 * The decision logic is in [CallTracker]; this class only wires Android broadcasts to it.
 */
class PhoneStateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        if (!AppConfig.isPaired()) return

        val phase = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        // Only delivered when READ_CALL_LOG is granted; blank otherwise.
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER).orEmpty()
        val now = System.currentTimeMillis()
        val state = CallTracker.load()

        when (phase) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                val next = CallTracker.onRinging(state, number, now)
                CallTracker.save(next)
                if (next.number.isNotBlank()) showCallerCard(context, next.number)
            }

            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                CallTracker.save(CallTracker.onOffHook(state, CallTracker.pendingOutgoing(now), now))
            }

            TelephonyManager.EXTRA_STATE_IDLE -> {
                val finished = CallTracker.onIdle(state, now) ?: return
                CallTracker.save(CallState())
                CallerIdOverlayService.hideOverlay(context)
                finish(context, finished, state)
            }
        }
    }

    /** Waits briefly for the phone to write its call-log row, then logs the call with the corrected values. */
    private fun finish(context: Context, guess: FinishedCall, state: CallState) {
        val app = context.applicationContext
        val pending = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                delay(CALL_LOG_SETTLE_MS)
                val since = minOf(state.startedAt.takeIf { it > 0 } ?: Long.MAX_VALUE, state.ringedAt.takeIf { it > 0 } ?: Long.MAX_VALUE)
                    .let { if (it == Long.MAX_VALUE) guess.at else it } - 30_000
                val key = Format.phoneKey(guess.number).ifBlank { null }
                val call = CallTracker.reconcile(guess, CallLogReader.latest(app, since, key))
                CallTracker.clearPendingOutgoing()

                if (call.number.isBlank()) return@launch // nothing to attribute the call to

                CallLogSync.send(
                    AppConfig.baseUrl(),
                    CallLogPayload(
                        phone = call.number,
                        callType = call.callType,
                        durationSeconds = call.durationSeconds.toLong(),
                        notes = call.note,
                        callId = call.callId
                    )
                )
                CallTracker.saveLastCall(call)
                notifyCallEnded(app, call)
            } finally {
                pending.finish()
            }
        }
    }

    private suspend fun notifyCallEnded(context: Context, call: FinishedCall) {
        val name = try {
            ApiClient.get().callerId(call.number).body()?.contact?.name
        } catch (e: Exception) { null }
        val who = name?.takeIf { it.isNotBlank() } ?: Format.phone(call.number)
        val what = when {
            call.callType == "missed" -> "Missed call from $who"
            !call.answered -> "$who did not answer"
            else -> "Call with $who · ${Format.duration(call.durationSeconds).ifBlank { "0s" }}"
        }
        Notifier.post(
            context, Notifier.CH_CALLS, POST_CALL_NOTIFICATION_ID,
            title = what,
            text = "Tap to add notes and set a follow-up",
            tap = Notifier.openIntent(context, "postcall", requestCode = POST_CALL_NOTIFICATION_ID)
        )
    }

    private fun showCallerCard(context: Context, number: String) {
        val app = context.applicationContext
        CoroutineScope(Dispatchers.IO).launch {
            try {
                if (!Settings.canDrawOverlays(app)) return@launch
                val contact = ApiClient.get().callerId(number).body()?.takeIf { it.found }?.contact ?: return@launch
                CallerIdOverlayService.showOverlay(
                    context = app,
                    name = contact.name,
                    phone = contact.phone,
                    dealValue = contact.dealValue,
                    stage = contact.stage,
                    destination = contact.destination.orEmpty(),
                    aiSummary = contact.aiSummary.orEmpty(),
                    nextAction = contact.nextBestAction.orEmpty()
                )
            } catch (e: Exception) {
                // Caller card is best-effort; a failed lookup must never disturb the call.
            }
        }
    }

    companion object {
        const val POST_CALL_NOTIFICATION_ID = 7001
        private const val CALL_LOG_SETTLE_MS = 1500L
    }
}
