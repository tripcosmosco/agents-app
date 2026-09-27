package co.tripcosmos.salesagents.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import co.tripcosmos.salesagents.SalesAgentsApp
import co.tripcosmos.salesagents.data.model.*
import co.tripcosmos.salesagents.data.repo.Res
import co.tripcosmos.salesagents.ui.components.Pill
import co.tripcosmos.salesagents.ui.theme.stageColor
import co.tripcosmos.salesagents.util.Format
import kotlinx.coroutines.launch

/** One trip: details, a line-item quote, and payment. Full-screen dialog so it has room for the quote table. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingSheet(initial: Booking, onDismiss: () -> Unit, onDone: (message: String?) -> Unit) {
    val repo = SalesAgentsApp.instance.repository
    val scope = rememberCoroutineScope()

    var booking by remember { mutableStateOf(initial) }
    var title by remember { mutableStateOf(initial.title) }
    var startDate by remember { mutableStateOf(initial.startDate.orEmpty()) }
    var endDate by remember { mutableStateOf(initial.endDate.orEmpty()) }
    var pax by remember { mutableStateOf(initial.pax.takeIf { it > 0 }?.toString() ?: "2") }
    var vehicle by remember { mutableStateOf(initial.vehicle) }
    var status by remember { mutableStateOf(initial.status) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    var lines by remember { mutableStateOf(listOf(QuoteLineBody("", 1.0, 0.0))) }
    var discount by remember { mutableStateOf("0") }
    var creatingQuote by remember { mutableStateOf(false) }
    var payAmount by remember { mutableStateOf("") }
    var payMethod by remember { mutableStateOf("upi") }
    var paying by remember { mutableStateOf(false) }
    var linkResult by remember { mutableStateOf<PaymentLinkResponse?>(null) }

    fun saveDetails(after: (Booking?) -> Unit) {
        saving = true; error = null
        scope.launch {
            val body = SaveBookingBody(
                leadId = booking.leadId, bookingId = booking.id, title = title.trim(),
                startDate = startDate.ifBlank { null }, endDate = endDate.ifBlank { null },
                pax = pax.toIntOrNull() ?: 1, vehicle = vehicle.trim(), status = status
            )
            when (val res = repo.saveBooking(body)) {
                is Res.Ok -> { booking = res.data.booking ?: booking; saving = false; after(booking) }
                is Res.Err -> { error = res.message; saving = false; after(null) }
            }
        }
    }

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(if (booking.id == 0L) "New trip" else booking.ref) },
                    navigationIcon = { IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, contentDescription = "Close") } }
                )
            }
        ) { padding ->
            LazyColumn(Modifier.padding(padding).fillMaxSize(), contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                item {
                    Card {
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Text("Trip details", fontWeight = FontWeight.SemiBold)
                            OutlinedTextField(value = title, onValueChange = { title = it }, label = { Text("Title") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                OutlinedTextField(value = startDate, onValueChange = { startDate = it }, label = { Text("Start (YYYY-MM-DD)") }, singleLine = true, modifier = Modifier.weight(1f))
                                OutlinedTextField(value = endDate, onValueChange = { endDate = it }, label = { Text("End") }, singleLine = true, modifier = Modifier.weight(1f))
                            }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                OutlinedTextField(value = pax, onValueChange = { pax = it.filter(Char::isDigit) }, label = { Text("Pax") }, singleLine = true, modifier = Modifier.weight(1f))
                                OutlinedTextField(value = vehicle, onValueChange = { vehicle = it }, label = { Text("Vehicle") }, singleLine = true, modifier = Modifier.weight(1f))
                            }
                            var statusMenu by remember { mutableStateOf(false) }
                            Box {
                                OutlinedButton(onClick = { statusMenu = true }) { Text(Format.stageLabel(status)) }
                                DropdownMenu(expanded = statusMenu, onDismissRequest = { statusMenu = false }) {
                                    listOf("quoted", "confirmed", "advance_paid", "paid", "completed", "cancelled").forEach { s ->
                                        DropdownMenuItem(text = { Text(Format.stageLabel(s)) }, onClick = { statusMenu = false; status = s })
                                    }
                                }
                            }
                            if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                            Button(onClick = { saveDetails {} }, enabled = !saving && title.isNotBlank(), modifier = Modifier.fillMaxWidth()) {
                                Text(if (saving) "Saving…" else "Save details")
                            }
                        }
                    }
                }

                item {
                    Card {
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("Quote", fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                                if (booking.quote != null) Pill(booking.quote!!.status, stageColor(booking.quote!!.status))
                            }
                            if (booking.id == 0L) {
                                Text("Save the trip details first, then add a quote.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            } else if (booking.quote != null) {
                                booking.quote!!.items.forEach { li ->
                                    Row(Modifier.fillMaxWidth()) { Text(li.description, modifier = Modifier.weight(1f)); Text(Format.inr(li.amount)) }
                                }
                                Divider()
                                Row(Modifier.fillMaxWidth()) { Text("Total", fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f)); Text(Format.inr(booking.total), fontWeight = FontWeight.Bold) }
                                Text("Advance ${Format.inr(booking.quote!!.advanceAmount)} · Balance ${Format.inr(booking.balance)}", style = MaterialTheme.typography.bodySmall)
                                Button(onClick = {
                                    scope.launch { repo.sendQuote(booking.quote!!.id); onDone("Quote sent on WhatsApp") }
                                }, modifier = Modifier.fillMaxWidth()) { Text("Send quote on WhatsApp") }
                            } else {
                                lines.forEachIndexed { i, l ->
                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                                        OutlinedTextField(value = l.description, onValueChange = { v -> lines = lines.toMutableList().also { it[i] = l.copy(description = v) } }, label = { Text("Item") }, singleLine = true, modifier = Modifier.weight(2f))
                                        OutlinedTextField(value = if (l.qty == l.qty.toLong().toDouble()) l.qty.toLong().toString() else l.qty.toString(), onValueChange = { v -> lines = lines.toMutableList().also { it[i] = l.copy(qty = v.toDoubleOrNull() ?: l.qty) } }, label = { Text("Qty") }, singleLine = true, modifier = Modifier.weight(1f))
                                        OutlinedTextField(value = if (l.price == 0.0) "" else l.price.toLong().toString(), onValueChange = { v -> lines = lines.toMutableList().also { it[i] = l.copy(price = v.toDoubleOrNull() ?: 0.0) } }, label = { Text("Price") }, singleLine = true, modifier = Modifier.weight(1f))
                                    }
                                }
                                TextButton(onClick = { lines = lines + QuoteLineBody("", 1.0, 0.0) }) { Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp)); Text("Add line") }
                                OutlinedTextField(value = discount, onValueChange = { discount = it.filter(Char::isDigit) }, label = { Text("Discount (₹)") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                                Button(
                                    enabled = !creatingQuote && lines.any { it.description.isNotBlank() && it.price > 0 },
                                    onClick = {
                                        creatingQuote = true
                                        scope.launch {
                                            val valid = lines.filter { it.description.isNotBlank() && it.price > 0 }
                                            when (val res = repo.createQuote(CreateQuoteBody(booking.id, valid, discount.toDoubleOrNull() ?: 0.0))) {
                                                is Res.Ok -> { booking = res.data.booking ?: booking; creatingQuote = false }
                                                is Res.Err -> { error = res.message; creatingQuote = false }
                                            }
                                        }
                                    },
                                    modifier = Modifier.fillMaxWidth()
                                ) { Text(if (creatingQuote) "Creating…" else "Create quote") }
                            }
                        }
                    }
                }

                if (booking.id != 0L && booking.balance > 0) {
                    item {
                        Card {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("Payment · balance ${Format.inr(booking.balance)}", fontWeight = FontWeight.SemiBold)
                                OutlinedTextField(value = payAmount, onValueChange = { payAmount = it.filter(Char::isDigit) }, label = { Text("Amount") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    listOf("upi" to "UPI", "cash" to "Cash", "bank" to "Bank", "card" to "Card").forEach { (id, label) ->
                                        FilterChip(selected = payMethod == id, onClick = { payMethod = id }, label = { Text(label) })
                                    }
                                }
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    OutlinedButton(
                                        enabled = !paying && payAmount.isNotBlank(),
                                        onClick = {
                                            paying = true
                                            scope.launch {
                                                when (val res = repo.paymentLink(booking.id, payAmount.toDouble(), "")) {
                                                    is Res.Ok -> { linkResult = res.data; paying = false }
                                                    is Res.Err -> { error = res.message; paying = false }
                                                }
                                            }
                                        }, modifier = Modifier.weight(1f)
                                    ) { Text("Get link") }
                                    Button(
                                        enabled = !paying && payAmount.isNotBlank(),
                                        onClick = {
                                            paying = true
                                            scope.launch {
                                                when (val res = repo.recordPayment(booking.id, payAmount.toDouble(), payMethod, "")) {
                                                    is Res.Ok -> { booking = res.data.booking ?: booking; paying = false; payAmount = "" }
                                                    is Res.Err -> { error = res.message; paying = false }
                                                }
                                            }
                                        }, modifier = Modifier.weight(1f)
                                    ) { Text("Record received") }
                                }
                                linkResult?.let { l ->
                                    Text(if (l.provider == "cashfree") "Cashfree link ready — share it from your notifications." else "No gateway configured — use the UPI link below.", style = MaterialTheme.typography.bodySmall)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
