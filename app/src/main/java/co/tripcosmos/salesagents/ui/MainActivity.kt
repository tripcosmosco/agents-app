package co.tripcosmos.salesagents.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.provider.Settings
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.notify.Notifier
import co.tripcosmos.salesagents.notify.PushRegistration
import co.tripcosmos.salesagents.notify.SyncWorker
import co.tripcosmos.salesagents.ui.theme.SalesAgentsTheme
import kotlinx.coroutines.launch

class MainActivity : FragmentActivity() {

    private val requestPermissions = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { /* best-effort */ }

    /** The newest notification / caller-card tap that has not been acted on yet. */
    private val pendingOpen = mutableStateOf<Intent?>(null)

    /** App lock: true while the content is hidden behind the fingerprint / screen-lock prompt. */
    private val locked = mutableStateOf(false)
    private var backgroundedAt = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        askRuntimePermissions()
        // A rotation re-creates the activity with the same intent: only act on it the first time.
        if (savedInstanceState == null) pendingOpen.value = intent
        locked.value = AppConfig.getBool(AppLock.PREF_ENABLED, false) && AppLock.available(this)

        setContent {
            SalesAgentsTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    if (locked.value) {
                        LockedScreen(onUnlock = ::promptUnlock)
                        LaunchedEffect(Unit) { promptUnlock() }
                    } else {
                        AppRoot(pendingOpen = pendingOpen.value, onOpened = { pendingOpen.value = null })
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Delivered while the app is already open (single-top): hand it to the composition.
        pendingOpen.value = intent
    }

    override fun onStop() {
        super.onStop()
        backgroundedAt = SystemClock.elapsedRealtime()
    }

    override fun onStart() {
        super.onStart()
        if (backgroundedAt > 0 && AppConfig.getBool(AppLock.PREF_ENABLED, false) && AppLock.available(this) &&
            SystemClock.elapsedRealtime() - backgroundedAt > AppLock.GRACE_MS
        ) locked.value = true
    }

    private fun promptUnlock() {
        val prompt = BiometricPrompt(this, ContextCompat.getMainExecutor(this), object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) { locked.value = false }
        })
        prompt.authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Unlock TripCosmos")
                .setSubtitle("Customer data is protected on this phone")
                .setAllowedAuthenticators(AppLock.AUTHENTICATORS)
                .build()
        )
    }

    private fun askRuntimePermissions() {
        val wanted = mutableListOf(Manifest.permission.READ_PHONE_STATE, Manifest.permission.READ_CALL_LOG, Manifest.permission.CALL_PHONE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) wanted += Manifest.permission.POST_NOTIFICATIONS
        val missing = wanted.filter { ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isNotEmpty()) requestPermissions.launch(missing.toTypedArray())
    }
}

/** Fingerprint / face / device PIN lock for the app, switched on in Settings. */
object AppLock {
    const val PREF_ENABLED = "app_lock_on"
    const val GRACE_MS = 60_000L
    const val AUTHENTICATORS = BiometricManager.Authenticators.BIOMETRIC_WEAK or BiometricManager.Authenticators.DEVICE_CREDENTIAL

    fun available(context: android.content.Context): Boolean =
        BiometricManager.from(context).canAuthenticate(AUTHENTICATORS) == BiometricManager.BIOMETRIC_SUCCESS
}

@Composable
private fun LockedScreen(onUnlock: () -> Unit) {
    Column(Modifier.fillMaxSize().padding(32.dp), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(48.dp), tint = MaterialTheme.colorScheme.primary)
        Spacer(Modifier.height(16.dp))
        Text("TripCosmos is locked", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(24.dp))
        Button(onClick = onUnlock) { Text("Unlock") }
    }
}

private sealed class Dest(val route: String, val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    object Home : Dest("home", "Today", Icons.Default.Home)
    object Leads : Dest("leads", "Leads", Icons.Default.People)
    object Inbox : Dest("inbox", "WhatsApp", Icons.Default.Chat)
    object Tasks : Dest("tasks", "Follow-ups", Icons.Default.CheckCircle)
}

private val bottomDests = listOf(Dest.Home, Dest.Leads, Dest.Inbox, Dest.Tasks)

@Composable
private fun AppRoot(pendingOpen: Intent?, onOpened: () -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    var paired by remember { mutableStateOf(AppConfig.isPaired()) }
    var tokenRejected by remember { mutableStateOf(false) }
    val context = LocalContext.current

    fun signOut() {
        AppConfig.signOut()
        SyncWorker.cancel(context)
        SalesAgentsApp.instance.appScope.launch { repo.clearCache() }
        paired = false
    }

    // A rejected token anywhere in the app (revoked in WordPress, or deleted) sends the agent back to pairing.
    LaunchedEffect(Unit) { repo.authFailed.collect { if (AppConfig.isPaired()) tokenRejected = true } }

    if (tokenRejected) {
        AlertDialog(
            onDismissRequest = {},
            title = { Text("This phone was disconnected") },
            text = { Text("The server no longer accepts this phone's access token (it may have been revoked). Connect again with a new token from WordPress.") },
            confirmButton = { TextButton(onClick = { tokenRejected = false; signOut() }) { Text("Connect again") } }
        )
    }

    if (!paired) {
        PairingScreen(onPaired = { paired = true; PushRegistration.refresh(context) })
        return
    }

    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    var showPostCall by remember { mutableStateOf(false) }
    var showOverlayHint by remember { mutableStateOf(false) }

    // Deep link from a notification or the caller card, whether the app was closed or already open.
    LaunchedEffect(pendingOpen) {
        val i = pendingOpen ?: return@LaunchedEffect
        val leadId = i.getLongExtra(Notifier.EXTRA_LEAD_ID, 0)
        when (i.getStringExtra(Notifier.EXTRA_OPEN)) {
            "lead" -> if (leadId > 0) nav.navigate("lead/$leadId")
            "chat" -> if (leadId > 0) nav.navigate("chat/$leadId/${Uri.encode(" ")}")
            "leads" -> nav.navigate(Dest.Leads.route) { launchSingleTop = true }
            "tasks" -> nav.navigate(Dest.Tasks.route) { launchSingleTop = true }
            "inbox" -> nav.navigate(Dest.Inbox.route) { launchSingleTop = true }
            "postcall" -> showPostCall = true
        }
        onOpened()
    }
    LaunchedEffect(Unit) {
        PushRegistration.refresh(context)
        // Ask once; after that the switch lives in Settings.
        if (!Settings.canDrawOverlays(context) && !AppConfig.getBool(PREF_OVERLAY_ASKED, false)) {
            showOverlayHint = true
            AppConfig.putBool(PREF_OVERLAY_ASKED, true)
        }
    }

    Scaffold(
        bottomBar = {
            if (bottomDests.any { it.route == currentRoute }) {
                NavigationBar {
                    bottomDests.forEach { d ->
                        NavigationBarItem(
                            selected = currentRoute == d.route,
                            onClick = { nav.navigate(d.route) { popUpTo(Dest.Home.route) { saveState = true }; launchSingleTop = true; restoreState = true } },
                            icon = { Icon(d.icon, contentDescription = d.label) },
                            label = { Text(d.label) }
                        )
                    }
                }
            }
        }
    ) { padding ->
        Box(Modifier.padding(padding)) {
            NavHost(navController = nav, startDestination = Dest.Home.route) {
                composable(Dest.Home.route) {
                    HomeScreen(
                        onOpenLead = { nav.navigate("lead/$it") },
                        onOpenTasks = { nav.navigate(Dest.Tasks.route) },
                        onOpenSettings = { nav.navigate("settings") },
                        onOpenTeam = { nav.navigate("team") },
                        onOpenBoard = { nav.navigate("board") },
                        onOpenBroadcasts = { nav.navigate("broadcasts") },
                        onOpenCalls = { nav.navigate("calls") }
                    )
                }
                composable(Dest.Leads.route) { LeadsScreen(onOpenLead = { nav.navigate("lead/$it") }, onOpenBoard = { nav.navigate("board") }) }
                composable(Dest.Tasks.route) { TasksScreen(onOpenLead = { nav.navigate("lead/$it") }) }
                composable(Dest.Inbox.route) { InboxScreen(onOpenConversation = { id, name -> nav.navigate("chat/$id/${Uri.encode(name.ifBlank { " " })}") }) }
                composable("lead/{id}") { back ->
                    LeadDetailScreen(
                        back.arguments?.getString("id")?.toLongOrNull() ?: 0,
                        onBack = { nav.popBackStack() },
                        onOpenChat = { id, name -> nav.navigate("chat/$id/${Uri.encode(name.ifBlank { " " })}") }
                    )
                }
                composable("chat/{id}/{name}") { back ->
                    ConversationScreen(
                        back.arguments?.getString("id")?.toLongOrNull() ?: 0,
                        Uri.decode(back.arguments?.getString("name").orEmpty()).trim(),
                        onBack = { nav.popBackStack() },
                        onOpenLead = { nav.navigate("lead/$it") }
                    )
                }
                composable("board") { BoardScreen(onOpenLead = { nav.navigate("lead/$it") }, onBack = { nav.popBackStack() }) }
                composable("team") { TeamScreen(onBack = { nav.popBackStack() }) }
                composable("calls") { CallsScreen(onOpenLead = { nav.navigate("lead/$it") }, onBack = { nav.popBackStack() }) }
                composable("broadcasts") { BroadcastScreen(onBack = { nav.popBackStack() }) }
                composable("settings") { SettingsScreen(onSignOut = ::signOut, onClose = { nav.popBackStack() }) }
            }
        }
    }

    if (showPostCall) {
        PostCallScreen(onOpenLead = { showPostCall = false; nav.navigate("lead/$it") }, onDismiss = { showPostCall = false })
    }
    if (showOverlayHint) {
        AlertDialog(
            onDismissRequest = { showOverlayHint = false },
            title = { Text("Show caller info while ringing?") },
            text = { Text("Allow \"Display over other apps\" so incoming calls show the customer's name and trip details. You can change this later in Settings.") },
            confirmButton = {
                TextButton(onClick = {
                    showOverlayHint = false
                    context.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${context.packageName}")))
                }) { Text("Allow") }
            },
            dismissButton = { TextButton(onClick = { showOverlayHint = false }) { Text("Not now") } }
        )
    }
}

private const val PREF_OVERLAY_ASKED = "overlay_hint_shown"
