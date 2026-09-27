package co.tripcosmos.salesagents.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Brand
val Orange = Color(0xFFF97316)
val OrangeDark = Color(0xFFC2410C)
val Blue = Color(0xFF2563EB)
val Green = Color(0xFF16A34A)
val Red = Color(0xFFDC2626)
val Amber = Color(0xFFD97706)
val WhatsAppGreen = Color(0xFF25D366)

// Light
val LightBg = Color(0xFFF8FAFC)
val LightSurface = Color(0xFFFFFFFF)
val LightBorder = Color(0xFFE2E8F0)
val LightTextPrimary = Color(0xFF0F172A)
val LightTextSecondary = Color(0xFF64748B)

// Dark
val DarkBg = Color(0xFF0B1120)
val DarkSurface = Color(0xFF141B2D)
val DarkBorder = Color(0xFF263149)
val DarkTextPrimary = Color(0xFFE2E8F0)
val DarkTextSecondary = Color(0xFF94A3B8)

private val LightColors = lightColorScheme(
    primary = Orange, onPrimary = Color.White, primaryContainer = Color(0xFFFFEDD5), onPrimaryContainer = OrangeDark,
    secondary = Blue, onSecondary = Color.White,
    tertiary = Green,
    error = Red,
    background = LightBg, onBackground = LightTextPrimary,
    surface = LightSurface, onSurface = LightTextPrimary,
    surfaceVariant = Color(0xFFF1F5F9), onSurfaceVariant = LightTextSecondary,
    outline = LightBorder
)

private val DarkColors = darkColorScheme(
    primary = Orange, onPrimary = Color.White, primaryContainer = Color(0xFF3A2110), onPrimaryContainer = Color(0xFFFFCFA0),
    secondary = Blue, onSecondary = Color.White,
    tertiary = Green,
    error = Color(0xFFF87171),
    background = DarkBg, onBackground = DarkTextPrimary,
    surface = DarkSurface, onSurface = DarkTextPrimary,
    surfaceVariant = Color(0xFF1C2438), onSurfaceVariant = DarkTextSecondary,
    outline = DarkBorder
)

/** Stage / status colour, same meaning across the app (dashboard pills, lead cards, booking status). */
fun stageColor(stage: String): Color = when (stage) {
    "won", "advance_paid", "paid" -> Green
    "lost", "cancelled" -> Red
    "proposal", "quoted" -> Blue
    "negotiation" -> Amber
    "completed" -> Color(0xFF0D9488)
    else -> LightTextSecondary
}

@Composable
fun SalesAgentsTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = if (darkTheme) DarkColors else LightColors, content = content)
}
