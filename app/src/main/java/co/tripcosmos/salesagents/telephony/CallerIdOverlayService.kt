package co.tripcosmos.salesagents.telephony

import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import co.tripcosmos.salesagents.R
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.util.Format

/**
 * Floating "who is this / what do they want" card shown over the incoming-call screen while a known
 * lead's number rings. Built with plain Views (not Compose): a WindowManager overlay window is not a
 * normal activity host, and Compose needs extra plumbing (a ViewTreeLifecycleOwner) to run in one.
 */
class CallerIdOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    companion object {
        const val ACTION_SHOW_OVERLAY = "co.tripcosmos.SHOW_OVERLAY"
        const val ACTION_HIDE_OVERLAY = "co.tripcosmos.HIDE_OVERLAY"

        const val EXTRA_NAME = "extra_name"
        const val EXTRA_PHONE = "extra_phone"
        const val EXTRA_DEAL_VALUE = "extra_deal_value"
        const val EXTRA_STAGE = "extra_stage"
        const val EXTRA_DESTINATION = "extra_destination"
        const val EXTRA_AI_SUMMARY = "extra_ai_summary"
        const val EXTRA_NEXT_ACTION = "extra_next_action"

        private const val NOTIFICATION_ID = 9001

        fun showOverlay(
            context: Context,
            name: String,
            phone: String,
            dealValue: Double,
            stage: String,
            destination: String,
            aiSummary: String,
            nextAction: String
        ) {
            val intent = Intent(context, CallerIdOverlayService::class.java).apply {
                action = ACTION_SHOW_OVERLAY
                putExtra(EXTRA_NAME, name)
                putExtra(EXTRA_PHONE, phone)
                putExtra(EXTRA_DEAL_VALUE, dealValue)
                putExtra(EXTRA_STAGE, stage)
                putExtra(EXTRA_DESTINATION, destination)
                putExtra(EXTRA_AI_SUMMARY, aiSummary)
                putExtra(EXTRA_NEXT_ACTION, nextAction)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(intent) else context.startService(intent)
        }

        fun hideOverlay(context: Context) {
            val intent = Intent(context, CallerIdOverlayService::class.java).apply { action = ACTION_HIDE_OVERLAY }
            context.startService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW_OVERLAY -> {
                startForegroundNotification()
                intent.let { renderOverlay(it) }
            }
            ACTION_HIDE_OVERLAY -> removeOverlay()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }

    private fun startForegroundNotification() {
        val notification: Notification = NotificationCompat.Builder(this, SalesAgentsApp.CALLER_ID_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle("TripCosmos caller card")
            .setContentText("Showing lead details for the incoming call")
            .setOngoing(true)
            .build()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun renderOverlay(intent: Intent) {
        removeOverlay()

        val name = intent.getStringExtra(EXTRA_NAME).orEmpty().ifBlank { "Traveler" }
        val phone = intent.getStringExtra(EXTRA_PHONE).orEmpty()
        val dealValue = intent.getDoubleExtra(EXTRA_DEAL_VALUE, 0.0)
        val stage = intent.getStringExtra(EXTRA_STAGE).orEmpty()
        val destination = intent.getStringExtra(EXTRA_DESTINATION).orEmpty()
        val aiSummary = intent.getStringExtra(EXTRA_AI_SUMMARY).orEmpty()
        val nextAction = intent.getStringExtra(EXTRA_NEXT_ACTION).orEmpty()

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP }

        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val cardView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#1F3A5F"))
                cornerRadius = dp(16).toFloat()
            }
        }

        val titleRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val nameText = TextView(this).apply {
            text = "$name  ·  ${Format.phone(phone)}"
            setTextColor(Color.WHITE)
            textSize = 16f
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        val closeBtn = TextView(this).apply {
            text = "✕"
            setTextColor(Color.WHITE)
            textSize = 18f
            setPadding(dp(8), 0, dp(4), 0)
            setOnClickListener { hideOverlay(this@CallerIdOverlayService) }
        }
        titleRow.addView(nameText)
        titleRow.addView(closeBtn)
        cardView.addView(titleRow)

        val metaLine = listOfNotNull(
            stage.takeIf { it.isNotBlank() },
            destination.takeIf { it.isNotBlank() },
            dealValue.takeIf { it > 0 }?.let { Format.inrCompact(it) }
        ).joinToString(" · ")
        if (metaLine.isNotBlank()) {
            val metaText = TextView(this).apply {
                text = metaLine
                setTextColor(Color.parseColor("#D6DEEA"))
                textSize = 13f
                setPadding(0, dp(4), 0, 0)
            }
            cardView.addView(metaText)
        }

        if (aiSummary.isNotBlank()) {
            val aiTipText = TextView(this).apply {
                text = aiSummary
                setTextColor(Color.WHITE)
                textSize = 14f
                setPadding(0, dp(8), 0, 0)
                maxLines = 3
            }
            cardView.addView(aiTipText)
        }

        if (nextAction.isNotBlank()) {
            val nextText = TextView(this).apply {
                text = "Say: $nextAction"
                setTextColor(Color.parseColor("#FCD9A0"))
                textSize = 13f
                setPadding(0, dp(6), 0, 0)
            }
            cardView.addView(nextText)
        }

        if (phone.isNotBlank()) {
            val waButton = Button(this).apply {
                text = "WhatsApp"
                setOnClickListener {
                    DialerManager.openWhatsApp(this@CallerIdOverlayService, phone, "Namaste $name ji! Thank you for calling TripCosmos.")
                }
            }
            cardView.addView(waButton)
        }

        overlayView = cardView
        windowManager?.addView(cardView, params)
    }

    private fun removeOverlay() {
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {
            // View was already detached (e.g. the call ended twice in quick succession).
        }
        overlayView = null
    }
}
