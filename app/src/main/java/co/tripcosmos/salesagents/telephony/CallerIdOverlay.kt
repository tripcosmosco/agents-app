package co.tripcosmos.salesagents.telephony

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import co.tripcosmos.salesagents.notify.Notifier
import co.tripcosmos.salesagents.ui.MainActivity
import co.tripcosmos.salesagents.util.Format

/**
 * Floating "who is this / what do they want" card shown over the incoming-call screen while a known lead's
 * number rings.
 *
 * It is added straight to the WindowManager with the "Display over other apps" permission. There is
 * deliberately no foreground service: a phoneCall-type service needs the dialer role or MANAGE_OWN_CALLS on
 * Android 14 and would crash, and an overlay window does not need a service to stay on screen. Built with
 * plain Views: an overlay window is not an activity, and Compose would need a lifecycle owner to run in one.
 */
object CallerIdOverlay {

    private val main = Handler(Looper.getMainLooper())
    private var view: View? = null

    data class Card(
        val leadId: Long,
        val name: String,
        val phone: String,
        val stage: String,
        val destination: String,
        val dealValue: Double,
        val summary: String,
        val nextAction: String,
        val owner: String = ""
    )

    fun show(context: Context, card: Card) {
        val app = context.applicationContext
        if (!Settings.canDrawOverlays(app)) return
        main.post { render(app, card) }
    }

    fun hide() {
        main.post { removeNow() }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun render(context: Context, c: Card) {
        removeNow()
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val density = context.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP
            y = dp(96)
        }

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(14), dp(16), dp(14))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#F21F3A5F"))
                cornerRadius = dp(18).toFloat()
            }
        }
        val outer = LinearLayout(context).apply {
            setPadding(dp(12), 0, dp(12), 0)
            addView(card, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        }

        fun line(text: String, color: String, size: Float, top: Int = 0, lines: Int = 2) = TextView(context).apply {
            this.text = text
            setTextColor(Color.parseColor(color))
            textSize = size
            maxLines = lines
            setPadding(0, dp(top), 0, 0)
        }

        val title = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        title.addView(
            line("TripCosmos · ${c.name.ifBlank { "Traveler" }}", "#FFFFFF", 16f, lines = 1),
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        )
        title.addView(line("✕", "#FFFFFF", 18f).apply {
            setPadding(dp(12), 0, dp(4), 0)
            contentDescription = "Close caller card"
            setOnClickListener { removeNow() }
        })
        card.addView(title)

        val meta = listOfNotNull(
            Format.stageLabel(c.stage).takeIf { c.stage.isNotBlank() },
            c.destination.takeIf { it.isNotBlank() },
            c.dealValue.takeIf { it > 0 }?.let { Format.inrCompact(it) },
            c.owner.takeIf { it.isNotBlank() }?.let { "Owner: $it" }
        ).joinToString(" · ")
        if (meta.isNotBlank()) card.addView(line(meta, "#D6DEEA", 13f, top = 4))
        if (c.summary.isNotBlank()) card.addView(line(c.summary, "#FFFFFF", 14f, top = 8, lines = 3))
        if (c.nextAction.isNotBlank()) card.addView(line("Next: ${c.nextAction}", "#FCD9A0", 13f, top = 6))
        card.addView(line("Tap to open the lead", "#9FB3CC", 12f, top = 8, lines = 1))

        // Tap opens the lead; the card can be dragged up or down out of the way of the call buttons.
        var downY = 0f
        var startY = 0
        var moved = false
        outer.setOnTouchListener { _, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> { downY = e.rawY; startY = params.y; moved = false; true }
                MotionEvent.ACTION_MOVE -> {
                    val dy = (e.rawY - downY).toInt()
                    if (kotlin.math.abs(dy) > dp(8)) moved = true
                    params.y = (startY + dy).coerceAtLeast(0)
                    try { wm.updateViewLayout(outer, params) } catch (_: Exception) {}
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!moved && c.leadId > 0) {
                        context.startActivity(Intent(context, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            putExtra(Notifier.EXTRA_OPEN, "lead")
                            putExtra(Notifier.EXTRA_LEAD_ID, c.leadId)
                        })
                        removeNow()
                    }
                    true
                }
                else -> false
            }
        }

        try {
            wm.addView(outer, params)
            view = outer
        } catch (e: Exception) {
            view = null // permission revoked between the check and now
        }
    }

    private fun removeNow() {
        val v = view ?: return
        view = null
        try {
            (v.context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(v)
        } catch (_: Exception) {
            // Already detached.
        }
    }
}
