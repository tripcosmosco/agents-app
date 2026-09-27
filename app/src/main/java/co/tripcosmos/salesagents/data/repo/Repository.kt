package co.tripcosmos.salesagents.data.repo

import co.tripcosmos.salesagents.data.api.ApiClient
import co.tripcosmos.salesagents.data.api.TripCosmosApiService
import co.tripcosmos.salesagents.data.db.CacheDao
import co.tripcosmos.salesagents.data.db.CacheEntry
import co.tripcosmos.salesagents.data.model.*
import com.google.gson.Gson
import com.google.gson.JsonParser
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import retrofit2.Response
import java.io.IOException

/** Outcome of a server call. Screens show [Err.message] verbatim: it is written for the agent. */
sealed class Res<out T> {
    data class Ok<T>(val data: T) : Res<T>()
    data class Err(val message: String, val kind: Kind = Kind.SERVER) : Res<Nothing>()

    enum class Kind { NETWORK, AUTH, VALIDATION, SERVER }
}

inline fun <T, R> Res<T>.fold(ok: (T) -> R, err: (Res.Err) -> R): R = when (this) {
    is Res.Ok -> ok(data)
    is Res.Err -> err(this)
}

/**
 * The only place that talks to the server. It turns HTTP/network failures into readable errors,
 * announces rejected tokens so the UI can send the agent back to pairing, and keeps the last good
 * response of each list so screens can show something useful offline.
 */
class Repository(
    private val cache: CacheDao,
    private val apiProvider: () -> TripCosmosApiService = { ApiClient.get() },
    private val gson: Gson = Gson()
) {
    private val _authFailed = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val authFailed: SharedFlow<Unit> = _authFailed

    private val api get() = apiProvider()

    // ---- plumbing ----------------------------------------------------------------------------

    private suspend fun <T : ApiResult> exec(cacheKey: String? = null, call: suspend () -> Response<T>): Res<T> {
        return try {
            val response = call()
            val body = response.body()
            when {
                response.isSuccessful && body != null && body.ok -> {
                    if (cacheKey != null) cache.put(CacheEntry(cacheKey, gson.toJson(body)))
                    Res.Ok(body)
                }
                response.code() == 401 || response.code() == 403 -> {
                    _authFailed.tryEmit(Unit)
                    Res.Err("This device's access token was rejected. Pair it again in Settings.", Res.Kind.AUTH)
                }
                else -> Res.Err(errorMessage(response, body), if (response.code() in 400..499) Res.Kind.VALIDATION else Res.Kind.SERVER)
            }
        } catch (e: IOException) {
            Res.Err("No connection. Check your internet and try again.", Res.Kind.NETWORK)
        } catch (e: Exception) {
            Res.Err("Something went wrong (${e.javaClass.simpleName}). Try again.", Res.Kind.SERVER)
        }
    }

    internal fun <T : ApiResult> errorMessage(response: Response<T>, body: T?): String {
        body?.error?.takeIf { it.isNotBlank() }?.let { return it }
        val raw = try { response.errorBody()?.string().orEmpty() } catch (e: Exception) { "" }
        if (raw.isNotBlank()) {
            try {
                val obj = JsonParser.parseString(raw).asJsonObject
                // Our own errors use "error"; WordPress core errors use "message".
                for (k in listOf("error", "message")) {
                    if (obj.has(k) && obj.get(k).isJsonPrimitive) return obj.get(k).asString
                }
            } catch (_: Exception) { /* not JSON */ }
        }
        return "The server could not complete this (HTTP ${response.code()})."
    }

    /** Last good response for [key], or null. */
    suspend fun <T> cached(key: String, type: Class<T>): T? {
        val row = cache.get(key) ?: return null
        return try { gson.fromJson(row.json, type) } catch (e: Exception) { null }
    }

    suspend fun clearCache() = cache.clear()

    suspend fun trimCache() = cache.deleteOlderThan(System.currentTimeMillis() - 14L * 24 * 3600 * 1000)

    // ---- identity + dashboard ------------------------------------------------------------------

    suspend fun me() = exec("me") { api.me() }
    suspend fun dashboard() = exec("dashboard") { api.dashboard() }
    suspend fun cachedDashboard() = cached("dashboard", DashboardResponse::class.java)
    suspend fun cachedMe() = cached("me", MeResponse::class.java)

    suspend fun notifications(sinceLead: Long, sinceMsg: Long) = exec { api.notifications(sinceLead, sinceMsg) }

    // ---- leads -----------------------------------------------------------------------------------

    /** Only the unfiltered first page is cached (that is what the agent sees on opening the tab). */
    suspend fun leads(stage: String?, owner: String?, query: String?, sort: String?, offset: Int, limit: Int = 30): Res<LeadListResponse> {
        val plain = (stage.isNullOrBlank() || stage == "all") && owner.isNullOrBlank() && query.isNullOrBlank() && offset == 0
        return exec(if (plain) "leads:first" else null) {
            api.leads(stage.takeUnless { it == "all" }, owner?.takeIf { it.isNotBlank() && it != "all" }, query?.takeIf { it.isNotBlank() }, sort, limit, offset)
        }
    }

    suspend fun cachedLeads() = cached("leads:first", LeadListResponse::class.java)

    suspend fun lead(id: Long) = exec("lead:$id") { api.lead(id) }
    suspend fun cachedLead(id: Long) = cached("lead:$id", LeadDetailResponse::class.java)

    suspend fun createLead(body: CreateLeadBody) = exec { api.createLead(body) }
    suspend fun summarize(id: Long, body: SummarizeBody) = exec { api.summarize(id, body) }
    suspend fun setStage(id: Long, stage: String) = exec { api.updateLead(UpdateLeadBody(id, stage = stage)) }
    suspend fun addNote(id: Long, note: String) = exec { api.updateLead(UpdateLeadBody(id, note = note)) }
    suspend fun assign(id: Long, manager: String, notify: Boolean) = exec { api.assignLead(AssignLeadBody(id, manager, notify)) }

    // ---- tasks -----------------------------------------------------------------------------------

    suspend fun tasks(filter: String, leadId: Long? = null) =
        exec(if (leadId == null) "tasks:$filter" else null) { api.tasks(filter, leadId) }

    suspend fun cachedTasks(filter: String) = cached("tasks:$filter", TaskListResponse::class.java)
    suspend fun createTask(leadId: Long, content: String, dueAtIso: String) = exec { api.createTask(CreateTaskBody(leadId, content, dueAtIso)) }
    suspend fun completeTask(id: Long) = exec { api.completeTask(id) }

    // ---- trips -----------------------------------------------------------------------------------

    suspend fun bookings(status: String? = null) = exec("bookings:${status.orEmpty()}") { api.bookings(null, status?.takeIf { it.isNotBlank() && it != "all" }) }
    suspend fun cachedBookings(status: String? = null) = cached("bookings:${status.orEmpty()}", BookingListResponse::class.java)
    suspend fun saveBooking(body: SaveBookingBody) = exec { api.saveBooking(body) }
    suspend fun createQuote(body: CreateQuoteBody) = exec { api.createQuote(body) }
    suspend fun sendQuote(quoteId: Long) = exec { api.sendQuote(quoteId) }
    suspend fun paymentLink(bookingId: Long, amount: Double, purpose: String) = exec { api.paymentLink(PaymentLinkBody(bookingId, amount, purpose)) }
    suspend fun recordPayment(bookingId: Long, amount: Double, method: String, reference: String) =
        exec { api.recordPayment(RecordPaymentBody(bookingId, amount, method, reference)) }
    suspend fun sendDispatch(body: DispatchBody) = exec { api.sendDispatch(body) }

    // ---- WhatsApp --------------------------------------------------------------------------------

    suspend fun inbox() = exec("inbox") { api.inbox() }
    suspend fun cachedInbox() = cached("inbox", InboxResponse::class.java)
    suspend fun conversation(leadId: Long) = exec("chat:$leadId") { api.conversation(leadId) }
    suspend fun cachedConversation(leadId: Long) = cached("chat:$leadId", ConversationResponse::class.java)
    suspend fun reply(leadId: Long, text: String) = exec { api.reply(leadId, ReplyBody(text)) }
    suspend fun setAi(leadId: Long, enabled: Boolean) = exec { api.setAi(leadId, AiToggleBody(enabled)) }
    suspend fun quickAction(phone: String, action: String) = exec { api.quickAction(QuickActionBody(phone, action)) }

    // ---- calls -----------------------------------------------------------------------------------

    suspend fun calls(limit: Int = 50) = exec("calls") { api.calls(limit) }
    suspend fun cachedCalls() = cached("calls", CallListResponse::class.java)
    suspend fun callerId(phone: String) = exec { api.callerId(phone) }
}
