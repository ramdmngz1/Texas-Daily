@file:OptIn(ExperimentalMaterial3Api::class)

package com.refuge.texasdaily.ui.screens

import android.app.Activity
import android.text.format.DateFormat
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TimePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.refuge.texasdaily.ui.theme.AccentGreen
import com.refuge.texasdaily.viewmodel.TexasViewModel
import java.util.Calendar

@Composable
fun SettingsScreen(
    viewModel: TexasViewModel,
    onClose: () -> Unit
) {
    val context = LocalContext.current
    val reminderEnabled by viewModel.reminderEnabled.collectAsState()
    val reminderHour by viewModel.reminderHour.collectAsState()
    val reminderMinute by viewModel.reminderMinute.collectAsState()
    val isDarkMode by viewModel.isDarkMode.collectAsState()
    val adsRemoved by viewModel.billingManager.adsRemoved.collectAsState()
    val billingStatus by viewModel.billingManager.statusMessage.collectAsState()

    var localReminderEnabled by remember { mutableStateOf(reminderEnabled) }
    val timePickerState: TimePickerState = rememberTimePickerState(
        initialHour = reminderHour,
        initialMinute = reminderMinute
    )

    LaunchedEffect(reminderEnabled) { localReminderEnabled = reminderEnabled }
    LaunchedEffect(localReminderEnabled, timePickerState.hour, timePickerState.minute) {
        if (localReminderEnabled) {
            viewModel.saveReminder(true, timePickerState.hour, timePickerState.minute)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onClose) {
                Icon(Icons.Default.Close, contentDescription = "Close settings")
            }
            Text(
                "Settings",
                style = MaterialTheme.typography.headlineSmall,
                modifier = Modifier.weight(1f).padding(start = 8.dp)
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(Modifier.height(4.dp))

            // Appearance section
            SettingsCard {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        if (isDarkMode) Icons.Default.DarkMode else Icons.Default.LightMode,
                        contentDescription = null,
                        tint = AccentGreen,
                        modifier = Modifier.padding(end = 12.dp)
                    )
                    Column(Modifier.weight(1f)) {
                        Text("Appearance", style = MaterialTheme.typography.labelLarge)
                        Text(
                            if (isDarkMode) "Dark" else "Light",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                        )
                    }
                    Switch(
                        checked = isDarkMode,
                        onCheckedChange = { viewModel.setDarkMode(it) },
                        colors = SwitchDefaults.colors(checkedThumbColor = AccentGreen, checkedTrackColor = AccentGreen.copy(alpha = 0.4f))
                    )
                }
            }

            // Daily reminder section
            SettingsCard {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Notifications,
                            contentDescription = null,
                            tint = AccentGreen,
                            modifier = Modifier.padding(end = 12.dp)
                        )
                        Text("Daily Reminder", style = MaterialTheme.typography.labelLarge, modifier = Modifier.weight(1f))
                        Switch(
                            checked = localReminderEnabled,
                            onCheckedChange = {
                                localReminderEnabled = it
                                viewModel.saveReminder(it, timePickerState.hour, timePickerState.minute)
                            },
                            colors = SwitchDefaults.colors(checkedThumbColor = AccentGreen, checkedTrackColor = AccentGreen.copy(alpha = 0.4f))
                        )
                    }

                    if (localReminderEnabled) {
                        Spacer(Modifier.height(16.dp))
                        HorizontalDivider()
                        Spacer(Modifier.height(16.dp))
                        TimePicker(
                            state = timePickerState,
                            modifier = Modifier.align(Alignment.CenterHorizontally)
                        )
                        Spacer(Modifier.height(8.dp))
                        val savedTime = formatTime(context, timePickerState.hour, timePickerState.minute)
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Notifications,
                                contentDescription = null,
                                tint = AccentGreen,
                                modifier = Modifier.padding(end = 8.dp)
                            )
                            Text(
                                "Reminder is ON. Saved time: $savedTime.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.9f)
                            )
                        }
                    }
                }
            }

            // Support section
            if (!adsRemoved) {
                SettingsCard {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text("Support Us", style = MaterialTheme.typography.labelLarge)
                        HorizontalDivider()
                        Button(
                            onClick = {
                                val activity = context as? Activity ?: return@Button
                            viewModel.billingManager.purchaseRemoveAds(activity)
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = AccentGreen),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Remove Ads — \$1.99", color = Color.White)
                        }
                        OutlinedButton(
                            onClick = { viewModel.billingManager.restorePurchases() },
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Restore Purchases")
                        }
                        billingStatus?.let { msg ->
                            Text(
                                msg,
                                style = MaterialTheme.typography.bodyMedium,
                                color = AccentGreen
                            )
                            LaunchedEffect(msg) {
                                kotlinx.coroutines.delay(3000)
                                viewModel.billingManager.clearStatusMessage()
                            }
                        }
                    }
                }
            }

            // About section
            SettingsCard {
                Column {
                    Text("About", style = MaterialTheme.typography.labelLarge)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "Texas Daily delivers one curated Texas fact each day — from history and culture to geography and beyond. Explore 600+ fascinating facts about the Lone Star State.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                    )
                }
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun SettingsCard(content: @Composable () -> Unit) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(20.dp)) {
            content()
        }
    }
}

private fun formatTime(context: android.content.Context, hour: Int, minute: Int): String {
    val cal = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, hour)
        set(Calendar.MINUTE, minute)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    return DateFormat.getTimeFormat(context).format(cal.time)
}
