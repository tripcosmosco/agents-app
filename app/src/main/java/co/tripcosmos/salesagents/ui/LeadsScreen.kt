package co.tripcosmos.salesagents.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.Lead
import co.tripcosmos.salesagents.data.model.MeResponse
import co.tripcosmos.salesagents.data.model.Option
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.telephony.DialerManager
import co.tripcosmos.salesagents.ui.components.*
import co.tripcosmos.salesagents.ui.theme.stageColor
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.ui.platform.LocalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeadsScreen(onOpenLead: (Long) -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var query by remember { mutableStateOf("") }
    var stage by remember { mutableStateOf("all") }
    var stages by remember { mutableStateOf(listOf(Option("all", "All"))) }
    var leads by remember { mutableStateOf<List<Lead>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<Res.Err?>(null) }
    var stale by remember { mutableStateOf(false) }
    var showAdd by remember { mutableStateOf(false) }

    suspend fun load(showSpinner: Boolean = true) {
        if (showSpinner) loading = true
        error = null
        when (val res = repo.leads(stage, null, query.trim().ifBlank { null }, "updated", 0)) {
            is Res.Ok -> { leads = res.data.leads; stale = false }
            is Res.Err -> {
                val cached = if (stage == "all" && query.isBlank()) repo.cachedLeads() else null
                if (cached != null) { leads = cached.leads; stale = true } else { error = res; leads = emptyList() }
            }
        }
        loading = false
    }

    LaunchedEffect(Unit) {
        (repo.cachedMe() ?: (repo.me() as? Res.Ok)?.data)?.let { m: MeResponse -> stages = listOf(Option("all", "All")) + m.stages }
        load()
    }
    // Debounced search-as-you-type.
    LaunchedEffect(query) { delay(350); load(showSpinner = false) }
    LaunchedEffect(stage) { load() }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Leads", fontWeight = FontWeight.Bold) }) },
        floatingActionButton = { FloatingActionButton(onClick = { showAdd = true }) { Icon(Icons.Default.Add, contentDescription = "Add lead") } }
    ) { padding ->
        Column(Modifier.padding(padding)) {
            OutlinedTextField(
                value = query, onValueChange = { query = it },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                placeholder = { Text("Search name, phone, destination") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
            )
            ScrollableTabRow(selectedTabIndex = stages.indexOfFirst { it.id == stage }.coerceAtLeast(0), edgePadding = 16.dp) {
                stages.forEach { s -> Tab(selected = s.id == stage, onClick = { stage = s.id }, text = { Text(s.label) }) }
            }
            if (stale) OfflineBanner()

            when {
                loading -> LoadingRow()
                error != null -> ErrorState(error!!, onRetry = { scope.launch { load() } })
                leads.isEmpty() -> EmptyState("No leads here", if (query.isNotBlank()) "Try a different search" else "New enquiries will show up here")
                else -> LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(leads, key = { it.id }) { lead ->
                        LeadRow(lead, onClick = { onOpenLead(lead.id) }, onCall = { DialerManager.call(context, lead.phone) })
                    }
                }
            }
        }
    }

    if (showAdd) {
        AddLeadSheet(onDismiss = { showAdd = false }, onCreated = { showAdd = false; scope.launch { load() } })
    }
}

@Composable
private fun LeadRow(lead: Lead, onClick: () -> Unit, onCall: () -> Unit) {
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            InitialsAvatar(lead.name)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(lead.name.ifBlank { "Traveler" }, fontWeight = FontWeight.SemiBold)
                Text(
                    listOfNotNull(lead.destination.takeIf { it.isNotBlank() }, Format.phone(lead.phone)).joinToString(" · "),
                    style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(4.dp))
                Row {
                    Pill(Format.stageLabel(lead.stage), stageColor(lead.stage))
                    if (lead.dealValue > 0) {
                        Spacer(Modifier.width(6.dp))
                        Text(Format.inrCompact(lead.dealValue), style = MaterialTheme.typography.labelMedium, modifier = Modifier.align(Alignment.CenterVertically))
                    }
                }
            }
            IconButton(onClick = onCall) { Icon(Icons.Default.Call, contentDescription = "Call") }
        }
    }
}

@Composable
private fun AddLeadSheet(onDismiss: () -> Unit, onCreated: () -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()
    var name by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var destination by remember { mutableStateOf("") }
    var pax by remember { mutableStateOf("") }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New lead") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = phone, onValueChange = { phone = it }, label = { Text("Phone") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = destination, onValueChange = { destination = it }, label = { Text("Destination") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = pax, onValueChange = { pax = it.filter(Char::isDigit) }, label = { Text("Travellers") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }
        },
        confirmButton = {
            TextButton(
                enabled = !saving,
                onClick = {
                    saving = true
                    scope.launch {
                        when (val res = repo.createLead(co.tripcosmos.salesagents.data.model.CreateLeadBody(
                            name = name.trim(), phone = phone.trim(), destination = destination.trim(), pax = pax.toIntOrNull() ?: 0
                        ))) {
                            is Res.Ok -> onCreated()
                            is Res.Err -> { error = res.message; saving = false }
                        }
                    }
                }
            ) { Text(if (saving) "Saving…" else "Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
