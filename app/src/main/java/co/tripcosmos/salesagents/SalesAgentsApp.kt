package co.tripcosmos.salesagents

import android.app.Application
import co.tripcosmos.salesagents.data.db.AppDatabase
import co.tripcosmos.salesagents.data.repo.Repository
import co.tripcosmos.salesagents.data.sync.CallLogSync
import co.tripcosmos.salesagents.notify.Notifier
import co.tripcosmos.salesagents.notify.SyncWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class SalesAgentsApp : Application() {

    companion object {
        /** Kept for the caller-ID overlay service, which posts its foreground notification on this channel. */
        const val CALLER_ID_CHANNEL_ID = Notifier.CH_CALLER_ID

        lateinit var instance: SalesAgentsApp
            private set
    }

    /** One repository for the whole process (the UI and the background worker share the same cache). */
    val repository: Repository by lazy { Repository(AppDatabase.getDatabase(this).cacheDao()) }

    override fun onCreate() {
        super.onCreate()
        instance = this
        AppConfig.init(this)
        Notifier.createChannels(this)
        CoroutineScope(Dispatchers.IO).launch {
            CallLogSync.flush(AppConfig.baseUrl())
            repository.trimCache()
        }
        if (AppConfig.isPaired()) SyncWorker.schedule(this)
    }
}
