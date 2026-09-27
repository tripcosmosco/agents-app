package co.tripcosmos.salesagents.notify

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import co.tripcosmos.salesagents.R
import co.tripcosmos.salesagents.ui.MainActivity

/** All notification channels and a single place that builds the "tap to open this lead" intents. */
object Notifier {

    const val CH_CALLER_ID = "tc_caller_id_channel"
    const val CH_CALLS = "tc_calls"
    const val CH_LEADS = "tc_new_leads"
    const val CH_MESSAGES = "tc_messages"
    const val CH_TASKS = "tc_tasks"

    /** Extras understood by MainActivity to deep-link from a notification. */
    const val EXTRA_OPEN = "tc_open"          // "lead" | "tasks" | "postcall" | "inbox"
    const val EXTRA_LEAD_ID = "tc_lead_id"

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        fun ch(id: String, name: String, desc: String, importance: Int) =
            nm.createNotificationChannel(NotificationChannel(id, name, importance).apply { description = desc })
        ch(CH_CALLER_ID, "Caller ID", "Shows who is calling while a call rings", NotificationManager.IMPORTANCE_LOW)
        ch(CH_CALLS, "Finished calls", "Prompts you to add notes after a call", NotificationManager.IMPORTANCE_DEFAULT)
        ch(CH_LEADS, "New leads", "A new enquiry has arrived", NotificationManager.IMPORTANCE_HIGH)
        ch(CH_MESSAGES, "Customer replies", "A customer replied on WhatsApp", NotificationManager.IMPORTANCE_HIGH)
        ch(CH_TASKS, "Follow-up reminders", "A follow-up is due", NotificationManager.IMPORTANCE_DEFAULT)
    }

    fun canPost(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return false
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    fun openIntent(context: Context, open: String, leadId: Long = 0, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_OPEN, open)
            putExtra(EXTRA_LEAD_ID, leadId)
        }
        return PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    /** Posts a notification if the user allows it. [id] should be stable per subject so updates replace, not stack. */
    fun post(context: Context, channel: String, id: Int, title: String, text: String, tap: PendingIntent) {
        if (!canPost(context)) return
        val n = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setContentIntent(tap)
            .setAutoCancel(true)
            .setPriority(if (channel == CH_LEADS || channel == CH_MESSAGES) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(id, n)
        } catch (e: SecurityException) {
            // Permission revoked between the check and the call; nothing to do.
        }
    }
}
