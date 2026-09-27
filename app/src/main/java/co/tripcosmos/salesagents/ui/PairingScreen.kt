package co.tripcosmos.salesagents.ui

import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.OpenInNew
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.api.ApiClient
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.notify.SyncWorker
import kotlinx.coroutines.launch

/**
 * First-run and re-pair screen. The agent pastes a server URL and a token generated in
 * WordPress → TripCosmos Agents → Integrations → "Mobile App Access", and this screen verifies
 * both against the server (calling /mobile/me) before saving anything.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PairingScreen(onPaired: () -> Unit) {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    val scope = rememberCoroutineScope()

    var url by remember { mutableStateOf(AppConfig.baseUrl().takeIf { it != AppConfig.DEFAULT_BASE_URL } ?: "") }
    var token by remember { mutableStateOf("") }
    var checking by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    fun connect() {
        if (token.isBlank()) { error = "Paste the token from WordPress first."; return }
        error = null
        checking = true
        scope.launch {
            val effectiveUrl = AppConfig.normalizeBaseUrl(url.ifBlank { AppConfig.DEFAULT_BASE_URL })
            val api = ApiClient.forPairing(effectiveUrl, token)
            val result = try {
                val response = api.me()
                val body = response.body()
                when {
                    response.isSuccessful && body?.ok == true -> Res.Ok(body)
                    response.code() == 401 || response.code() == 403 -> Res.Err("That token was not accepted. Check it was copied in full.")
                    else -> Res.Err("Could not reach that server (HTTP ${response.code()}). Check the URL.")
                }
            } catch (e: Exception) {
                Res.Err("Could not reach that server: ${e.message ?: e.javaClass.simpleName}")
            }
            checking = false
            when (result) {
                is Res.Ok -> {
                    AppConfig.setBaseUrl(effectiveUrl)
                    AppConfig.setToken(token)
                    AppConfig.setAgentName(result.data.agent)
                    SyncWorker.schedule(context)
                    onPaired()
                }
                is Res.Err -> error = result.message
            }
        }
    }

    Box(Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(32.dp))
            Text("TripCosmos", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Text("Sales Agents", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.height(32.dp))

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Text("Connect this phone", fontWeight = FontWeight.SemiBold)

                    OutlinedTextField(
                        value = url, onValueChange = { url = it }, singleLine = true,
                        label = { Text("Website (leave blank for tripcosmos.co)") },
                        placeholder = { Text("tripcosmos.co") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = token, onValueChange = { token = it.trim() }, singleLine = true,
                        label = { Text("Mobile access token") },
                        supportingText = { Text("From TripCosmos Agents → Integrations → Mobile App Access") },
                        isError = error != null,
                        modifier = Modifier.fillMaxWidth()
                    )
                    if (error != null) {
                        Text(error!!, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                    Button(onClick = ::connect, enabled = !checking, modifier = Modifier.fillMaxWidth().height(48.dp)) {
                        if (checking) CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.onPrimary)
                        else Text("Connect")
                    }
                    TextButton(onClick = { uriHandler.openUri("https://${url.ifBlank { "tripcosmos.co" }}/wp-admin/admin.php?page=tc-agents-integrations#tc-mobile-access") }) {
                        Icon(Icons.Default.OpenInNew, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Open that settings page")
                    }
                }
            }
        }
    }
}

/** Reachable from Settings once paired, to re-pair, switch server, or sign out this device. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConnectionSettingsScreen(onSignedOut: () -> Unit, onClose: () -> Unit) {
    val context = LocalContext.current
    var confirmSignOut by remember { mutableStateOf(false) }

    Scaffold(topBar = { TopAppBar(title = { Text("Connection") }, navigationIcon = { IconButton(onClick = onClose) { Icon(Icons.AutoMirrored.Filled.ArrowBack, null) } }) }) { padding ->
        Column(Modifier.padding(padding).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
                Spacer(Modifier.width(8.dp))
                Column {
                    Text("Connected as ${AppConfig.agentName().ifBlank { "this device" }}")
                    Text(Uri.parse(AppConfig.baseUrl()).host.orEmpty(), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            OutlinedButton(onClick = { confirmSignOut = true }, modifier = Modifier.fillMaxWidth()) { Text("Disconnect this device") }
        }
    }

    if (confirmSignOut) {
        AlertDialog(
            onDismissRequest = { confirmSignOut = false },
            title = { Text("Disconnect this device?") },
            text = { Text("You will need the token again to reconnect. Cached leads on this phone are cleared.") },
            confirmButton = {
                TextButton(onClick = {
                    AppConfig.signOut()
                    SyncWorker.cancel(context)
                    kotlinx.coroutines.GlobalScope.launch { SalesAgentsApp.instance.repository.clearCache() }
                    confirmSignOut = false
                    onSignedOut()
                }) { Text("Disconnect") }
            },
            dismissButton = { TextButton(onClick = { confirmSignOut = false }) { Text("Cancel") } }
        )
    }
}
