import Foundation

@MainActor
final class TexasAppViewModel: ObservableObject {

    // MARK: - Published state

    @Published var todayFact: TexasFact? = nil
    @Published var selectedCategories: Set<String> = []
    @Published var notificationTime: Date
    @Published var adsSDKReady: Bool = false
    @Published var onboardingDone: Bool = false

    let availableCategories: [String]

    private var notificationDebounceTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        self.availableCategories = Array(Set(FactStore.shared.facts.map { $0.category })).sorted()

        if let arr = UserDefaults.standard.array(forKey: PreferenceKeys.selectedCategories) as? [String] {
            let validCategories = Set(self.availableCategories)
            self.selectedCategories = Set(arr).intersection(validCategories)
        } else {
            self.selectedCategories = []
        }

        let hour: Int
        let minute: Int
        if UserDefaults.standard.object(forKey: PreferenceKeys.reminderHour) != nil {
            hour = UserDefaults.standard.integer(forKey: PreferenceKeys.reminderHour)
            minute = UserDefaults.standard.integer(forKey: PreferenceKeys.reminderMinute)
        } else {
            hour = 9
            minute = 0
        }
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        self.notificationTime = Calendar.current.date(from: comps) ?? Date()

        self.onboardingDone = UserDefaults.standard.bool(forKey: PreferenceKeys.onboardingDone)

        refreshTodayFact()
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        onboardingDone = true
        UserDefaults.standard.set(true, forKey: PreferenceKeys.onboardingDone)
    }

    // MARK: - Facts

    func refreshTodayFact() {
        let currentID = todayFact?.id

        var next: TexasFact?
        if !selectedCategories.isEmpty {
            next = FactStore.shared.randomFact(from: selectedCategories, excluding: currentID)
        }
        if next == nil {
            next = FactStore.shared.randomFact(excluding: currentID)
        }

        todayFact = next
    }

    // MARK: - Category Selection

    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        saveSelectedCategories()
        refreshTodayFact()
    }

    func clearCategories() {
        selectedCategories = []
        saveSelectedCategories()
        refreshTodayFact()
    }

    private func saveSelectedCategories() {
        UserDefaults.standard.set(Array(selectedCategories), forKey: PreferenceKeys.selectedCategories)
    }

    // MARK: - Notifications

    func saveNotificationTime() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        UserDefaults.standard.set(comps.hour ?? 9, forKey: PreferenceKeys.reminderHour)
        UserDefaults.standard.set(comps.minute ?? 0, forKey: PreferenceKeys.reminderMinute)

        let enabled = UserDefaults.standard.object(forKey: PreferenceKeys.dailyReminderEnabled) as? Bool ?? false
        guard enabled else { return }

        notificationDebounceTask?.cancel()
        notificationDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            await scheduleDailyReminderIfEnabled()
        }
    }

    func setDailyReminderEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: PreferenceKeys.dailyReminderEnabled)
        if enabled {
            saveNotificationTime()
        } else {
            Task { await scheduleDailyReminderIfEnabled() }
        }
    }

    func scheduleDailyReminderIfEnabled() async {
        let enabled = UserDefaults.standard.object(forKey: PreferenceKeys.dailyReminderEnabled) as? Bool ?? false
        let center = NotificationManager.shared

        if !enabled {
            center.cancelDailyFactNotification()
            return
        }

        let comps = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        await center.scheduleDailyFactNotification(at: comps)
    }
}
