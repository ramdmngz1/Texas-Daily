package com.refuge.texasdaily.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.refuge.texasdaily.data.PreferenceKeys
import com.refuge.texasdaily.data.dataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val prefs = context.dataStore.data.first()
                val enabled = prefs[PreferenceKeys.REMINDER_ENABLED] ?: false
                if (enabled) {
                    val hour = prefs[PreferenceKeys.REMINDER_HOUR] ?: 9
                    val minute = prefs[PreferenceKeys.REMINDER_MINUTE] ?: 0
                    DailyReminderWorker.schedule(context, hour, minute)
                }
            } finally {
                pendingResult.finish()
            }
        }
    }
}
