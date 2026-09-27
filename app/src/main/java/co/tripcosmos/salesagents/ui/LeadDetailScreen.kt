package co.tripcosmos.salesagents.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.*
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.telephony.DialerManager
import co.tripcosmos.salesagents.ui.components.*
import co.tripcosmos.salesagents.ui.theme.stageColor
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeadDetailScreen(leadId: Long, onBack: () -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var detail by remember { mutableStateOf<LeadDetailResponse?>(null) }
    var error by remember { mutableStateOf<Res.Err?>(null) }
    var stale by remember { mutableStateOf(false) }
    var tab by remember { mutableStateOf(0) }
    var showSummarize by remember { mutableStateOf(false) }
    var showAddTask by remember { mutableStateOf(false) }
    var showBooking by remember { mutableStateOf<Booking?>(null) }
    var snack by remember { mutableStateOf<String?>(null) }

    suspend fun load() {
        when (val res = repo.lead(leadId)) {
            is Res.Ok -> { detail = res.data; stale = false; error = null }
            is Res.Err -> {
                val cached = repo.cachedLead(leadId)
                if (cached != null) { detail = cached; stale = true } else error = res
            }
        }
    }
    LaunchedEffect(leadId) { load() }

    val snackHost = remember { SnackbarHostState() }
    LaunchedEffect(snack) { snack?.let { snackHost.showSnackbar(it); snack = null } }

    Scaffold(
        snackbarHost = { SnackbarHost(snackHost) },
        topBar = {
            TopAppBar(
                title = { Text(detail?.lead?.name?.ifBlank { "Traveler" } ?: "Lead", fontWeight = FontWeight.Bold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") } }
            )
        }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            val d = detail
            when {
                d == null && error != null -> ErrorState(error!!, onRetry = { scope.launch { load() } })
                d == null -> LoadingRow()
                else -> Column {
                    if (stale) OfflineBanner()
                    LeadHeader(
                        d.lead,
                        onCall = { DialerManager.call(context, d.lead.phone) },
                        onWhatsApp = { DialerManager.openWhatsApp(context, d.lead.phone) },
                        onStage = { stage -> scope.launch { if (repo.setStage(leadId, stage) is Res.Ok) load() } }
                    )
                    TabRow(selectedTabIndex = tab) {
                        listOf("Overview", "Tasks", "Trip").forEachIndexed { i, t -> Tab(selected = tab == i, onClick = { tab = i }, text = { Text(t) }) }
                    }
                    when (tab) {
                        0 -> OverviewTab(d, onSummarize = { showSummarize = true })
                        1 -> TasksTab(d.tasks, onAdd = { showAddTask = true }, onComplete = { id ->
                            scope.launch { if (repo.completeTask(id) is Res.Ok) load() }
                        })
                        else -> TripTab(d.bookings, onNewBooking = { showBooking = Booking(leadId = leadId) }, onOpenBooking = { showBooking = it })
                    }
                }
            }
        }
    }

    if (showSummarize) {
        SummarizeSheet(leadId, onDismiss = { showSummarize = false }, onDone = { showSummarize = false; scope.launch { load() } })
    }
    if (showAddTask) {
        AddTaskSheet(leadId, onDismiss = { showAddTask = false }, onDone = { showAddTask = false; scope.launch { load() } })
    }
    showBooking?.let { b ->
        BookingSheet(b, onDismiss = { showBooking = null }, onDone = { msg -> showBooking = null; snack = msg; scope.launch { load() } })
    }
}

@Composable
private fun LeadHeader(lead: Lead, onCall: () -> Unit, onWhatsApp: () -> Unit, onStage: (String) -> Unit) {
    var stageMenu by remember { mutableStateOf(false) }
    Column(Modifier.padding(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            InitialsAvatar(lead.name, size = 52)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(Format.phone(lead.phone), style = MaterialTheme.typography.bodyMedium)
                if (lead.destination.isNotBlank()) Text(lead.destination, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
            }
            if (lead.dealValue > 0) Text(Format.inrCompact(lead.dealValue), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = onCall, modifier = Modifier.weight(1f)) { Icon(Icons.Default.Call, contentDescription = null, modifier = Modifier.size(18.dp)); Spacer(Modifier.width(6.dp)); Text("Call") }
            OutlinedButton(onClick = onWhatsApp, modifier = Modifier.weight(1f)) { Text("WhatsApp") }
            Box {
                OutlinedButton(onClick = { stageMenu = true }) { Text(Format.stageLabel(lead.stage)) }
                DropdownMenu(expanded = stageMenu, onDismissRequest = { stageMenu = false }) {
                    listOf("inquiry", "qualified", "proposal", "negotiation", "won", "completed", "lost").forEach { s ->
                        DropdownMenuItem(text = { Text(Format.stageLabel(s)) }, onClick = { stageMenu = false; onStage(s) })
                    }
                }
            }
        }
    }
}

@Composable
private fun OverviewTab(d: LeadDetailResponse, onSummarize: () -> Unit) {
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Card {
                Column(Modifier.padding(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("AI call summary", fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                        TextButton(onClick = onSummarize) { Text("Summarize a call") }
                    }
                    val mem = d.memory
                    if (mem == null || mem.summary.isBlank()) {
                        Text("No summary yet. After a call, tap \"Summarize a call\" and paste your notes.", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
                    } else {
                        Text(mem.summary, style = MaterialTheme.typography.bodyMedium)
                        if (mem.facts.isNotEmpty()) {
                            Spacer(Modifier.height(8.dp))
                            mem.facts.forEach { Text("•  $it", style = MaterialTheme.typography.bodySmall) }
                        }
                        if (mem.nextBestAction.isNotBlank()) {
                            Spacer(Modifier.height(8.dp))
                            Text("Next: ${mem.nextBestAction}", fontWeight = FontWeight.Medium, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }
        }
        if (d.lead.requirements.isNotBlank()) {
            item { InfoCard("Requirements", d.lead.requirements) }
        }
        item { SectionLabel("Activity") }
        if (d.activities.isEmpty()) {
            item { EmptyState("Nothing logged yet") }
        } else {
            items(d.activities, key = { it.id }) { ActivityRow(it) }
        }
    }
}

@Composable
private fun InfoCard(title: String, body: String) {
    Card(Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp)) { Text(title, fontWeight = FontWeight.SemiBold); Text(body, style = MaterialTheme.typography.bodyMedium) } }
}

@Composable
private fun ActivityRow(a: Activity) {
    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
        Text(activityIcon(a.type), modifier = Modifier.width(28.dp))
        Column(Modifier.weight(1f)) {
            Text(a.content, style = MaterialTheme.typography.bodyMedium)
            Text(Format.relative(a.createdAt), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

private fun activityIcon(type: String) = when (type) {
    "call" -> "📞"; "whatsapp" -> "💬"; "email" -> "✉️"; "booking" -> "🧳"; "task" -> "✅"; "system" -> "•"; else -> "📝"
}

@Composable
private fun TasksTab(tasks: List<Activity>, onAdd: () -> Unit, onComplete: (Long) -> Unit) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.padding(16.dp, 16.dp, 16.dp, 0.dp)) {
            Spacer(Modifier.weight(1f))
            TextButton(onClick = onAdd) { Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(18.dp)); Text("Add follow-up") }
        }
        if (tasks.isEmpty()) {
            EmptyState("No open follow-ups", "Add one so this lead is not forgotten")
        } else {
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(tasks, key = { it.id }) { t ->
                    val due = Format.due(t.dueAt)
                    Card {
                        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(checked = false, onCheckedChange = { onComplete(t.id) })
                            Column(Modifier.weight(1f)) {
                                Text(t.content)
                                if (due != null) Text(due.text, color = if (due.overdue) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TripTab(bookings: List<Booking>, onNewBooking: () -> Unit, onOpenBooking: (Booking) -> Unit) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.padding(16.dp, 16.dp, 16.dp, 0.dp)) {
            Spacer(Modifier.weight(1f))
            TextButton(onClick = onNewBooking) { Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(18.dp)); Text("New trip") }
        }
        if (bookings.isEmpty()) {
            EmptyState("No trip yet", "Create one to quote, invoice and take payment")
        } else {
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(bookings, key = { it.id }) { b ->
                    Card(onClick = { onOpenBooking(b) }) {
                        Column(Modifier.padding(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(b.title.ifBlank { b.ref }, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                                Pill(Format.stageLabel(b.status), stageColor(b.status))
                            }
                            if (!b.startDate.isNullOrBlank()) Text("${b.startDate} → ${b.endDate.orEmpty()} · ${b.pax} pax", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Spacer(Modifier.height(6.dp))
                            Row {
                                Text("Total ${Format.inr(b.total)}", style = MaterialTheme.typography.bodySmall)
                                Spacer(Modifier.width(12.dp))
                                if (b.balance > 0) Text("Balance ${Format.inr(b.balance)}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                                else if (b.total > 0) Text("Paid in full", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SummarizeSheet(leadId: Long, onDismiss: () -> Unit, onDone: () -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()
    var notes by remember { mutableStateOf("") }
    var createTask by remember { mutableStateOf(true) }
    var working by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var result by remember { mutableStateOf<SummaryResponse?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (result != null) "Summary ready" else "Summarize this call") },
        text = {
            if (result != null) {
                Column {
                    Text(result!!.summary)
                    if (result!!.nextBestAction.isNotBlank()) { Spacer(Modifier.height(8.dp)); Text("Next: ${result!!.nextBestAction}", fontWeight = FontWeight.Medium) }
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Type what the customer said (or paste the transcript). The AI extracts facts — nothing is invented.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    OutlinedTextField(value = notes, onValueChange = { notes = it }, minLines = 4, modifier = Modifier.fillMaxWidth(), placeholder = { Text("e.g. Wants 4 nights Varanasi + Ayodhya in October, 4 adults, budget ~80,000, 4-star hotel") })
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = createTask, onCheckedChange = { createTask = it })
                        Text("Create a follow-up task")
                    }
                    if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                }
            }
        },
        confirmButton = {
            if (result != null) TextButton(onClick = onDone) { Text("Done") }
            else TextButton(enabled = !working && notes.trim().length >= 10, onClick = {
                working = true
                scope.launch {
                    when (val res = repo.summarize(leadId, SummarizeBody(notes = notes.trim(), createTask = createTask))) {
                        is Res.Ok -> { result = res.data; working = false }
                        is Res.Err -> { error = res.message; working = false }
                    }
                }
            }) { Text(if (working) "Thinking…" else "Summarize") }
        },
        dismissButton = if (result == null) ({ TextButton(onClick = onDismiss) { Text("Cancel") } }) else null
    )
}

@Composable
private fun AddTaskSheet(leadId: Long, onDismiss: () -> Unit, onDone: () -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()
    var content by remember { mutableStateOf("") }
    var days by remember { mutableStateOf(1) }
    var saving by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add follow-up") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(value = content, onValueChange = { content = it }, label = { Text("What to do") }, modifier = Modifier.fillMaxWidth())
                Text("When", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf(1 to "Tomorrow", 3 to "In 3 days", 7 to "In a week").forEach { (n, label) ->
                        FilterChip(selected = days == n, onClick = { days = n }, label = { Text(label) })
                    }
                }
            }
        },
        confirmButton = {
            TextButton(enabled = !saving && content.isNotBlank(), onClick = {
                saving = true
                val due = java.time.ZonedDateTime.now().plusDays(days.toLong()).withHour(11).withMinute(0).withSecond(0)
                scope.launch {
                    when (repo.createTask(leadId, content.trim(), Format.toIsoUtc(due))) {
                        is Res.Ok -> onDone()
                        is Res.Err -> saving = false
                    }
                }
            }) { Text(if (saving) "Saving…" else "Add") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
