package co.tripcosmos.salesagents.util

import org.junit.Assert.*
import org.junit.Test
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

class FormatTest {

    private val ist = ZoneId.of("Asia/Kolkata")
    private val now = Instant.parse("2026-09-27T06:00:00Z") // 11:30 IST, Sunday

    @Test fun `rupees use indian digit grouping`() {
        assertEquals("₹0", Format.inr(0.0))
        assertEquals("₹999", Format.inr(999.0))
        assertEquals("₹1,000", Format.inr(1000.0))
        assertEquals("₹45,400", Format.inr(45400.0))
        assertEquals("₹4,54,000", Format.inr(454000.0))
        assertEquals("₹45,40,000", Format.inr(4540000.0))
        assertEquals("₹1,20,00,000", Format.inr(12000000.0))
        assertEquals("₹1,234.50", Format.inr(1234.5))
        assertEquals("-₹500", Format.inr(-500.0))
    }

    @Test fun `compact rupees for dashboards`() {
        assertEquals("₹950", Format.inrCompact(950.0))
        assertEquals("₹12.5K", Format.inrCompact(12500.0))
        assertEquals("₹45.4L", Format.inrCompact(4540000.0))
        assertEquals("₹1.2Cr", Format.inrCompact(12000000.0))
        assertEquals("₹1L", Format.inrCompact(100000.0))
    }

    @Test fun `iso parsing accepts the server format and rejects junk`() {
        assertEquals(Instant.parse("2026-09-27T05:30:00Z"), Format.parseIso("2026-09-27T05:30:00Z"))
        assertNull(Format.parseIso(null))
        assertNull(Format.parseIso(""))
        assertNull(Format.parseIso("not a date"))
    }

    @Test fun `a picked local time is sent to the server as utc`() {
        val elevenIst = ZonedDateTime.of(2026, 9, 28, 11, 0, 0, 0, ist)
        assertEquals("2026-09-28T05:30:00Z", Format.toIsoUtc(elevenIst))
    }

    @Test fun `relative times`() {
        assertEquals("just now", Format.relative("2026-09-27T05:59:40Z", now, ist))
        assertEquals("5 min ago", Format.relative("2026-09-27T05:55:00Z", now, ist))
        assertEquals("3 h ago", Format.relative("2026-09-27T03:00:00Z", now, ist))
        assertEquals("in 2 h", Format.relative("2026-09-27T08:00:00Z", now, ist))
        assertEquals("Yesterday", Format.relative("2026-09-26T05:00:00Z", now, ist))
        assertEquals("3 d ago", Format.relative("2026-09-24T06:00:00Z", now, ist))
        assertEquals("12 Aug", Format.relative("2026-08-12T06:00:00Z", now, ist))
        assertEquals("", Format.relative(null, now, ist))
    }

    @Test fun `due labels flag overdue and today`() {
        val today = Format.due("2026-09-27T10:00:00Z", now, ist)!!
        assertEquals("Today, 3:30 PM", today.text); assertTrue(today.today); assertFalse(today.overdue)

        val tomorrow = Format.due("2026-09-28T05:30:00Z", now, ist)!!
        assertEquals("Tomorrow, 11:00 AM", tomorrow.text); assertFalse(tomorrow.overdue)

        val later = Format.due("2026-10-02T05:30:00Z", now, ist)!!
        assertEquals("Fri 2 Oct, 11:00 AM", later.text)

        val overdue = Format.due("2026-09-20T04:00:00Z", now, ist)!!
        assertEquals("Overdue · 7 d", overdue.text); assertTrue(overdue.overdue)

        val earlierToday = Format.due("2026-09-27T04:00:00Z", now, ist)!!
        assertTrue(earlierToday.overdue); assertTrue(earlierToday.today)

        assertNull(Format.due(null, now, ist))
    }

    @Test fun `call durations`() {
        assertEquals("", Format.duration(0))
        assertEquals("45s", Format.duration(45))
        assertEquals("3m 04s", Format.duration(184))
        assertEquals("60m 00s", Format.duration(3600))
    }

    @Test fun `whatsapp receipt ticks`() {
        assertEquals("✓", Format.tick("sent"))
        assertEquals("✓✓", Format.tick("delivered"))
        assertEquals("✓✓", Format.tick("read"))
        assertEquals("!", Format.tick("failed"))
        assertEquals("", Format.tick(""))
        assertEquals("Read", Format.tickLabel("read"))
    }

    @Test fun `initials`() {
        assertEquals("AV", Format.initials("Aditya Verma"))
        assertEquals("RM", Format.initials("Rajesh & Sunita Mehra"))
        assertEquals("PR", Format.initials("Priya"))
        assertEquals("?", Format.initials("   "))
    }

    @Test fun `phone formatting and matching keys`() {
        assertEquals("+91 93361 16210", Format.phone("+919336116210"))
        assertEquals("9336116210", Format.phone("9336116210"))
        assertEquals("9336116210", Format.phoneKey("+91 93361-16210"))
        assertEquals("9336116210", Format.phoneKey("09336116210"))
    }

    @Test fun `stage labels prefer the servers and fall back sensibly`() {
        assertEquals("Trip completed", Format.stageLabel("completed"))
        assertEquals("Custom", Format.stageLabel("custom_stage", mapOf("custom_stage" to "Custom")))
        assertEquals("Follow up", Format.stageLabel("follow_up"))
    }
}
