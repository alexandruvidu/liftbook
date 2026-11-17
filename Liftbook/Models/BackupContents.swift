import Foundation

extension DataExport {
    struct ProgressPhotoRecord: Codable, Equatable {
        var id: UUID
        var date: Date
        var fileName: String
    }

    /// The settings a backup carries. `nil` means the setting was never
    /// changed, so the app's default applies. When the last backup ran isn't
    /// included: that belongs to the phone, not the data.
    struct SettingsRecord: Codable, Equatable {
        var weightUnit: String?
        var weeklyGoal: Int?
        var restSeconds: Int?
        var restSound: Bool?
        var keepScreenOn: Bool?
        var automaticBackup: Bool?

        init(weightUnit: String? = nil, weeklyGoal: Int? = nil, restSeconds: Int? = nil,
             restSound: Bool? = nil, keepScreenOn: Bool? = nil, automaticBackup: Bool? = nil) {
            self.weightUnit = weightUnit
            self.weeklyGoal = weeklyGoal
            self.restSeconds = restSeconds
            self.restSound = restSound
            self.keepScreenOn = keepScreenOn
            self.automaticBackup = automaticBackup
        }

        init(defaults: UserDefaults) {
            weightUnit = defaults.object(forKey: WeightUnit.storageKey) as? String
            weeklyGoal = defaults.object(forKey: WeeklyGoal.storageKey) as? Int
            restSeconds = defaults.object(forKey: RestTimer.defaultSecondsKey) as? Int
            restSound = defaults.object(forKey: RestTimer.soundKey) as? Bool
            keepScreenOn = defaults.object(forKey: RestTimer.keepScreenOnKey) as? Bool
            automaticBackup = defaults.object(forKey: AutoBackup.enabledKey) as? Bool
        }

        /// Sets every setting to the backup's value; ones it never changed go
        /// back to the default.
        func apply(to defaults: UserDefaults) {
            func set(_ value: Any?, _ key: String) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
            set(weightUnit, WeightUnit.storageKey)
            set(weeklyGoal, WeeklyGoal.storageKey)
            set(restSeconds, RestTimer.defaultSecondsKey)
            set(restSound, RestTimer.soundKey)
            set(keepScreenOn, RestTimer.keepScreenOnKey)
            set(automaticBackup, AutoBackup.enabledKey)
        }
    }
}
