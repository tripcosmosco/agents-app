package co.tripcosmos.salesagents

import android.app.Application
import co.tripcosmos.salesagents.data.db.AppDatabase
import co.tripcosmos.salesagents.data.repo.Repository
import co.tripcosmos.salesagents.data.sync.CallLogSync
import co.tripcosmos.salesagents.notify.Notifier
import co.tripcosmos.salesagents.notify.SyncWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class SalesAgentsApp : Application() {

    companion object {
        lateinit var instance: SalesAgentsApp
            private set
    }

    /** One repository for the whole process (the UI and the background worker share the same cache). */
    val repository: Repository by lazy { Repository(AppDatabase.getDatabase(this).cacheDao()) }

    /** For work that must outlive the screen that started it (sign-out cleanup, push-token upload). */
    val appScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        instance = this
        AppConfig.init(this)
        Notifier.createChannels(this)
        appScope.launch {
            CallLogSync.flush(AppConfig.baseUrl())
            repository.trimCache()
        }
        if (AppConfig.isPaired()) SyncWorker.schedule(this)
    }
}
