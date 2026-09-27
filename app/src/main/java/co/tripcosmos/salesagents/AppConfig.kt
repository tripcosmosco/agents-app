package co.tripcosmos.salesagents

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * App settings. The API token lives in encrypted storage; everything else (server URL, notification
 * cursors, the last finished call) is non-secret and lives in ordinary preferences.
 *
 * There is no built-in default token: the agent pastes one generated in WordPress
 * (TripCosmos Agents > Integrations > Mobile App Access).
 */
object AppConfig {

    const val DEFAULT_BASE_URL = "https://tripcosmos.co/wp-json/tc-agents/v1/"

    private const val PLAIN_PREFS = "tc_agents_prefs"
    private const val SECURE_PREFS = "tc_agents_secure"
    private const val KEY_TOKEN = "mobile_api_token"
    private const val KEY_PENDING_CALLS = "pending_call_logs"
    private const val KEY_BASE_URL = "base_url"
    private const val KEY_AGENT = "agent_name"
    private val REJECTED_LEGACY_TOKENS = setOf("tc_mobile_secret_2026", "test")

    private var appContext: Context? = null
    private val secure: SharedPreferences by lazy { openSecurePrefs() }
    private val plain: SharedPreferences by lazy { context().getSharedPreferences(PLAIN_PREFS, Context.MODE_PRIVATE) }

    fun init(context: Context) {
        appContext = context.applicationContext
        migrateLegacyToken()
    }

    // ---- pairing -------------------------------------------------------------------------

    fun token(): String {
        if (appContext == null) return ""
        return secure.getString(KEY_TOKEN, "").orEmpty()
    }

    fun setToken(value: String) {
        if (appContext == null) return
        secure.edit().putString(KEY_TOKEN, value.trim()).apply()
    }

    fun isPaired(): Boolean = token().isNotBlank()

    fun baseUrl(): String {
        if (appContext == null) return DEFAULT_BASE_URL
        return normalizeBaseUrl(plain.getString(KEY_BASE_URL, null))
    }

    fun setBaseUrl(value: String) {
        if (appContext == null) return
        plain.edit().putString(KEY_BASE_URL, normalizeBaseUrl(value)).apply()
    }

    /** Name the server reported for this token (e.g. "Santosh - Redmi"). */
    fun agentName(): String = if (appContext == null) "" else plain.getString(KEY_AGENT, "").orEmpty()

    fun setAgentName(value: String) {
        if (appContext == null) return
        plain.edit().putString(KEY_AGENT, value).apply()
    }

    /** Forget this device's credentials and cached identity. Cached CRM data is cleared by the caller. */
    fun signOut() {
        if (appContext == null) return
        secure.edit().remove(KEY_TOKEN).remove(KEY_PENDING_CALLS).apply()
        plain.edit().remove(KEY_AGENT).apply()
    }

    // ---- call log retry queue (encrypted: it holds customer phone numbers) ----------------

    fun pendingCalls(): String {
        if (appContext == null) return ""
        return secure.getString(KEY_PENDING_CALLS, "").orEmpty()
    }

    fun setPendingCalls(json: String) {
        if (appContext == null) return
        secure.edit().putString(KEY_PENDING_CALLS, json).apply()
    }

    // ---- small typed helpers over the plain prefs ------------------------------------------

    fun getLong(key: String, default: Long = 0L): Long = if (appContext == null) default else plain.getLong(key, default)
    fun putLong(key: String, value: Long) { if (appContext != null) plain.edit().putLong(key, value).apply() }
    fun getString(key: String, default: String = ""): String = if (appContext == null) default else plain.getString(key, default) ?: default
    fun putString(key: String, value: String) { if (appContext != null) plain.edit().putString(key, value).apply() }
    fun getBool(key: String, default: Boolean): Boolean = if (appContext == null) default else plain.getBoolean(key, default)
    fun putBool(key: String, value: Boolean) { if (appContext != null) plain.edit().putBoolean(key, value).apply() }

    // ---- internals ------------------------------------------------------------------------

    /** Ensures a scheme and a trailing slash so Retrofit accepts it. Blank falls back to production. */
    internal fun normalizeBaseUrl(raw: String?): String {
        val v = raw?.trim().orEmpty()
        if (v.isEmpty()) return DEFAULT_BASE_URL
        val withScheme = if (v.startsWith("http://") || v.startsWith("https://")) v else "https://$v"
        return if (withScheme.endsWith("/")) withScheme else "$withScheme/"
    }

    private fun context(): Context = checkNotNull(appContext) { "AppConfig.init() was not called" }

    private fun openSecurePrefs(): SharedPreferences {
        return try {
            createEncrypted()
        } catch (e: Exception) {
            // Keystore state can be corrupted after a restore; start clean rather than crash.
            context().deleteSharedPreferences(SECURE_PREFS)
            try {
                createEncrypted()
            } catch (e2: Exception) {
                context().getSharedPreferences("${SECURE_PREFS}_fallback", Context.MODE_PRIVATE)
            }
        }
    }

    private fun createEncrypted(): SharedPreferences {
        val ctx = context()
        val masterKey = MasterKey.Builder(ctx)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return EncryptedSharedPreferences.create(
            ctx,
            SECURE_PREFS,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    /** Moves a real token out of the old plain-text prefs and drops the old shared default. */
    private fun migrateLegacyToken() {
        val legacy = context().getSharedPreferences(PLAIN_PREFS, Context.MODE_PRIVATE)
        val old = legacy.getString(KEY_TOKEN, null) ?: return
        if (old.isNotBlank() && old !in REJECTED_LEGACY_TOKENS && secure.getString(KEY_TOKEN, "").isNullOrBlank()) {
            secure.edit().putString(KEY_TOKEN, old).apply()
        }
        legacy.edit().remove(KEY_TOKEN).apply()
    }
}
