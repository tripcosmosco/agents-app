package co.tripcosmos.salesagents.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.SummarizeBody
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.telephony.CallTracker
import co.tripcosmos.salesagents.telephony.FinishedCall
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.launch

/**
 * Shown right after a call ends (from the notification, or automatically if the app is foregrounded).
 * The call itself was already logged by [co.tripcosmos.salesagents.telephony.PhoneStateReceiver]; this
 * only offers to turn the agent's notes into an AI summary on the matching lead.
 */
@Composable
fun PostCallScreen(onOpenLead: (Long) -> Unit, onDismiss: () -> Unit) {
    val call = remember { CallTracker.lastCall() }
    if (call == null) {
        LaunchedEffect(Unit) { onDismiss() }
        return
    }
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()
    var notes by remember { mutableStateOf("") }
    var working by remember { mutableStateOf(false) }
    var leadId by remember { mutableStateOf<Long?>(null) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(call.number) {
        when (val res = repo.callerId(call.number)) {
            is Res.Ok -> leadId = res.data.contact?.id
            is Res.Err -> {}
        }
    }

    AlertDialog(
        onDismissRequest = { CallTracker.clearLastCall(); onDismiss() },
        title = { Text(titleFor(call)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(Format.phone(call.number), style = MaterialTheme.typography.bodyMedium)
                if (call.answered && call.durationSeconds > 0) {
                    OutlinedTextField(
                        value = notes, onValueChange = { notes = it }, minLines = 3, modifier = Modifier.fillMaxWidth(),
                        label = { Text("What did they say?") },
                        placeholder = { Text("e.g. Wants 4 nights Varanasi in October, 4 adults") }
                    )
                }
                if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }
        },
        confirmButton = {
            when {
                leadId == null -> TextButton(onClick = { CallTracker.clearLastCall(); onDismiss() }) { Text("Close") }
                notes.trim().length >= 10 -> TextButton(enabled = !working, onClick = {
                    working = true
                    scope.launch {
                        when (repo.summarize(leadId!!, SummarizeBody(notes = notes.trim(), createTask = true))) {
                            is Res.Ok -> { CallTracker.clearLastCall(); onOpenLead(leadId!!) }
                            is Res.Err -> { error = "Saved to the lead's notes; the AI summary failed."; working = false }
                        }
                    }
                }) { Text(if (working) "Saving…" else "Save summary") }
                else -> TextButton(onClick = { CallTracker.clearLastCall(); onOpenLead(leadId!!) }) { Text("Open lead") }
            }
        },
        dismissButton = { TextButton(onClick = { CallTracker.clearLastCall(); onDismiss() }) { Text("Skip") } }
    )
}

private fun titleFor(call: FinishedCall): String = when {
    call.callType == "missed" -> "Missed call"
    !call.answered -> "Call not answered"
    else -> "Call ended · ${Format.duration(call.durationSeconds)}"
}
