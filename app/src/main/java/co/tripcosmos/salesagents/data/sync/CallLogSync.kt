package co.tripcosmos.salesagents.data.sync

import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.data.api.ApiClient
import co.tripcosmos.salesagents.data.model.CallLogPayload
import com.google.gson.Gson
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Sends call logs to the server and keeps any that could not be delivered (offline, server down,
 * device not paired yet) in an encrypted queue that is retried on the next call and at app start.
 */
object CallLogSync {

    private const val MAX_PENDING = 200
    private val gson = Gson()
    private val lock = Mutex()

    suspend fun send(baseUrl: String, payload: CallLogPayload) {
        lock.withLock {
            val pending = readQueue().toMutableList()
            pending.add(payload)
            writeQueue(drain(baseUrl, pending))
        }
    }

    /** Retries everything that is waiting. Safe to call whenever the app starts. */
    suspend fun flush(baseUrl: String) {
        lock.withLock {
            val pending = readQueue()
            if (pending.isEmpty() || !AppConfig.isPaired()) return
            writeQueue(drain(baseUrl, pending))
        }
    }

    private suspend fun drain(baseUrl: String, items: List<CallLogPayload>): List<CallLogPayload> {
        val remaining = mutableListOf<CallLogPayload>()
        for (item in items) {
            if (!deliver(baseUrl, item)) remaining.add(item)
        }
        return remaining.takeLast(MAX_PENDING)
    }

    /** True when the item is finished (delivered, or rejected in a way a retry cannot fix). */
    private suspend fun deliver(baseUrl: String, payload: CallLogPayload): Boolean {
        return try {
            val response = ApiClient.get(baseUrl).logCall(payload)
            when {
                response.isSuccessful -> true
                response.code() == 400 || response.code() == 404 || response.code() == 422 -> true
                else -> false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun readQueue(): List<CallLogPayload> {
        val json = AppConfig.pendingCalls()
        if (json.isBlank()) return emptyList()
        return try {
            gson.fromJson(json, Array<CallLogPayload>::class.java)?.toList().orEmpty()
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun writeQueue(items: List<CallLogPayload>) {
        AppConfig.setPendingCalls(if (items.isEmpty()) "" else gson.toJson(items))
    }
}
