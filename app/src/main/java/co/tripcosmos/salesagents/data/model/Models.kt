package co.tripcosmos.salesagents.data.model

import com.google.gson.JsonElement
import com.google.gson.annotations.SerializedName

/*
 * Wire models for the TripCosmos mobile API (api_level 2). Every field has a neutral default so a missing
 * key never crashes and never shows invented data: text is "", numbers are 0, lists are empty.
 * Times arrive as UTC ISO-8601 strings ("2026-09-27T05:30:00Z") and are parsed in Format.kt.
 */

/** Base for every response: the server always sends `ok`, and `error` on failures. */
interface ApiResult {
    val ok: Boolean
    val error: String?
}

data class Option(val id: String = "", val label: String = "")

data class TeamMember(val id: Long = 0, val name: String = "", val role: String = "")

data class Features(
    val cashfree: Boolean = false,
    val upi: Boolean = false,
    val gst: Boolean = false,
    val whatsapp: Boolean = false
)

data class MeResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val agent: String = "",
    @SerializedName("plugin_version") val pluginVersion: String = "",
    @SerializedName("api_level") val apiLevel: Int = 0,
    val stages: List<Option> = emptyList(),
    @SerializedName("booking_status") val bookingStatus: List<Option> = emptyList(),
    val team: List<TeamMember> = emptyList(),
    val features: Features = Features()
) : ApiResult

data class Lead(
    val id: Long = 0,
    val name: String = "",
    val phone: String = "",
    val email: String = "",
    val stage: String = "inquiry",
    val score: Int = 0,
    @SerializedName("deal_value") val dealValue: Double = 0.0,
    val owner: String = "",
    val source: String = "",
    val tags: List<String> = emptyList(),
    val destination: String = "",
    val pax: Int = 0,
    @SerializedName("travel_month") val travelMonth: String = "",
    val requirements: String = "",
    val intent: String = "",
    @SerializedName("next_follow_up_at") val nextFollowUpAt: String? = null,
    @SerializedName("last_contacted_at") val lastContactedAt: String? = null,
    @SerializedName("created_at") val createdAt: String? = null,
    @SerializedName("updated_at") val updatedAt: String? = null
)

data class LeadListResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val leads: List<Lead> = emptyList(),
    val total: Int = 0,
    @SerializedName("has_more") val hasMore: Boolean = false
) : ApiResult

data class Activity(
    val id: Long = 0,
    val type: String = "note",
    val content: String = "",
    val meta: JsonElement? = null,
    @SerializedName("due_at") val dueAt: String? = null,
    @SerializedName("done_at") val doneAt: String? = null,
    @SerializedName("created_at") val createdAt: String? = null
)

data class Memory(
    val summary: String = "",
    val facts: List<String> = emptyList(),
    val preferences: List<String> = emptyList(),
    val objections: List<String> = emptyList(),
    @SerializedName("next_best_action") val nextBestAction: String = ""
)

data class CanContact(val whatsapp: Boolean = true, val email: Boolean = true)

data class QuoteItem(
    @SerializedName("desc") val description: String = "",
    val qty: Double = 1.0,
    val price: Double = 0.0,
    val amount: Double = 0.0
)

data class QuoteInfo(
    val id: Long = 0,
    val version: Int = 1,
    val status: String = "draft",
    val total: Double = 0.0,
    @SerializedName("advance_amount") val advanceAmount: Double = 0.0,
    @SerializedName("valid_until") val validUntil: String? = null,
    val url: String = "",
    val items: List<QuoteItem> = emptyList()
)

data class Booking(
    val id: Long = 0,
    @SerializedName("lead_id") val leadId: Long = 0,
    val ref: String = "",
    val title: String = "",
    @SerializedName("start_date") val startDate: String? = null,
    @SerializedName("end_date") val endDate: String? = null,
    val pax: Int = 1,
    val vehicle: String = "",
    val driver: String = "",
    val status: String = "quoted",
    @SerializedName("quote_amount") val quoteAmount: Double = 0.0,
    @SerializedName("advance_paid") val advancePaid: Double = 0.0,
    val total: Double = 0.0,
    val balance: Double = 0.0,
    @SerializedName("advance_due") val advanceDue: Double = 0.0,
    val notes: String = "",
    val quote: QuoteInfo? = null,
    @SerializedName("updated_at") val updatedAt: String? = null
)

data class LeadDetailResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val lead: Lead = Lead(),
    val activities: List<Activity> = emptyList(),
    val tasks: List<Activity> = emptyList(),
    val bookings: List<Booking> = emptyList(),
    val memory: Memory? = null,
    @SerializedName("can_contact") val canContact: CanContact = CanContact()
) : ApiResult

data class Task(
    val id: Long = 0,
    val content: String = "",
    @SerializedName("due_at") val dueAt: String? = null,
    @SerializedName("done_at") val doneAt: String? = null,
    @SerializedName("created_at") val createdAt: String? = null,
    @SerializedName("lead_id") val leadId: Long = 0,
    val name: String = "",
    val phone: String = ""
)

data class TaskListResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val tasks: List<Task> = emptyList()
) : ApiResult

data class BookingListResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val bookings: List<Booking> = emptyList()
) : ApiResult

data class BookingResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val booking: Booking? = null,
    @SerializedName("quote_id") val quoteId: Long = 0
) : ApiResult

data class Today(
    @SerializedName("new_leads") val newLeads: Int = 0,
    val calls: Int = 0,
    @SerializedName("quotes_sent") val quotesSent: Int = 0,
    val bookings: Int = 0,
    @SerializedName("tasks_due") val tasksDue: Int = 0,
    @SerializedName("tasks_overdue") val tasksOverdue: Int = 0,
    val collected: Double = 0.0
)

data class Month(
    @SerializedName("new_leads") val newLeads: Int = 0,
    val won: Int = 0,
    val collected: Double = 0.0
)

data class PipelineStage(val stage: String = "", val count: Int = 0, val value: Double = 0.0)

data class DashboardResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val today: Today = Today(),
    val month: Month = Month(),
    val pipeline: List<PipelineStage> = emptyList(),
    val hot: List<Lead> = emptyList()
) : ApiResult

data class CallRecord(
    val id: Long = 0,
    @SerializedName("lead_id") val leadId: Long = 0,
    val name: String = "",
    val phone: String = "",
    val type: String = "",
    val duration: Int = 0,
    @SerializedName("recording_url") val recordingUrl: String = "",
    val note: String = "",
    val at: String? = null
)

data class CallListResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val calls: List<CallRecord> = emptyList()
) : ApiResult

data class ChatMessage(
    val id: Long = 0,
    /** "customer", "agent" or "ai". */
    val from: String = "customer",
    val text: String = "",
    /** Who on the team sent an agent message ("Santosh", "business phone"); "" otherwise. */
    val by: String = "",
    /** WhatsApp receipt for our messages: "", "sent", "delivered", "read" or "failed". */
    val delivery: String = "",
    val at: String? = null
)

data class ConversationResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val messages: List<ChatMessage> = emptyList(),
    val lead: Lead = Lead(),
    /** False once a person has taken over this customer; the AI then stays quiet. */
    @SerializedName("ai_enabled") val aiEnabled: Boolean = true
) : ApiResult

data class AiToggleBody(val enabled: Boolean)

data class AiToggleResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    @SerializedName("ai_enabled") val aiEnabled: Boolean = true
) : ApiResult

/** One row of the WhatsApp inbox (existing endpoint /mobile/whatsapp-leads). */
data class InboxItem(
    val id: String = "",
    @SerializedName("customer_name") val customerName: String = "",
    val phone: String = "",
    @SerializedName("last_message") val lastMessage: String = "",
    @SerializedName("time_ago") val timeAgo: String = "",
    @SerializedName("unread_count") val unreadCount: Int = 0,
    @SerializedName("tour_interest") val tourInterest: String = "",
    @SerializedName("estimated_budget") val estimatedBudget: Double = 0.0,
    @SerializedName("assigned_manager") val assignedManager: String? = null,
    @SerializedName("lead_score") val leadScore: Int = 0,
    val status: String = "new"
)

data class InboxResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val leads: List<InboxItem> = emptyList()
) : ApiResult

data class SummaryResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val summary: String = "",
    val facts: List<String> = emptyList(),
    val intent: String = "",
    @SerializedName("intent_reasons") val intentReasons: List<String> = emptyList(),
    @SerializedName("next_best_action") val nextBestAction: String = "",
    @SerializedName("task_id") val taskId: Long = 0,
    val lead: Lead = Lead()
) : ApiResult

data class CreateLeadResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val lead: Lead = Lead(),
    val duplicate: Boolean = false
) : ApiResult

data class PaymentLinkResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val provider: String = "",
    val url: String = "",
    val upi: String = ""
) : ApiResult

data class TaskCreatedResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    @SerializedName("task_id") val taskId: Long = 0
) : ApiResult

data class SimpleResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val message: String? = null,
    val duplicate: Boolean = false,
    val url: String = ""
) : ApiResult

data class CallerIdContact(
    val id: Long = 0,
    val name: String = "",
    val phone: String = "",
    val stage: String = "",
    @SerializedName("lead_score") val leadScore: Int = 0,
    @SerializedName("deal_value") val dealValue: Double = 0.0,
    val destination: String? = null,
    val requirements: String? = null,
    @SerializedName("ai_summary") val aiSummary: String? = null,
    @SerializedName("next_best_action") val nextBestAction: String? = null
)

data class CallerIdResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    val found: Boolean = false,
    val contact: CallerIdContact? = null
) : ApiResult

data class NotifLead(
    val id: Long = 0, val name: String = "", val phone: String = "",
    val source: String = "", val destination: String = ""
)

data class NotifReply(
    val id: Long = 0,
    @SerializedName("lead_id") val leadId: Long = 0,
    val name: String = "", val phone: String = "", val text: String = "", val at: String? = null
)

data class NotifTask(
    val id: Long = 0,
    @SerializedName("lead_id") val leadId: Long = 0,
    val name: String = "", val text: String = "",
    @SerializedName("due_at") val dueAt: String? = null
)

data class NotificationsResponse(
    override val ok: Boolean = false,
    override val error: String? = null,
    @SerializedName("latest_lead") val latestLead: Long = 0,
    @SerializedName("latest_msg") val latestMsg: Long = 0,
    @SerializedName("new_leads") val newLeads: List<NotifLead> = emptyList(),
    val replies: List<NotifReply> = emptyList(),
    @SerializedName("tasks_due") val tasksDue: List<NotifTask> = emptyList()
) : ApiResult

// ---- request bodies ---------------------------------------------------------------------

data class CallLogPayload(
    val phone: String,
    @SerializedName("call_type") val callType: String, // incoming, outgoing, missed
    @SerializedName("duration_seconds") val durationSeconds: Long,
    val notes: String = "",
    /** Stable id so a retry after a timeout is not logged twice (the server de-duplicates on it). */
    @SerializedName("call_id") val callId: String = "",
    @SerializedName("recording_url") val recordingUrl: String = ""
)

data class CreateLeadBody(
    val name: String,
    val phone: String,
    val email: String = "",
    val destination: String = "",
    val pax: Int = 0,
    val budget: Double = 0.0,
    val requirements: String = "",
    val source: String = "mobile_app"
)

data class UpdateLeadBody(
    @SerializedName("lead_id") val leadId: Long,
    val stage: String? = null,
    val note: String? = null,
    val owner: String? = null
)

data class AssignLeadBody(
    @SerializedName("lead_id") val leadId: Long,
    @SerializedName("manager_name") val managerName: String,
    @SerializedName("notify_manager") val notifyManager: Boolean = true
)

data class CreateTaskBody(
    @SerializedName("lead_id") val leadId: Long,
    val content: String,
    @SerializedName("due_at") val dueAt: String
)

data class SaveBookingBody(
    @SerializedName("lead_id") val leadId: Long,
    @SerializedName("booking_id") val bookingId: Long = 0,
    val title: String,
    @SerializedName("start_date") val startDate: String? = null,
    @SerializedName("end_date") val endDate: String? = null,
    val pax: Int = 1,
    val vehicle: String = "",
    val driver: String = "",
    @SerializedName("quote_amount") val quoteAmount: Double = 0.0,
    val status: String = "quoted",
    val notes: String = ""
)

data class QuoteLineBody(@SerializedName("desc") val description: String, val qty: Double, val price: Double)

data class CreateQuoteBody(
    @SerializedName("booking_id") val bookingId: Long,
    val items: List<QuoteLineBody>,
    val discount: Double = 0.0,
    val notes: String = ""
)

data class PaymentLinkBody(
    @SerializedName("booking_id") val bookingId: Long,
    val amount: Double,
    val purpose: String = ""
)

data class RecordPaymentBody(
    @SerializedName("booking_id") val bookingId: Long,
    val amount: Double,
    val method: String,
    val reference: String = ""
)

data class ReplyBody(val message: String)

data class SummarizeBody(
    val notes: String = "",
    val transcript: String = "",
    @SerializedName("create_task") val createTask: Boolean = false
)

data class QuickActionBody(val phone: String, val action: String)

data class DispatchBody(
    val phone: String,
    @SerializedName("customer_name") val customerName: String,
    @SerializedName("driver_name") val driverName: String,
    @SerializedName("vehicle_number") val vehicleNumber: String,
    @SerializedName("vehicle_type") val vehicleType: String
)
