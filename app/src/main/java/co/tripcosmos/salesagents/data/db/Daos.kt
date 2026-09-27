package co.tripcosmos.salesagents.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface CacheDao {
    @Query("SELECT * FROM cache WHERE `key` = :key LIMIT 1")
    suspend fun get(key: String): CacheEntry?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun put(entry: CacheEntry)

    @Query("DELETE FROM cache")
    suspend fun clear()

    /** Keeps the cache bounded: lead detail pages are the only unbounded keys. */
    @Query("DELETE FROM cache WHERE savedAt < :before")
    suspend fun deleteOlderThan(before: Long)
}
