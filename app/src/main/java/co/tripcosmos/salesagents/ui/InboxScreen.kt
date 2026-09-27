package co.tripcosmos.salesagents.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.ChatMessage
import co.tripcosmos.salesagents.data.model.InboxItem
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.ui.components.*
import co.tripcosmos.salesagents.ui.theme.WhatsAppGreen
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InboxScreen(onOpenConversation: (Long, String) -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()
    var items by remember { mutableStateOf<List<InboxItem>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<Res.Err?>(null) }
    var stale by remember { mutableStateOf(false) }

    suspend fun load() {
        loading = true
        when (val res = repo.inbox()) {
            is Res.Ok -> { items = res.data.leads; stale = false; error = null }
            is Res.Err -> {
                val cached = repo.cachedInbox()
                if (cached != null) { items = cached.leads; stale = true } else { error = res }
            }
        }
        loading = false
    }
    LaunchedEffect(Unit) { load() }

    Scaffold(topBar = { TopAppBar(title = { Text("WhatsApp", fontWeight = FontWeight.Bold) }) }) { padding ->
        Column(Modifier.padding(padding)) {
            if (stale) OfflineBanner()
            when {
                loading -> LoadingRow()
                error != null -> ErrorState(error!!, onRetry = { scope.launch { load() } })
                items.isEmpty() -> EmptyState("No WhatsApp conversations yet")
                else -> LazyColumn {
                    items(items, key = { it.id }) { item ->
                        ListItem(
                            leadingContent = { InitialsAvatar(item.customerName.ifBlank { "Traveler" }, size = 44) },
                            headlineContent = { Text(item.customerName.ifBlank { "Traveler" }, fontWeight = FontWeight.Medium) },
                            supportingContent = {
                                Column {
                                    Text(item.lastMessage.ifBlank { "No messages yet" }, maxLines = 1)
                                    Text(
                                        item.assignedManager?.takeIf { it.isNotBlank() }?.let { "Assigned to $it" } ?: "Not assigned",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = if (item.assignedManager.isNullOrBlank()) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            },
                            trailingContent = {
                                Column(horizontalAlignment = Alignment.End) {
                                    Text(item.timeAgo, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    if (item.unreadCount > 0) {
                                        Spacer(Modifier.height(4.dp))
                                        Pill("${item.unreadCount}", WhatsAppGreen)
                                    }
                                }
                            },
                            modifier = Modifier.clickable { onOpenConversation(item.id.toLongOrNull() ?: 0, item.customerName) }
                        )
                        Divider()
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConversationScreen(leadId: Long, name: String, onBack: () -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()
    var messages by remember { mutableStateOf<List<ChatMessage>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<Res.Err?>(null) }
    var draft by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var sendError by remember { mutableStateOf<String?>(null) }
    var aiEnabled by remember { mutableStateOf(true) }

    suspend fun load() {
        when (val res = repo.conversation(leadId)) {
            is Res.Ok -> { messages = res.data.messages; aiEnabled = res.data.aiEnabled; error = null }
            is Res.Err -> {
                val cached = repo.cachedConversation(leadId)
                if (cached != null) { messages = cached.messages; aiEnabled = cached.aiEnabled } else error = res
            }
        }
        loading = false
    }
    LaunchedEffect(leadId) { load() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(name.ifBlank { "Conversation" }) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") } },
                actions = {
                    Text("AI", style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(end = 6.dp))
                    Switch(
                        checked = aiEnabled,
                        onCheckedChange = { want ->
                            scope.launch {
                                when (val r = repo.setAi(leadId, want)) {
                                    is Res.Ok -> aiEnabled = r.data.aiEnabled
                                    is Res.Err -> sendError = r.message
                                }
                            }
                        },
                        modifier = Modifier.padding(end = 12.dp).semantics { contentDescription = "Let the AI reply to this customer" }
                    )
                }
            )
        },
        bottomBar = {
            Column {
                if (sendError != null) {
                    Text(sendError!!, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall, modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp))
                }
                Row(Modifier.padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(value = draft, onValueChange = { draft = it }, modifier = Modifier.weight(1f), placeholder = { Text("Message") })
                    IconButton(
                        enabled = !sending && draft.isNotBlank(),
                        onClick = {
                            sending = true
                            sendError = null
                            val text = draft.trim()
                            scope.launch {
                                when (val r = repo.reply(leadId, text)) {
                                    is Res.Ok -> { draft = ""; load() }
                                    is Res.Err -> sendError = r.message
                                }
                                sending = false
                            }
                        }
                    ) { Icon(Icons.AutoMirrored.Filled.Send, contentDescription = "Send") }
                }
            }
        }
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            if (aiEnabled) {
                Text(
                    "The AI is replying to this customer. Sending a message takes over.",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                    modifier = Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.secondaryContainer).padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            when {
                loading -> LoadingRow()
                error != null -> ErrorState(error!!, onRetry = { scope.launch { load() } })
                messages.isEmpty() -> EmptyState("No messages yet")
                else -> LazyColumn(modifier = Modifier.fillMaxSize(), contentPadding = PaddingValues(12.dp), reverseLayout = true, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(messages.reversed(), key = { it.id }) { m -> MessageBubble(m) }
                }
            }
        }
    }
}

@Composable
private fun MessageBubble(m: ChatMessage) {
    val mine = m.from != "customer"
    val bg = when (m.from) {
        "customer" -> MaterialTheme.colorScheme.surfaceVariant
        "ai" -> MaterialTheme.colorScheme.secondaryContainer
        else -> MaterialTheme.colorScheme.primaryContainer
    }
    Row(Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Card(colors = CardDefaults.cardColors(containerColor = bg), modifier = Modifier.fillMaxWidth(0.82f).wrapContentWidth(if (mine) Alignment.End else Alignment.Start)) {
            Column(Modifier.padding(10.dp)) {
                val label = when {
                    m.from == "ai" -> "AI reply"
                    m.from == "agent" && m.by.isNotBlank() -> m.by
                    else -> ""
                }
                if (label.isNotEmpty()) Text(label, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(m.text)
                Row(Modifier.align(Alignment.End), verticalAlignment = Alignment.CenterVertically) {
                    Text(Format.relative(m.at), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    val tick = Format.tick(m.delivery)
                    if (tick.isNotEmpty()) {
                        Spacer(Modifier.width(4.dp))
                        Text(
                            tick,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = when (m.delivery) {
                                "read" -> MaterialTheme.colorScheme.secondary
                                "failed" -> MaterialTheme.colorScheme.error
                                else -> MaterialTheme.colorScheme.onSurfaceVariant
                            },
                            modifier = Modifier.semantics { contentDescription = Format.tickLabel(m.delivery) }
                        )
                    }
                }
            }
        }
    }
}
