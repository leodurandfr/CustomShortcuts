// StorageManager.swift
import Foundation


@MainActor
final class StorageManager {
    static let shared = StorageManager()
    private init() {}

    private let userDefaults = UserDefaults.standard
    private let applicationsKey = "savedApplications"

    func saveApplications(_ applications: [CustomApplication]) {
        if let encoded = try? JSONEncoder().encode(applications) {
            userDefaults.set(encoded, forKey: applicationsKey)
        }
    }

    func loadApplications() -> [CustomApplication] {
        guard let data = userDefaults.data(forKey: applicationsKey),
              let applications = try? JSONDecoder().decode([CustomApplication].self, from: data) else {
            return []
        }
        return applications
    }
}
