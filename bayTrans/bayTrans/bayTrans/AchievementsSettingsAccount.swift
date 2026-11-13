import SwiftUI

struct AchievementsView: View {
    @ObservedObject var achievements: AchievementController

    var body: some View {
        FormShell(title: "Achievements", subtitle: "Unlock goals by using BayTrans features.") {
            ForEach(achievements.achievements) { achievement in
                HStack(spacing: 12) {
                    Image(systemName: achievement.isUnlocked ? "trophy.fill" : "lock.fill")
                        .foregroundStyle(achievement.isUnlocked ? BayTransColors.accent : BayTransColors.secondaryText)
                        .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(achievement.title)
                            .font(.scaled(.headline))
                        Text(achievement.description)
                            .font(.scaled(.subheadline))
                            .foregroundStyle(BayTransColors.secondaryText)
                    }
                    Spacer()
                }
                .padding(12)
                .background(BayTransColors.field)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .navigationTitle("Achievements")
    }
}

struct SettingsView: View {
    @ObservedObject var achievements: AchievementController
    @AppStorage("baytrans.fontScale") private var fontScale = 1.0
    @AppStorage("baytrans.theme") private var theme = BayTransTheme.system.rawValue
    @AppStorage("baytrans.tts") private var textToSpeech = true
    @AppStorage("baytrans.sfx") private var soundEffects = true
    @AppStorage("baytrans.haptics") private var haptics = true

    var body: some View {
        FormShell(title: "Settings", subtitle: "Adjust readability, theme, speech, and feedback preferences.") {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Theme", selection: $theme) {
                    ForEach(BayTransTheme.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading) {
                    Text("Font Size")
                    Slider(value: $fontScale, in: 0.85...1.35, step: 0.05)
                }
                Toggle("Enable Text to Speech", isOn: $textToSpeech)
                Toggle("Sound Effects", isOn: $soundEffects)
                Toggle("Haptic Feedback", isOn: $haptics)
                Toggle("Offline Mode Reminder", isOn: .constant(true))
                    .disabled(true)
                Text("All core learning, translation, quiz, typing, and writing data is available locally. Optional account sync can be added later without blocking offline use.")
                    .font(.scaled(.subheadline))
                    .foregroundStyle(BayTransColors.secondaryText)
            }
            .onChange(of: fontScale) { _, _ in achievements.unlock("settings") }
            .onChange(of: theme) { _, _ in achievements.unlock("settings") }
            .onChange(of: textToSpeech) { _, _ in achievements.unlock("settings") }
        }
        .navigationTitle("Settings")
    }
}

struct AccountView: View {
    @State private var isRegistered = false
    @State private var name = ""
    @State private var email = ""

    var body: some View {
        FormShell(title: "Optional Account", subtitle: "A local mock sign-in for future sync of statistics, achievements, and saved work.") {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Name", text: $name)
                    .textFieldStyle(BayTextFieldStyle())
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(BayTextFieldStyle())
                Button(isRegistered ? "Signed In" : "Register / Sign In") { isRegistered = true }
                    .buttonStyle(WideButtonStyle())
                if isRegistered {
                    Label("Local profile active. Cloud sync is intentionally optional.", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Account")
    }
}
