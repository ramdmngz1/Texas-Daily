package com.refuge.texasdaily.viewmodel

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.refuge.texasdaily.billing.BillingManager
import com.refuge.texasdaily.data.FactRepository
import com.refuge.texasdaily.data.TexasFact
import com.refuge.texasdaily.notifications.DailyReminderWorker
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "texas_daily_prefs")

private val KEY_CATEGORIES = stringSetPreferencesKey("tx_selectedCategories")
private val KEY_REMINDER_ENABLED = booleanPreferencesKey("reminder_enabled")
private val KEY_REMINDER_HOUR = intPreferencesKey("reminder_hour")
private val KEY_REMINDER_MINUTE = intPreferencesKey("reminder_minute")
private val KEY_DARK_MODE = booleanPreferencesKey("dark_mode")

class TexasViewModel(
    private val context: Context,
    val billingManager: BillingManager
) : ViewModel() {

    private val repository = FactRepository(context)

    private val _currentFact = MutableStateFlow<TexasFact?>(null)
    val currentFact: StateFlow<TexasFact?> = _currentFact

    private val _selectedCategories = MutableStateFlow<Set<String>>(emptySet())
    val selectedCategories: StateFlow<Set<String>> = _selectedCategories

    private val _allCategories = MutableStateFlow<List<String>>(emptyList())
    val allCategories: StateFlow<List<String>> = _allCategories

    private val _reminderEnabled = MutableStateFlow(false)
    val reminderEnabled: StateFlow<Boolean> = _reminderEnabled

    private val _reminderHour = MutableStateFlow(9)
    val reminderHour: StateFlow<Int> = _reminderHour

    private val _reminderMinute = MutableStateFlow(0)
    val reminderMinute: StateFlow<Int> = _reminderMinute

    private val _isDarkMode = MutableStateFlow(false)
    val isDarkMode: StateFlow<Boolean> = _isDarkMode

    init {
        _allCategories.value = repository.getCategories()
        viewModelScope.launch {
            val prefs = context.dataStore.data.first()
            _selectedCategories.value = prefs[KEY_CATEGORIES] ?: emptySet()
            _reminderEnabled.value = prefs[KEY_REMINDER_ENABLED] ?: false
            _reminderHour.value = prefs[KEY_REMINDER_HOUR] ?: 9
            _reminderMinute.value = prefs[KEY_REMINDER_MINUTE] ?: 0
            _isDarkMode.value = prefs[KEY_DARK_MODE] ?: false
            loadNewFact()
        }
    }

    fun loadNewFact() {
        _currentFact.value = repository.randomFact(_selectedCategories.value)
    }

    fun toggleCategory(category: String) {
        val updated = _selectedCategories.value.toMutableSet()
        if (category in updated) updated.remove(category) else updated.add(category)
        _selectedCategories.value = updated
        viewModelScope.launch {
            context.dataStore.edit { it[KEY_CATEGORIES] = updated }
        }
    }

    fun clearCategoryFilter() {
        _selectedCategories.value = emptySet()
        viewModelScope.launch {
            context.dataStore.edit { it[KEY_CATEGORIES] = emptySet() }
        }
    }

    fun setDarkMode(enabled: Boolean) {
        _isDarkMode.value = enabled
        viewModelScope.launch {
            context.dataStore.edit { it[KEY_DARK_MODE] = enabled }
        }
    }

    fun saveReminder(enabled: Boolean, hour: Int, minute: Int) {
        _reminderEnabled.value = enabled
        _reminderHour.value = hour
        _reminderMinute.value = minute
        viewModelScope.launch {
            context.dataStore.edit {
                it[KEY_REMINDER_ENABLED] = enabled
                it[KEY_REMINDER_HOUR] = hour
                it[KEY_REMINDER_MINUTE] = minute
            }
        }
        if (enabled) {
            DailyReminderWorker.schedule(context, hour, minute)
        } else {
            DailyReminderWorker.cancel(context)
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            val billing = BillingManager(context)
            @Suppress("UNCHECKED_CAST")
            return TexasViewModel(context.applicationContext, billing) as T
        }
    }
}
