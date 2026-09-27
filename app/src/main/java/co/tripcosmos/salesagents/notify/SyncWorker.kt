package co.tripcosmos.salesagents.notify

import android.content.Context
import androidx.work.*
import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.NotificationsResponse
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.data.sync.CallLogSync
import co.tripcosmos.salesagents.util.Format
import java.util.concurrent.TimeUnit

/**
 * Every ~15 minutes (Android's minimum for background work) asks the server what is new and turns it into
 * notifications: new leads, customer replies and follow-ups that are due. It also retries call logs that
 * could not be delivered while the phone was offline.
 *
 * Cursors are stored so each lead / message is announced once. The very first run only records them, so
 * installing the app never floods the phone with history.
 */
class SyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        if (!AppConfig.isPaired()) return Result.success()
        CallLogSync.flush(AppConfig.baseUrl())

        val repo = SalesAgentsApp.instance.repository
        return when (val res = repo.notifications(AppConfig.getLong(KEY_LEAD), AppConfig.getLong(KEY_MSG))) {
            is Res.Ok -> { announce(applicationContext, res.data); Result.success() }
            is Res.Err -> if (res.kind == Res.Kind.NETWORK) Result.retry() else Result.success()
        }
    }

    companion object {
        private const val WORK_NAME = "tc_sync"
        const val KEY_LEAD = "notif_cursor_lead"
        const val KEY_MSG = "notif_cursor_msg"
        private const val KEY_NOTIFIED_TASKS = "notif_tasks_seen"
        const val PREF_LEADS = "notif_leads_on"
        const val PREF_MESSAGES = "notif_messages_on"
        const val PREF_TASKS = "notif_tasks_on"
        private const val MAX_INDIVIDUAL = 4

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.UPDATE, request)
        }

        fun cancel(context: Context) = WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)

        /** Records the server's latest ids without notifying (used when the agent is already looking at the app). */
        fun advanceCursors(response: NotificationsResponse) {
            AppConfig.putLong(KEY_LEAD, maxOf(AppConfig.getLong(KEY_LEAD), response.latestLead))
            AppConfig.putLong(KEY_MSG, maxOf(AppConfig.getLong(KEY_MSG), response.latestMsg))
        }

        /** Task ids in [current] that have not been announced yet. */
        internal fun unannounced(current: List<Long>, announced: Set<Long>): List<Long> = current.filter { it !in announced }

        private fun announce(context: Context, r: NotificationsResponse) {
            val firstRun = AppConfig.getLong(KEY_LEAD) == 0L && AppConfig.getLong(KEY_MSG) == 0L
            advanceCursors(r)
            if (firstRun) {
                // Remember what is already due so it is not announced as new next time.
                rememberTasks(r.tasksDue.map { it.id })
                return
            }

            if (AppConfig.getBool(PREF_LEADS, true)) {
                r.newLeads.take(MAX_INDIVIDUAL).forEach { l ->
                    val detail = listOf(Format.phone(l.phone), l.destination, l.source.replace('_', ' ')).filter { it.isNotBlank() }.joinToString(" · ")
                    Notifier.post(context, Notifier.CH_LEADS, 10_000 + l.id.toInt(), "New lead: ${l.name}", detail,
                        Notifier.openIntent(context, "lead", l.id, 10_000 + l.id.toInt()))
                }
                if (r.newLeads.size > MAX_INDIVIDUAL) {
                    Notifier.post(context, Notifier.CH_LEADS, 9_999, "${r.newLeads.size} new leads", "Open the app to see them",
                        Notifier.openIntent(context, "leads", requestCode = 9_999))
                }
            }

            if (AppConfig.getBool(PREF_MESSAGES, true)) {
                // One notification per customer: the newest reply replaces the older one.
                r.replies.groupBy { it.leadId }.forEach { (leadId, msgs) ->
                    val last = msgs.last()
                    Notifier.post(context, Notifier.CH_MESSAGES, 20_000 + leadId.toInt(), "${last.name} replied", last.text,
                        Notifier.openIntent(context, "lead", leadId, 20_000 + leadId.toInt()))
                }
            }

            if (AppConfig.getBool(PREF_TASKS, true)) {
                val fresh = unannounced(r.tasksDue.map { it.id }, announcedTasks())
                val byId = r.tasksDue.associateBy { it.id }
                fresh.take(MAX_INDIVIDUAL).forEach { id ->
                    val t = byId.getValue(id)
                    Notifier.post(context, Notifier.CH_TASKS, 30_000 + id.toInt(), "Follow-up due: ${t.name}", t.text,
                        Notifier.openIntent(context, "tasks", t.leadId, 30_000 + id.toInt()))
                }
                if (fresh.size > MAX_INDIVIDUAL) {
                    Notifier.post(context, Notifier.CH_TASKS, 29_999, "${fresh.size} follow-ups due", "Open Tasks to work through them",
                        Notifier.openIntent(context, "tasks", requestCode = 29_999))
                }
                rememberTasks(r.tasksDue.map { it.id })
            }
        }

        private fun announcedTasks(): Set<Long> =
            AppConfig.getString(KEY_NOTIFIED_TASKS).split(',').mapNotNull { it.toLongOrNull() }.toSet()

        /** Keeps only ids still due, so the list cannot grow without bound. */
        private fun rememberTasks(currentlyDue: List<Long>) =
            AppConfig.putString(KEY_NOTIFIED_TASKS, currentlyDue.joinToString(","))
    }
}
