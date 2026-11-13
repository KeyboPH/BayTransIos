import SwiftUI
import Foundation
import Combine

final class AchievementController: ObservableObject {
    @Published var achievements: [Achievement] = []
    private let storageKey = "baytrans.achievements"

    init() {
        load()
    }

    func unlock(_ id: String) {
        guard let index = achievements.firstIndex(where: { $0.id == id }), achievements[index].isUnlocked == false else { return }
        achievements[index].isUnlocked = true
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey), let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        } else {
            achievements = [
                Achievement(id: "first_translate", title: "First Conversion", description: "Use the translator for the first time.", isUnlocked: false),
                Achievement(id: "perfect_quiz", title: "Perfect Reader", description: "Finish a quiz with a perfect score.", isUnlocked: false),
                Achievement(id: "quick_quiz", title: "Fast Recall", description: "Complete a quiz in under one minute.", isUnlocked: false),
                Achievement(id: "typing_90", title: "Steady Hands", description: "Finish a typing test with at least 90% accuracy.", isUnlocked: false),
                Achievement(id: "writer", title: "Baybayin Writer", description: "Save your first writing activity.", isUnlocked: false),
                Achievement(id: "collector", title: "Portfolio Keeper", description: "Save at least three writing activities.", isUnlocked: false),
                Achievement(id: "learner", title: "Script Scholar", description: "Open the learning section.", isUnlocked: false),
                Achievement(id: "settings", title: "Personalized", description: "Adjust an app setting.", isUnlocked: false)
            ]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

final class WritingStore: ObservableObject {
    @Published var entries: [WritingEntry] = []
    private let storageKey = "baytrans.writing.entries"

    init() {
        load()
    }

    func saveEntry(_ entry: WritingEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }

    func deleteEntry(_ entry: WritingEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey), let decoded = try? JSONDecoder().decode([WritingEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
