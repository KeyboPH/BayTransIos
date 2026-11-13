import SwiftUI

struct HomeView: View {
    @AppStorage("baytrans.fontScale") private var fontScale = 1.0
    @AppStorage("baytrans.theme") private var themeRaw = BayTransTheme.system.rawValue
    @AppStorage("baytrans.tts") private var textToSpeech = true
    @StateObject private var achievements = AchievementController()
    @StateObject private var writingStore = WritingStore()
    @StateObject private var speech = SpeechController()

    private var theme: BayTransTheme { BayTransTheme(rawValue: themeRaw) ?? .system }
    private var dynamicTypeSize: DynamicTypeSize {
        switch fontScale {
        case ..<0.95: return .small
        case 0.95..<1.1: return .medium
        case 1.1..<1.25: return .large
        default: return .xLarge
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                        HomeTile(title: "Translate", subtitle: "Real-time utility", icon: "character.book.closed", destination: AnyView(TranslatorView(achievements: achievements, speech: speech, textToSpeech: textToSpeech)))
                        HomeTile(title: "Quiz", subtitle: "Adjustable drills", icon: "checklist.checked", destination: AnyView(QuizView(achievements: achievements)))
                        HomeTile(title: "Typing", subtitle: "Speed practice", icon: "keyboard", destination: AnyView(TypingPracticeView(achievements: achievements)))
                        HomeTile(title: "Learn", subtitle: "Modules and cards", icon: "book.pages", destination: AnyView(LearningView(achievements: achievements, speech: speech, textToSpeech: textToSpeech)))
                        HomeTile(title: "Activities", subtitle: "Write and save", icon: "square.and.pencil", destination: AnyView(WritingActivityView(store: writingStore, achievements: achievements)))
                        HomeTile(title: "Saved Work", subtitle: "CRUD library", icon: "tray.full", destination: AnyView(SavedWorkView(store: writingStore)))
                        HomeTile(title: "Achievements", subtitle: "Progress goals", icon: "trophy", destination: AnyView(AchievementsView(achievements: achievements)))
                        HomeTile(title: "Settings", subtitle: "Personalize", icon: "gearshape", destination: AnyView(SettingsView(achievements: achievements)))
                        HomeTile(title: "Account", subtitle: "Optional profile", icon: "person.crop.circle", destination: AnyView(AccountView()))
                    }
                }
                .padding(20)
            }
            .background(BayTransColors.background.ignoresSafeArea())
            .navigationTitle("BayTrans")
        }
        .preferredColorScheme(theme.colorScheme)
        .dynamicTypeSize(dynamicTypeSize)
        .environment(\.fontScale, fontScale)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BayTrans")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(BayTransColors.ink)
            Text("A web and mobile educational application for Baybayin using hands-on learning with utility features.")
                .font(.scaled(.headline))
                .foregroundStyle(BayTransColors.secondaryText)
            Text(BaybayinTranslator.shared.translateLatinToBaybayin("baytrans"))
                .font(.system(size: 48, weight: .semibold, design: .serif))
                .foregroundStyle(BayTransColors.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
        .padding(20)
        .background(BayTransColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct HomeTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(BayTransColors.accent)
                    .frame(width: 38, height: 38)
                    .background(BayTransColors.accent.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.scaled(.headline))
                        .foregroundStyle(BayTransColors.ink)
                    Text(subtitle)
                        .font(.scaled(.subheadline))
                        .foregroundStyle(BayTransColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
            .padding(14)
            .background(BayTransColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
