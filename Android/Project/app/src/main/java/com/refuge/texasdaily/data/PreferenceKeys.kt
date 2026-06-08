package com.refuge.texasdaily.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "texas_daily_prefs")

object PreferenceKeys {
    val CATEGORIES = stringSetPreferencesKey("tx_selectedCategories")
    val REMINDER_ENABLED = booleanPreferencesKey("reminder_enabled")
    val REMINDER_HOUR = intPreferencesKey("reminder_hour")
    val REMINDER_MINUTE = intPreferencesKey("reminder_minute")
    val DARK_MODE = booleanPreferencesKey("dark_mode")
    val ONBOARDING_DONE = booleanPreferencesKey("onboarding_done")
}
