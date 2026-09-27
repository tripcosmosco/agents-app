package co.tripcosmos.salesagents.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.DashboardResponse
import co.tripcosmos.salesagents.data.model.Lead
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.ui.components.*
import co.tripcosmos.salesagents.ui.theme.stageColor
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(onOpenLead: (Long) -> Unit, onOpenTasks: () -> Unit, onOpenSettings: () -> Unit = {}) {
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()
    var state by remember { mutableStateOf<Res<DashboardResponse>?>(null) }
    var stale by remember { mutableStateOf(false) }
    var refreshing by remember { mutableStateOf(false) }

    suspend fun load() {
        refreshing = true
        when (val res = repo.dashboard()) {
            is Res.Ok -> { state = res; stale = false }
            is Res.Err -> {
                val cached = repo.cachedDashboard()
                if (cached != null) { state = Res.Ok(cached); stale = true } else state = res
            }
        }
        refreshing = false
    }
    LaunchedEffect(Unit) { load() }

    Scaffold(topBar = {
        TopAppBar(title = { Text("Today", fontWeight = FontWeight.Bold) }, actions = {
            IconButton(onClick = { scope.launch { load() } }, enabled = !refreshing) {
                if (refreshing) CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                else Icon(Icons.Default.Refresh, contentDescription = "Refresh")
            }
            IconButton(onClick = onOpenSettings) { Icon(Icons.Default.Settings, contentDescription = "Settings") }
        })
    }) { padding ->
        Box(Modifier.padding(padding)) {
            when (val s = state) {
                null -> LoadingRow()
                is Res.Ok -> {
                    Column {
                        if (stale) OfflineBanner()
                        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                            item { KpiGrid(s.data, onOpenTasks) }
                            item { PipelineRow(s.data) }
                            if (s.data.hot.isNotEmpty()) {
                                item { SectionLabel("Needs attention") }
                                items(s.data.hot, key = { it.id }) { lead -> HotLeadCard(lead, onClick = { onOpenLead(lead.id) }) }
                            }
                        }
                    }
                }
                is Res.Err -> ErrorState(s, onRetry = { scope.launch { load() } })
            }
        }
    }
}

@Composable
private fun KpiGrid(d: DashboardResponse, onOpenTasks: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
            Kpi("New leads today", "${d.today.newLeads}", Modifier.weight(1f))
            Kpi("Calls today", "${d.today.calls}", Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
            Kpi("Collected today", Format.inrCompact(d.today.collected), Modifier.weight(1f))
            Kpi(
                "Follow-ups due", "${d.today.tasksDue + d.today.tasksOverdue}",
                Modifier.weight(1f), highlight = d.today.tasksOverdue > 0, onClick = onOpenTasks
            )
        }
    }
}

@Composable
private fun Kpi(label: String, value: String, modifier: Modifier = Modifier, highlight: Boolean = false, onClick: (() -> Unit)? = null) {
    ElevatedCard(modifier = modifier, onClick = { onClick?.invoke() } ) {
        Column(Modifier.padding(14.dp)) {
            Text(value, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = if (highlight) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface)
            Text(label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun PipelineRow(d: DashboardResponse) {
    if (d.pipeline.isEmpty()) return
    val total = d.pipeline.sumOf { it.count }.coerceAtLeast(1)
    Column {
        SectionLabel("Pipeline")
        Card {
            Column(Modifier.padding(14.dp)) {
                Row(Modifier.fillMaxWidth().height(10.dp)) {
                    d.pipeline.forEach { p ->
                        Box(Modifier.weight((p.count.toFloat() / total).coerceAtLeast(0.02f)).fillMaxHeight().background(stageColor(p.stage)))
                    }
                }
                Spacer(Modifier.height(10.dp))
                d.pipeline.forEach { p ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 2.dp)) {
                        Box(Modifier.size(8.dp).clip(RoundedCornerShape(50)).background(stageColor(p.stage)))
                        Spacer(Modifier.width(8.dp))
                        Text(Format.stageLabel(p.stage), modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium)
                        Text("${p.count} · ${Format.inrCompact(p.value)}", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                    }
                }
            }
        }
    }
}

@Composable
private fun HotLeadCard(lead: Lead, onClick: () -> Unit) {
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            InitialsAvatar(lead.name)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(lead.name.ifBlank { "Traveler" }, fontWeight = FontWeight.SemiBold)
                Text(
                    listOf(lead.destination, Format.phone(lead.phone)).filter { it.isNotBlank() }.joinToString(" · "),
                    style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (lead.dealValue > 0) Text(Format.inrCompact(lead.dealValue), fontWeight = FontWeight.SemiBold)
        }
    }
}
