package com.refuge.texasdaily.viewmodel

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.refuge.texasdaily.billing.BillingManager
import com.refuge.texasdaily.data.FactRepository
import com.refuge.texasdaily.data.PreferenceKeys
import com.refuge.texasdaily.data.TexasFact
import com.refuge.texasdaily.data.dataStore
import com.refuge.texasdaily.notifications.DailyReminderWorker
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class TexasViewModel(
    private val context: Context,
    val billingManager: BillingManager
) : ViewModel() {

    private val repository = FactRepository.getInstance(context)

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

    private val _onboardingDone = MutableStateFlow(false)
    val onboardingDone: StateFlow<Boolean> = _onboardingDone

    init {
        _allCategories.value = repository.getCategories()
        loadNewFact()
        viewModelScope.launch {
            val prefs = context.dataStore.data.first()
            _selectedCategories.value = prefs[PreferenceKeys.CATEGORIES] ?: emptySet()
            _reminderEnabled.value = prefs[PreferenceKeys.REMINDER_ENABLED] ?: false
            _reminderHour.value = prefs[PreferenceKeys.REMINDER_HOUR] ?: 9
            _reminderMinute.value = prefs[PreferenceKeys.REMINDER_MINUTE] ?: 0
            _isDarkMode.value = prefs[PreferenceKeys.DARK_MODE] ?: false
            _onboardingDone.value = prefs[PreferenceKeys.ONBOARDING_DONE] ?: false
            if (_selectedCategories.value.isNotEmpty()) {
                loadNewFact()
            }
        }
    }

    fun loadNewFact() {
        val currentId = _currentFact.value?.id
        val categories = _selectedCategories.value

        var next: TexasFact? = null
        if (categories.isNotEmpty()) {
            next = repository.randomFact(categories, excludingId = currentId)
        }
        if (next == null) {
            next = repository.randomFact(emptySet(), excludingId = currentId)
        }
        _currentFact.value = next
    }

    fun toggleCategory(category: String) {
        val updated = _selectedCategories.value.toMutableSet()
        if (category in updated) updated.remove(category) else updated.add(category)
        _selectedCategories.value = updated
        viewModelScope.launch {
            context.dataStore.edit { it[PreferenceKeys.CATEGORIES] = updated }
        }
        loadNewFact()
    }

    fun clearCategoryFilter() {
        _selectedCategories.value = emptySet()
        viewModelScope.launch {
            context.dataStore.edit { it[PreferenceKeys.CATEGORIES] = emptySet() }
        }
        loadNewFact()
    }

    fun completeOnboarding() {
        _onboardingDone.value = true
        viewModelScope.launch {
            context.dataStore.edit { it[PreferenceKeys.ONBOARDING_DONE] = true }
        }
    }

    fun setDarkMode(enabled: Boolean) {
        _isDarkMode.value = enabled
        viewModelScope.launch {
            context.dataStore.edit { it[PreferenceKeys.DARK_MODE] = enabled }
        }
    }

    fun saveReminder(enabled: Boolean, hour: Int, minute: Int) {
        _reminderEnabled.value = enabled
        _reminderHour.value = hour
        _reminderMinute.value = minute
        viewModelScope.launch {
            context.dataStore.edit {
                it[PreferenceKeys.REMINDER_ENABLED] = enabled
                it[PreferenceKeys.REMINDER_HOUR] = hour
                it[PreferenceKeys.REMINDER_MINUTE] = minute
            }
        }
        if (enabled) {
            DailyReminderWorker.schedule(context, hour, minute)
        } else {
            DailyReminderWorker.cancel(context)
        }
    }

    override fun onCleared() {
        super.onCleared()
        billingManager.endConnection()
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            val billing = BillingManager(context)
            @Suppress("UNCHECKED_CAST")
            return TexasViewModel(context.applicationContext, billing) as T
        }
    }
}
