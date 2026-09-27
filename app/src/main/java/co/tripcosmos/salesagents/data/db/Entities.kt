package co.tripcosmos.salesagents.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * One cached API response, stored as the JSON the server sent. This is what lets the app show the
 * last-known leads, tasks and trips when there is no signal, instead of an empty screen.
 */
@Entity(tableName = "cache")
data class CacheEntry(
    @PrimaryKey val key: String,
    val json: String,
    val savedAt: Long = System.currentTimeMillis()
)
