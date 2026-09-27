package co.tripcosmos.salesagents.telephony

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast

/** Places calls through the phone's own SIM and opens WhatsApp. */
object DialerManager {

    /**
     * Calls [rawPhone] on the carrier SIM. The number is remembered first: Android does not tell a
     * receiver which number an outgoing call went to, so without this the call could not be logged.
     */
    fun call(context: Context, rawPhone: String) {
        val clean = rawPhone.replace(Regex("[^0-9+]"), "")
        if (clean.isBlank()) {
            Toast.makeText(context, "That phone number is not valid", Toast.LENGTH_SHORT).show()
            return
        }
        CallTracker.noteOutgoing(clean)
        val uri = Uri.parse("tel:$clean")
        try {
            context.startActivity(Intent(Intent.ACTION_CALL, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: SecurityException) {
            // CALL_PHONE not granted: open the dialer with the number filled in; the agent taps call.
            context.startActivity(Intent(Intent.ACTION_DIAL, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: Exception) {
            Toast.makeText(context, "Could not start the call: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    /** Opens the WhatsApp app itself (used when the agent prefers it over the in-app thread). */
    fun openWhatsApp(context: Context, rawPhone: String, prefill: String = "") {
        val digits = rawPhone.filter { it.isDigit() }
        val number = if (digits.length == 10) "91$digits" else digits
        val url = "https://wa.me/$number" + if (prefill.isNotBlank()) "?text=" + Uri.encode(prefill) else ""
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: Exception) {
            Toast.makeText(context, "WhatsApp is not installed", Toast.LENGTH_SHORT).show()
        }
    }

    fun sms(context: Context, rawPhone: String, body: String = "") {
        val uri = Uri.parse("smsto:${rawPhone.replace(Regex("[^0-9+]"), "")}")
        try {
            context.startActivity(Intent(Intent.ACTION_SENDTO, uri).putExtra("sms_body", body).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: Exception) {
            Toast.makeText(context, "No SMS app found", Toast.LENGTH_SHORT).show()
        }
    }
}
