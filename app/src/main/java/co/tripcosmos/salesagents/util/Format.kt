package co.tripcosmos.salesagents.util

import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToLong

/** Pure formatting helpers (no Android types) so they can be unit-tested on the JVM. */
object Format {

    private val EN = Locale.ENGLISH

    // ---- time --------------------------------------------------------------------------------

    /** Parses the server's UTC ISO-8601 ("2026-09-27T05:30:00Z"); null for blank/invalid input. */
    fun parseIso(value: String?): Instant? {
        if (value.isNullOrBlank()) return null
        return try { Instant.parse(value) } catch (e: Exception) {
            try { java.time.OffsetDateTime.parse(value).toInstant() } catch (e2: Exception) { null }
        }
    }

    fun toIsoUtc(time: ZonedDateTime): String =
        DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'", EN).format(time.withZoneSameInstant(ZoneId.of("UTC")))

    /** "just now", "5 min ago", "3 h ago", "Yesterday", "4 d ago", then a date. Future times read "in 2 h". */
    fun relative(value: String?, now: Instant = Instant.now(), zone: ZoneId = ZoneId.systemDefault()): String {
        val t = parseIso(value) ?: return ""
        val d = Duration.between(t, now)
        val future = d.isNegative
        val mins = abs(d.toMinutes())
        val hours = abs(d.toHours())
        return when {
            mins < 1 -> "just now"
            mins < 60 -> if (future) "in $mins min" else "$mins min ago"
            hours < 24 -> if (future) "in $hours h" else "$hours h ago"
            else -> {
                val days = ChronoDays.between(t, now, zone)
                when {
                    !future && days == 1L -> "Yesterday"
                    !future && days < 7 -> "$days d ago"
                    future && days == 1L -> "Tomorrow"
                    future && days < 7 -> "in $days d"
                    else -> DateTimeFormatter.ofPattern("d MMM", EN).format(t.atZone(zone))
                }
            }
        }
    }

    /** Whole calendar days between two instants in [zone] (so 11 pm -> 1 am is 1 day, not 0). */
    private object ChronoDays {
        fun between(a: Instant, b: Instant, zone: ZoneId): Long =
            abs(java.time.temporal.ChronoUnit.DAYS.between(a.atZone(zone).toLocalDate(), b.atZone(zone).toLocalDate()))
    }

    data class Due(val text: String, val overdue: Boolean, val today: Boolean)

    /** Label for a task / follow-up: "Overdue · 2 d", "Today, 11:00 AM", "Tomorrow, 9:30 AM", "Mon 5 Oct, 11:00 AM". */
    fun due(value: String?, now: Instant = Instant.now(), zone: ZoneId = ZoneId.systemDefault()): Due? {
        val t = parseIso(value) ?: return null
        val local = t.atZone(zone)
        val today = now.atZone(zone).toLocalDate()
        val date: LocalDate = local.toLocalDate()
        val time = DateTimeFormatter.ofPattern("h:mm a", EN).format(local)
        val dayDiff = java.time.temporal.ChronoUnit.DAYS.between(today, date)
        if (t.isBefore(now)) {
            val text = when {
                dayDiff == 0L -> "Overdue · today, $time"
                dayDiff == -1L -> "Overdue · yesterday"
                else -> "Overdue · ${abs(dayDiff)} d"
            }
            return Due(text, overdue = true, today = dayDiff == 0L)
        }
        return when (dayDiff) {
            0L -> Due("Today, $time", overdue = false, today = true)
            1L -> Due("Tomorrow, $time", overdue = false, today = false)
            else -> Due(DateTimeFormatter.ofPattern("EEE d MMM, h:mm a", EN).format(local), overdue = false, today = false)
        }
    }

    /** "3m 04s" or "45s"; "" for zero (unanswered). */
    fun duration(seconds: Int): String {
        if (seconds <= 0) return ""
        val m = seconds / 60
        val s = seconds % 60
        return if (m == 0) "${s}s" else "%dm %02ds".format(EN, m, s)
    }

    /** WhatsApp-style receipt mark: ✓ sent, ✓✓ delivered/read, ! failed, "" when unknown. */
    fun tick(delivery: String): String = when (delivery) {
        "sent" -> "✓"
        "delivered", "read" -> "✓✓"
        "failed" -> "!"
        else -> ""
    }

    fun tickLabel(delivery: String): String = when (delivery) {
        "sent" -> "Sent"
        "delivered" -> "Delivered"
        "read" -> "Read"
        "failed" -> "Not delivered"
        else -> ""
    }

    // ---- money -------------------------------------------------------------------------------

    /** ₹ with Indian digit grouping: 4540000 -> "₹45,40,000". Whole rupees only; paise are shown when present. */
    fun inr(amount: Double): String {
        val negative = amount < 0
        val rounded = (abs(amount) * 100).roundToLong()
        val rupees = rounded / 100
        val paise = (rounded % 100).toInt()
        val digits = rupees.toString()
        val grouped = if (digits.length <= 3) digits else {
            val head = digits.dropLast(3)
            val tail = digits.takeLast(3)
            head.reversed().chunked(2).joinToString(",").reversed() + "," + tail
        }
        val body = if (paise == 0) grouped else "$grouped.%02d".format(EN, paise)
        return (if (negative) "-₹" else "₹") + body
    }

    /** Short form for dashboards: 4540000 -> "₹45.4L", 12500 -> "₹12.5K", 12000000 -> "₹1.2Cr". */
    fun inrCompact(amount: Double): String {
        val a = abs(amount)
        val sign = if (amount < 0) "-" else ""
        fun trim(v: Double): String = ("%.1f".format(EN, v)).removeSuffix(".0")
        return sign + when {
            a >= 1e7 -> "₹${trim(a / 1e7)}Cr"
            a >= 1e5 -> "₹${trim(a / 1e5)}L"
            a >= 1e3 -> "₹${trim(a / 1e3)}K"
            else -> "₹${a.roundToLong()}"
        }
    }

    // ---- people + phones ---------------------------------------------------------------------------

    fun initials(name: String): String {
        val parts = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
        return when {
            parts.isEmpty() -> "?"
            parts.size == 1 -> parts[0].take(2).uppercase(EN)
            else -> "${parts.first().first()}${parts.last().first()}".uppercase(EN)
        }
    }

    fun digits(phone: String): String = phone.filter { it.isDigit() }

    /** "+919336116210" -> "+91 93361 16210"; anything else is returned as typed. */
    fun phone(raw: String): String {
        val d = digits(raw)
        return if (raw.trim().startsWith("+91") && d.length == 12) "+91 ${d.substring(2, 7)} ${d.substring(7)}" else raw
    }

    /** Last 10 digits, used to match a number regardless of +91 / 0 prefixes. */
    fun phoneKey(raw: String): String = digits(raw).takeLast(10)

    fun stageLabel(id: String, labels: Map<String, String> = emptyMap()): String =
        labels[id] ?: when (id) {
            "inquiry" -> "Inquiry"
            "qualified" -> "Qualified"
            "proposal" -> "Proposal"
            "negotiation" -> "Negotiation"
            "won" -> "Won"
            "completed" -> "Trip completed"
            "lost" -> "Lost"
            else -> id.replace('_', ' ').replaceFirstChar { it.uppercase(EN) }
        }
}
