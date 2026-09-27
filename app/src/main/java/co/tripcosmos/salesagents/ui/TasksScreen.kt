package co.tripcosmos.salesagents.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.Task
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.telephony.DialerManager
import co.tripcosmos.salesagents.ui.components.*
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.launch
import androidx.compose.ui.platform.LocalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TasksScreen(onOpenLead: (Long) -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var filter by remember { mutableStateOf("overdue") }
    var tasks by remember { mutableStateOf<List<Task>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<Res.Err?>(null) }
    var stale by remember { mutableStateOf(false) }

    suspend fun load() {
        loading = true
        when (val res = repo.tasks(filter)) {
            is Res.Ok -> { tasks = res.data.tasks; stale = false; error = null }
            is Res.Err -> {
                val cached = repo.cachedTasks(filter)
                if (cached != null) { tasks = cached.tasks; stale = true } else { error = res; tasks = emptyList() }
            }
        }
        loading = false
    }
    LaunchedEffect(filter) { load() }

    Scaffold(topBar = { TopAppBar(title = { Text("Follow-ups", fontWeight = FontWeight.Bold) }) }) { padding ->
        Column(Modifier.padding(padding)) {
            ScrollableTabRow(selectedTabIndex = listOf("overdue", "today", "upcoming", "done").indexOf(filter), edgePadding = 16.dp) {
                listOf("overdue" to "Overdue", "today" to "Today", "upcoming" to "Upcoming", "done" to "Done").forEach { (id, label) ->
                    Tab(selected = filter == id, onClick = { filter = id }, text = { Text(label) })
                }
            }
            if (stale) OfflineBanner()
            when {
                loading -> LoadingRow()
                error != null -> ErrorState(error!!, onRetry = { scope.launch { load() } })
                tasks.isEmpty() -> EmptyState("Nothing here", "You're all caught up")
                else -> LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(tasks, key = { it.id }) { t ->
                        val due = Format.due(t.dueAt)
                        Card(onClick = { onOpenLead(t.leadId) }) {
                            Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                                if (filter != "done") {
                                    Checkbox(checked = false, onCheckedChange = { scope.launch { if (repo.completeTask(t.id) is Res.Ok) load() } })
                                }
                                Column(Modifier.weight(1f)) {
                                    Text(t.content, fontWeight = FontWeight.Medium)
                                    Text(t.name.ifBlank { "Traveler" }, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    if (due != null) Text(due.text, style = MaterialTheme.typography.labelSmall, color = if (due.overdue) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                                if (t.phone.isNotBlank() && filter != "done") {
                                    IconButton(onClick = { DialerManager.call(context, t.phone) }) {
                                        Icon(Icons.Default.Call, contentDescription = "Call")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
