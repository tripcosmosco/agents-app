package co.tripcosmos.salesagents.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.notify.Notifier
import co.tripcosmos.salesagents.ui.theme.SalesAgentsTheme

class MainActivity : ComponentActivity() {

    private val requestPermissions = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { /* best-effort */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        askRuntimePermissions()

        setContent {
            SalesAgentsTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    AppRoot(initialIntent = intent)
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun askRuntimePermissions() {
        val wanted = mutableListOf(Manifest.permission.READ_PHONE_STATE, Manifest.permission.READ_CALL_LOG)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) wanted += Manifest.permission.POST_NOTIFICATIONS
        val missing = wanted.filter { ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isNotEmpty()) requestPermissions.launch(missing.toTypedArray())
    }
}

private sealed class Dest(val route: String, val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    object Home : Dest("home", "Home", Icons.Default.Home)
    object Leads : Dest("leads", "Leads", Icons.Default.People)
    object Tasks : Dest("tasks", "Tasks", Icons.Default.CheckCircle)
    object Inbox : Dest("inbox", "WhatsApp", Icons.Default.Chat)
}

private val bottomDests = listOf(Dest.Home, Dest.Leads, Dest.Tasks, Dest.Inbox)

@Composable
private fun AppRoot(initialIntent: Intent?) {
    var paired by remember { mutableStateOf(AppConfig.isPaired()) }

    if (!paired) {
        PairingScreen(onPaired = { paired = true })
        return
    }

    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    var showPostCall by remember { mutableStateOf(false) }
    var showOverlayHint by remember { mutableStateOf(false) }
    val context = LocalContext.current

    // Deep link from a notification: open the right screen once, on first composition.
    LaunchedEffect(initialIntent) {
        when (initialIntent?.getStringExtra(Notifier.EXTRA_OPEN)) {
            "lead" -> initialIntent.getLongExtra(Notifier.EXTRA_LEAD_ID, 0).takeIf { it > 0 }?.let { nav.navigate("lead/$it") }
            "leads" -> nav.navigate(Dest.Leads.route)
            "tasks" -> nav.navigate(Dest.Tasks.route)
            "inbox" -> nav.navigate(Dest.Inbox.route)
            "postcall" -> showPostCall = true
        }
    }
    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) showOverlayHint = true
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
                composable(Dest.Home.route) { HomeScreen(onOpenLead = { nav.navigate("lead/$it") }, onOpenTasks = { nav.navigate(Dest.Tasks.route) }, onOpenSettings = { nav.navigate("settings") }) }
                composable(Dest.Leads.route) { LeadsScreen(onOpenLead = { nav.navigate("lead/$it") }) }
                composable(Dest.Tasks.route) { TasksScreen(onOpenLead = { nav.navigate("lead/$it") }) }
                composable(Dest.Inbox.route) { InboxScreen(onOpenConversation = { id, name -> nav.navigate("chat/$id/${Uri.encode(name)}") }) }
                composable("lead/{id}") { back -> LeadDetailScreen(back.arguments?.getString("id")?.toLongOrNull() ?: 0, onBack = { nav.popBackStack() }) }
                composable("chat/{id}/{name}") { back ->
                    ConversationScreen(
                        back.arguments?.getString("id")?.toLongOrNull() ?: 0,
                        Uri.decode(back.arguments?.getString("name").orEmpty()),
                        onBack = { nav.popBackStack() }
                    )
                }
                composable("settings") { ConnectionSettingsScreen(onSignedOut = { paired = false }, onClose = { nav.popBackStack() }) }
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
            text = { Text("Allow \"Display over other apps\" so incoming calls show the customer's name and trip details.") },
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
