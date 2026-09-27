package co.tripcosmos.salesagents.updater

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

data class GitHubReleaseInfo(
    val tagName: String,
    val name: String,
    val body: String,
    val downloadUrl: String,
    val isNewer: Boolean
)

/**
 * Checks the plugin's GitHub repo for a newer signed release APK and hands the user to it. The repo also
 * publishes the WordPress plugin under plain `vX.Y.Z` tags, so app releases use their own `app-vX.Y.Z`
 * prefix — never compared against a plugin tag by mistake.
 */
object GitHubUpdateManager {
    val CURRENT_VERSION: String = "v${co.tripcosmos.salesagents.BuildConfig.VERSION_NAME}"

    const val GITHUB_REPO = "tripcosmosco/agents"
    const val APP_TAG_PREFIX = "app-v"
    const val API_URL = "https://api.github.com/repos/$GITHUB_REPO/releases?per_page=20"
    const val FALLBACK_DOWNLOAD_URL = "https://tripcosmos.co/downloads/tripcosmos-agents.apk"

    /** Null when the release server cannot be reached or no app release has been published. */
    suspend fun checkLatestRelease(): GitHubReleaseInfo? {
        return withContext(Dispatchers.IO) {
            try {
                val conn = URL(API_URL).openConnection() as HttpURLConnection
                conn.requestMethod = "GET"
                conn.setRequestProperty("User-Agent", "TripcosmosAgents-Android")
                conn.setRequestProperty("Accept", "application/vnd.github+json")
                conn.connectTimeout = 8000
                conn.readTimeout = 8000
                try {
                    if (conn.responseCode != 200) return@withContext null
                    parseLatestAppRelease(conn.inputStream.bufferedReader().use { it.readText() })
                } finally {
                    conn.disconnect()
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    /** The newest `app-vX.Y.Z` release in a GitHub releases-list response, or null. */
    internal fun parseLatestAppRelease(responseBody: String): GitHubReleaseInfo? {
        return try {
            val releases = JSONArray(responseBody)
            var best: JSONObject? = null
            for (i in 0 until releases.length()) {
                val r = releases.optJSONObject(i) ?: continue
                if (r.optBoolean("draft", false)) continue
                val tag = r.optString("tag_name", "")
                if (!tag.startsWith(APP_TAG_PREFIX)) continue
                if (best == null || compareVersions(tag, best.optString("tag_name", "")) > 0) best = r
            }
            val r = best ?: return null
            val tag = r.optString("tag_name", "")
            val url = getZipUrl(jsonToRelease(r)) ?: FALLBACK_DOWNLOAD_URL
            GitHubReleaseInfo(
                tagName = tag,
                name = r.optString("name", tag),
                body = r.optString("body", ""),
                downloadUrl = url,
                isNewer = compareVersions(tag, CURRENT_VERSION) > 0
            )
        } catch (e: Exception) {
            null
        }
    }

    private fun jsonToRelease(r: JSONObject): Map<String, Any?> {
        val assets = mutableListOf<Map<String, String>>()
        val arr = r.optJSONArray("assets")
        if (arr != null) {
            for (i in 0 until arr.length()) {
                val a = arr.optJSONObject(i) ?: continue
                assets += mapOf("name" to a.optString("name", ""), "browser_download_url" to a.optString("browser_download_url", ""))
            }
        }
        return mapOf("assets" to assets, "zipball_url" to r.optString("zipball_url", ""))
    }

    /**
     * A `.zip`/`.apk` asset's own download URL is preferred (a real release artifact); otherwise falls
     * back to the source `zipball_url`. Only `https://github.com/...` or `https://api.github.com/...`
     * is ever accepted — this is a hostile-update guard, not a formatting nicety: a compromised or
     * spoofed host must never be returned as an install source.
     */
    fun getZipUrl(release: Map<String, Any?>): String? {
        @Suppress("UNCHECKED_CAST")
        val assets = release["assets"] as? List<Map<String, String>> ?: emptyList()
        val asset = assets.firstOrNull { (it["name"] ?: "").let { n -> n.endsWith(".zip") || n.endsWith(".apk") } }
        val assetUrl = asset?.get("browser_download_url")
        if (!assetUrl.isNullOrBlank() && isTrustedGithubUrl(assetUrl)) return assetUrl

        val zipball = release["zipball_url"] as? String
        if (!zipball.isNullOrBlank() && isTrustedGithubUrl(zipball)) return zipball

        return null
    }

    private fun isTrustedGithubUrl(url: String): Boolean {
        if (!url.startsWith("https://")) return false
        // java.net.URI, not android.net.Uri: this class is also exercised by plain-JVM unit tests,
        // where the Android framework's own classes are stubs and throw.
        val host = try { java.net.URI(url).host } catch (e: Exception) { null } ?: return false
        return host == "github.com" || host == "api.github.com"
    }

    /**
     * Compares "vX.Y.Z" / "app-vX.Y.Z" tags numerically, segment by segment (so v2.10.0 > v2.9.0, unlike a
     * plain string compare). A missing trailing segment counts as 0 (v2.0 == v2.0.0).
     */
    fun compareVersions(a: String, b: String): Int {
        val na = normalize(a)
        val nb = normalize(b)
        val len = maxOf(na.size, nb.size)
        for (i in 0 until len) {
            val x = na.getOrElse(i) { 0 }
            val y = nb.getOrElse(i) { 0 }
            if (x != y) return x.compareTo(y)
        }
        return 0
    }

    private fun normalize(tag: String): List<Int> {
        var s = tag.trim()
        if (s.startsWith(APP_TAG_PREFIX)) s = s.removePrefix(APP_TAG_PREFIX)
        else if (s.startsWith("v")) s = s.removePrefix("v")
        return s.split(".").map { it.takeWhile(Char::isDigit).toIntOrNull() ?: 0 }
    }

    fun openDownload(context: Context, url: String) {
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: Exception) {
            // Nothing sensible to fall back to; the caller shows the raw URL.
        }
    }
}
