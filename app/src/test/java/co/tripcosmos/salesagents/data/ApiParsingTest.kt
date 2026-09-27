package co.tripcosmos.salesagents.data

import co.tripcosmos.salesagents.data.model.*
import com.google.gson.Gson
import org.junit.Assert.*
import org.junit.Test

/** Fixtures are real responses captured from the plugin (v1.8.0/1.9.0) running on WordPress + MariaDB. */
class ApiParsingTest {

    private val gson = Gson()

    @Test fun `me response`() {
        val r = gson.fromJson(
            """{"ok":true,"agent":"Test Phone","plugin_version":"1.8.0","api_level":2,"server_time":"2026-09-27T04:59:03Z",
            "stages":[{"id":"inquiry","label":"Inquiry"},{"id":"won","label":"Won"}],
            "booking_status":[{"id":"quoted","label":"Quoted"}],
            "team":[{"id":1,"name":"admin","role":"administrator"}],
            "features":{"cashfree":false,"upi":true,"gst":false,"whatsapp":true}}""",
            MeResponse::class.java
        )
        assertTrue(r.ok); assertEquals("Test Phone", r.agent); assertEquals(2, r.apiLevel)
        assertEquals(2, r.stages.size); assertEquals("Won", r.stages[1].label)
        assertEquals("admin", r.team[0].name)
        assertTrue(r.features.upi); assertFalse(r.features.cashfree)
    }

    @Test fun `lead detail with tasks and empty memory`() {
        val r = gson.fromJson(
            """{"ok":true,"lead":{"id":1,"name":"Aditya Verma","phone":"+919336116210","email":"a@example.com","stage":"won","score":50,
            "deal_value":45400,"owner":"","source":"website","tags":[],"destination":"Varanasi & Ayodhya","pax":4,"travel_month":"",
            "requirements":"","intent":"","next_follow_up_at":"2026-09-28T05:30:00Z","last_contacted_at":null,
            "created_at":"2026-09-27T04:58:52Z","updated_at":"2026-09-27T04:58:52Z"},
            "activities":[{"id":1,"type":"system","content":"Contact created from website","meta":{},"due_at":null,"done_at":null,"created_at":"2026-09-27T04:58:52Z"}],
            "tasks":[{"id":5,"type":"task","content":"Send quotation","meta":{},"due_at":"2026-09-28T05:30:00Z","done_at":null,"created_at":"2026-09-27T04:59:18Z"}],
            "bookings":[],"memory":null,"can_contact":{"whatsapp":true,"email":true}}""",
            LeadDetailResponse::class.java
        )
        assertEquals(1L, r.lead.id); assertEquals(45400.0, r.lead.dealValue, 0.0); assertEquals(4, r.lead.pax)
        assertEquals("", r.lead.owner); assertNull(r.lead.lastContactedAt)
        assertEquals("2026-09-28T05:30:00Z", r.lead.nextFollowUpAt)
        assertEquals(1, r.activities.size); assertEquals("Send quotation", r.tasks[0].content)
        assertNull(r.memory); assertTrue(r.canContact.whatsapp)
    }

    @Test fun `booking with quote and balance`() {
        val r = gson.fromJson(
            """{"ok":true,"booking":{"id":1,"lead_id":1,"ref":"TC-260927-1","title":"Varanasi + Ayodhya 4N\/5D","start_date":"2026-10-15",
            "end_date":"2026-10-19","pax":4,"vehicle":"Innova Crysta","driver":"","status":"advance_paid","quote_amount":45400,
            "advance_paid":5000,"total":45400,"balance":40400,"advance_due":0,"notes":"",
            "quote":{"id":1,"version":1,"status":"draft","total":45400,"advance_amount":1500,"valid_until":"2026-10-04",
            "url":"http:\/\/127.0.0.1:18080\/?tc_quote=23a1c4a4","items":[{"desc":"Innova Crysta 5 days","qty":5,"price":4500,"amount":22500}]},
            "updated_at":"2026-09-27T04:59:35Z"}}""",
            BookingResponse::class.java
        )
        val b = r.booking!!
        assertEquals("Varanasi + Ayodhya 4N/5D", b.title); assertEquals("advance_paid", b.status)
        assertEquals(40400.0, b.balance, 0.0); assertEquals(5000.0, b.advancePaid, 0.0)
        assertEquals("Innova Crysta 5 days", b.quote!!.items[0].description)
        assertEquals(22500.0, b.quote!!.items[0].amount, 0.0)
    }

    @Test fun `dashboard`() {
        val r = gson.fromJson(
            """{"ok":true,"today":{"new_leads":1,"calls":0,"quotes_sent":0,"bookings":0,"tasks_due":0,"tasks_overdue":2,"collected":5000},
            "month":{"new_leads":3,"won":1,"collected":5000},
            "pipeline":[{"stage":"inquiry","count":1,"value":45000}],"hot":[]}""",
            DashboardResponse::class.java
        )
        assertEquals(2, r.today.tasksOverdue); assertEquals(5000.0, r.today.collected, 0.0)
        assertEquals("inquiry", r.pipeline[0].stage)
    }

    @Test fun `notifications feed`() {
        val r = gson.fromJson(
            """{"ok":true,"latest_lead":3,"latest_msg":0,"new_leads":[{"id":3,"name":"Rohit K","phone":"+919811122233","source":"mobile_app","destination":""}],
            "replies":[],"tasks_due":[{"id":6,"lead_id":1,"name":"Aditya Verma","text":"Call back","due_at":"2026-09-20T04:00:00Z"}]}""",
            NotificationsResponse::class.java
        )
        assertEquals(3L, r.latestLead); assertEquals("Rohit K", r.newLeads[0].name)
        assertEquals(1L, r.tasksDue[0].leadId)
    }

    @Test fun `whatsapp thread with sender, receipts and AI state`() {
        val r = gson.fromJson(
            """{"ok":true,"messages":[
            {"id":1,"from":"customer","text":"Namaste","by":"","delivery":"","at":"2026-09-27T05:50:00Z"},
            {"id":5,"from":"agent","text":"Rs 14,500","by":"Santosh","delivery":"read","at":"2026-09-27T05:52:00Z"}],
            "lead":{"id":4,"name":"Neha Kapoor"},"ai_enabled":false}""",
            ConversationResponse::class.java
        )
        assertFalse(r.aiEnabled)
        assertEquals("Santosh", r.messages[1].by)
        assertEquals("read", r.messages[1].delivery)
        assertEquals("", r.messages[0].delivery)
        assertTrue("AI defaults to on when the server omits it", gson.fromJson("""{"ok":true}""", ConversationResponse::class.java).aiEnabled)
    }

    @Test fun `a response missing fields yields empty values, never invented ones`() {
        val lead = gson.fromJson("""{"id":9}""", Lead::class.java)
        assertEquals("", lead.name); assertEquals("", lead.owner); assertTrue(lead.tags.isEmpty())
        assertEquals(0.0, lead.dealValue, 0.0); assertNull(lead.nextFollowUpAt)
        val me = gson.fromJson("""{"ok":true}""", MeResponse::class.java)
        assertTrue(me.team.isEmpty()); assertEquals("", me.agent)
    }

    @Test fun `request bodies use the servers field names`() {
        val json = gson.toJson(CreateTaskBody(7, "Call back", "2026-09-28T05:30:00Z"))
        assertTrue(json.contains("\"lead_id\":7")); assertTrue(json.contains("\"due_at\""))
        val quote = gson.toJson(CreateQuoteBody(1, listOf(QuoteLineBody("Cab", 2.0, 4500.0)), 500.0))
        assertTrue(quote.contains("\"booking_id\":1")); assertTrue(quote.contains("\"desc\":\"Cab\""))
        val call = gson.toJson(CallLogPayload("+919336116210", "outgoing", 184, callId = "abc"))
        assertTrue(call.contains("\"duration_seconds\":184")); assertTrue(call.contains("\"call_id\":\"abc\""))
    }
}
