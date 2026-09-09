import SwiftUI
import Foundation
import AVFoundation
import Combine
import UniformTypeIdentifiers
import UIKit

// MARK: - Models

enum BayTransTheme: String, CaseIterable, Identifiable {
    case system = "Default"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum TranslationDirection: String, CaseIterable, Identifiable {
    case latinToBaybayin = "Latin to Baybayin"
    case baybayinToLatin = "Baybayin to Latin"

    var id: String { rawValue }
    var sourceLabel: String { self == .latinToBaybayin ? "Latin" : "Baybayin" }
    var outputLabel: String { self == .latinToBaybayin ? "Baybayin" : "Latin" }
}

enum QuizItemMode: String, CaseIterable, Identifiable {
    case characters = "Characters"
    case words = "Words"

    var id: String { rawValue }
}

enum TypingMode: String, CaseIterable, Identifiable {
    case directBaybayin = "Type Baybayin"
    case latinPromptToBaybayin = "Latin prompt -> Baybayin"
    case baybayinPromptToLatin = "Baybayin prompt -> Latin"

    var id: String { rawValue }
}

enum TypingSource: String, CaseIterable, Identifiable {
    case syllables = "Syllables"
    case words = "Words"
    case article = "Article"

    var id: String { rawValue }
}

enum WritingMode: String, CaseIterable, Identifiable, Codable {
    case creative = "Creative"
    case letter = "Letter"

    var id: String { rawValue }
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let answer: String
    let choices: [String]
}

struct QuizSummary {
    let correct: Int
    let total: Int
    let elapsed: TimeInterval

    var percentage: Int { total == 0 ? 0 : Int((Double(correct) / Double(total)) * 100) }
}

struct TypingSample: Identifiable {
    let id = UUID()
    let second: Int
    let wpm: Int
    let mistakes: Int
}

struct TypingSummary {
    let typedCharacters: Int
    let correctCharacters: Int
    let mistakes: Int
    let elapsed: TimeInterval
    let samples: [TypingSample]

    var accuracy: Int {
        guard typedCharacters > 0 else { return 0 }
        return Int((Double(correctCharacters) / Double(typedCharacters)) * 100)
    }

    var wpm: Int {
        guard elapsed > 0 else { return 0 }
        return Int((Double(correctCharacters) / 5.0) / (elapsed / 60.0))
    }
}

struct WritingEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var prompt: String
    var mode: WritingMode
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, body: String, prompt: String, mode: WritingMode, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.body = body
        self.prompt = prompt
        self.mode = mode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    var isUnlocked: Bool
}

struct LearningModule: Identifiable {
    let id = UUID()
    let title: String
    let sections: [LearningSection]
}

struct LearningSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct BaybayinCharacter: Identifiable {
    let id = UUID()
    let baybayin: String
    let latin: String
    let pronunciation: String
    let note: String
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .pdf, .html] }
    static var writableContentTypes: [UTType] { [.plainText, .pdf, .html] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Controllers

final class BaybayinTranslator {
    static let shared = BaybayinTranslator()

    private let latinToBaybayin: [String: String] = [
        "a": "ᜀ", "e": "ᜁ", "i": "ᜁ", "o": "ᜂ", "u": "ᜂ",
        "ba": "ᜊ", "be": "ᜊᜒ", "bi": "ᜊᜒ", "bo": "ᜊᜓ", "bu": "ᜊᜓ", "b": "ᜊ᜔",
        "ka": "ᜃ", "ke": "ᜃᜒ", "ki": "ᜃᜒ", "ko": "ᜃᜓ", "ku": "ᜃᜓ", "k": "ᜃ᜔",
        "da": "ᜇ", "de": "ᜇᜒ", "di": "ᜇᜒ", "do": "ᜇᜓ", "du": "ᜇᜓ", "d": "ᜇ᜔",
        "ga": "ᜄ", "ge": "ᜄᜒ", "gi": "ᜄᜒ", "go": "ᜄᜓ", "gu": "ᜄᜓ", "g": "ᜄ᜔",
        "ha": "ᜑ", "he": "ᜑᜒ", "hi": "ᜑᜒ", "ho": "ᜑᜓ", "hu": "ᜑᜓ", "h": "ᜑ᜔",
        "la": "ᜎ", "le": "ᜎᜒ", "li": "ᜎᜒ", "lo": "ᜎᜓ", "lu": "ᜎᜓ", "l": "ᜎ᜔",
        "ma": "ᜋ", "me": "ᜋᜒ", "mi": "ᜋᜒ", "mo": "ᜋᜓ", "mu": "ᜋᜓ", "m": "ᜋ᜔",
        "na": "ᜈ", "ne": "ᜈᜒ", "ni": "ᜈᜒ", "no": "ᜈᜓ", "nu": "ᜈᜓ", "n": "ᜈ᜔",
        "pa": "ᜉ", "pe": "ᜉᜒ", "pi": "ᜉᜒ", "po": "ᜉᜓ", "pu": "ᜉᜓ", "p": "ᜉ᜔",
        "ra": "ᜇ", "re": "ᜇᜒ", "ri": "ᜇᜒ", "ro": "ᜇᜓ", "ru": "ᜇᜓ", "r": "ᜇ᜔",
        "sa": "ᜐ", "se": "ᜐᜒ", "si": "ᜐᜒ", "so": "ᜐᜓ", "su": "ᜐᜓ", "s": "ᜐ᜔",
        "ta": "ᜆ", "te": "ᜆᜒ", "ti": "ᜆᜒ", "to": "ᜆᜓ", "tu": "ᜆᜓ", "t": "ᜆ᜔",
        "wa": "ᜏ", "we": "ᜏᜒ", "wi": "ᜏᜒ", "wo": "ᜏᜓ", "wu": "ᜏᜓ", "w": "ᜏ᜔",
        "ya": "ᜌ", "ye": "ᜌᜒ", "yi": "ᜌᜒ", "yo": "ᜌᜓ", "yu": "ᜌᜓ", "y": "ᜌ᜔",
        "nga": "ᜅ", "nge": "ᜅᜒ", "ngi": "ᜅᜒ", "ngo": "ᜅᜓ", "ngu": "ᜅᜓ", "ng": "ᜅ᜔"
    ]

    private let baybayinToLatin: [String: String] = [
        "ᜀ": "a", "ᜁ": "i", "ᜂ": "u", "᜶": ".", "᜵": ",",
        "ᜊ": "ba", "ᜊᜒ": "bi", "ᜊᜓ": "bu", "ᜊ᜔": "b",
        "ᜃ": "ka", "ᜃᜒ": "ki", "ᜃᜓ": "ku", "ᜃ᜔": "k",
        "ᜇ": "da/ra", "ᜇᜒ": "di/ri", "ᜇᜓ": "du/ru", "ᜇ᜔": "d/r",
        "ᜄ": "ga", "ᜄᜒ": "gi", "ᜄᜓ": "gu", "ᜄ᜔": "g",
        "ᜑ": "ha", "ᜑᜒ": "hi", "ᜑᜓ": "hu", "ᜑ᜔": "h",
        "ᜎ": "la", "ᜎᜒ": "li", "ᜎᜓ": "lu", "ᜎ᜔": "l",
        "ᜋ": "ma", "ᜋᜒ": "mi", "ᜋᜓ": "mu", "ᜋ᜔": "m",
        "ᜈ": "na", "ᜈᜒ": "ni", "ᜈᜓ": "nu", "ᜈ᜔": "n",
        "ᜉ": "pa", "ᜉᜒ": "pi", "ᜉᜓ": "pu", "ᜉ᜔": "p",
        "ᜐ": "sa", "ᜐᜒ": "si", "ᜐᜓ": "su", "ᜐ᜔": "s",
        "ᜆ": "ta", "ᜆᜒ": "ti", "ᜆᜓ": "tu", "ᜆ᜔": "t",
        "ᜏ": "wa", "ᜏᜒ": "wi", "ᜏᜓ": "wu", "ᜏ᜔": "w",
        "ᜌ": "ya", "ᜌᜒ": "yi", "ᜌᜓ": "yu", "ᜌ᜔": "y",
        "ᜅ": "nga", "ᜅᜒ": "ngi", "ᜅᜓ": "ngu", "ᜅ᜔": "ng"
    ]

    private let vowels = Set("aeiou")
    private let consonants = Set("bdghklmnprstwy")

    func translate(_ text: String, direction: TranslationDirection) -> String {
        switch direction {
        case .latinToBaybayin:
            return translateLatinToBaybayin(text)
        case .baybayinToLatin:
            return translateBaybayinToLatin(text)
        }
    }

    func translateLatinToBaybayin(_ text: String) -> String {
        let lowercased = text.lowercased()
        var output = ""
        var index = lowercased.startIndex

        while index < lowercased.endIndex {
            let remaining = lowercased[index...]
            if remaining.hasPrefix("nga") || remaining.hasPrefix("nge") || remaining.hasPrefix("ngi") || remaining.hasPrefix("ngo") || remaining.hasPrefix("ngu") {
                let key = String(remaining.prefix(3))
                output += latinToBaybayin[key] ?? key
                index = lowercased.index(index, offsetBy: 3)
                continue
            }

            if remaining.hasPrefix("ng") {
                output += latinToBaybayin["ng"] ?? "ng"
                index = lowercased.index(index, offsetBy: 2)
                continue
            }

            let current = lowercased[index]
            if current == "," {
                output += "᜵"
                index = lowercased.index(after: index)
                continue
            }
            if current == "." {
                output += "᜶"
                index = lowercased.index(after: index)
                continue
            }

            if vowels.contains(current) {
                output += latinToBaybayin[String(current)] ?? String(current)
                index = lowercased.index(after: index)
                continue
            }

            if consonants.contains(current) {
                let nextIndex = lowercased.index(after: index)
                if nextIndex < lowercased.endIndex, vowels.contains(lowercased[nextIndex]) {
                    let syllable = String(current) + String(lowercased[nextIndex])
                    output += latinToBaybayin[syllable] ?? syllable
                    index = lowercased.index(after: nextIndex)
                } else {
                    output += latinToBaybayin[String(current)] ?? String(current)
                    index = nextIndex
                }
                continue
            }

            output += String(current)
            index = lowercased.index(after: index)
        }

        return output
    }

    func translateBaybayinToLatin(_ text: String) -> String {
        var output = ""
        var index = text.startIndex

        while index < text.endIndex {
            let current = String(text[index])
            let nextIndex = text.index(after: index)

            if nextIndex < text.endIndex {
                let pair = current + String(text[nextIndex])
                if let translated = baybayinToLatin[pair] {
                    output += translated
                    index = text.index(after: nextIndex)
                    continue
                }
            }

            output += baybayinToLatin[current] ?? current
            index = nextIndex
        }

        return output
    }
}

final class SpeechController: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, enabled: Bool) {
        guard enabled, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fil-PH") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.42
        synthesizer.speak(utterance)
    }
}

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

// MARK: - Data

enum BayTransData {
    static let characters: [BaybayinCharacter] = [
        BaybayinCharacter(baybayin: "ᜀ", latin: "a", pronunciation: "a", note: "Independent vowel."),
        BaybayinCharacter(baybayin: "ᜁ", latin: "i/e", pronunciation: "i or e", note: "Independent vowel for i and e sounds."),
        BaybayinCharacter(baybayin: "ᜂ", latin: "u/o", pronunciation: "u or o", note: "Independent vowel for u and o sounds."),
        BaybayinCharacter(baybayin: "ᜊ", latin: "ba", pronunciation: "ba", note: "Base consonant with inherent a."),
        BaybayinCharacter(baybayin: "ᜃ", latin: "ka", pronunciation: "ka", note: "Use kudlit for ki/ku."),
        BaybayinCharacter(baybayin: "ᜇ", latin: "da/ra", pronunciation: "da or ra", note: "Historically used for both d and r."),
        BaybayinCharacter(baybayin: "ᜄ", latin: "ga", pronunciation: "ga", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜑ", latin: "ha", pronunciation: "ha", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜎ", latin: "la", pronunciation: "la", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜋ", latin: "ma", pronunciation: "ma", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜈ", latin: "na", pronunciation: "na", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜅ", latin: "nga", pronunciation: "nga", note: "Distinct consonant for the ng sound."),
        BaybayinCharacter(baybayin: "ᜉ", latin: "pa", pronunciation: "pa", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜐ", latin: "sa", pronunciation: "sa", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜆ", latin: "ta", pronunciation: "ta", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜏ", latin: "wa", pronunciation: "wa", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜌ", latin: "ya", pronunciation: "ya", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜒ", latin: "kudlit i/e", pronunciation: "i or e mark", note: "Placed above a consonant."),
        BaybayinCharacter(baybayin: "ᜓ", latin: "kudlit u/o", pronunciation: "u or o mark", note: "Placed below a consonant."),
        BaybayinCharacter(baybayin: "᜔", latin: "virama", pronunciation: "vowel killer", note: "Modern mark used to cancel the inherent a."),
        BaybayinCharacter(baybayin: "᜵", latin: ",", pronunciation: "comma", note: "Baybayin punctuation."),
        BaybayinCharacter(baybayin: "᜶", latin: ".", pronunciation: "period", note: "Baybayin punctuation.")
    ]

    static let latinWords = ["araw", "bayan", "diwa", "gabi", "haligi", "kalayaan", "lahi", "mahal", "ngiti", "puso", "sulat", "tala", "wika", "yaman", "buhay", "dangal", "liwanag", "panahon"]

    static var baybayinWords: [String] {
        latinWords.map { BaybayinTranslator.shared.translateLatinToBaybayin($0) }
    }

    static let hardArticleLatin = "ang wikang filipino ay yaman ng bayan. sa bawat titik, buhay ang alaala ng ating lahi. mahalin natin ang sariling sulat at kultura."

    static var hardArticleBaybayin: String {
        BaybayinTranslator.shared.translateLatinToBaybayin(hardArticleLatin)
    }

    static let writingPrompts = [
        "Sumulat ng maikling kuwento tungkol sa isang batang unang natutong bumasa ng Baybayin.",
        "Gumawa ng tula tungkol sa araw, dagat, at alaala ng sariling bayan.",
        "Isulat ang isang pangako sa sarili gamit ang mga salitang nagpapakita ng dangal at pag-asa.",
        "Gumawa ng maikling sanaysay tungkol sa kahalagahan ng wika at kultura.",
        "Maglarawan ng isang sinaunang pamayanan at kung paano ginagamit ang sulat sa araw-araw."
    ]

    static let letterPrompts = [
        "Sumulat ng liham pasasalamat para sa iyong ina.",
        "Sumulat ng maikling mensahe para sa isang kaibigan na matagal mo nang hindi nakita.",
        "Sumulat ng liham pagmamahal para sa iyong kasintahan.",
        "Sumulat ng liham paumanhin para sa taong nasaktan mo.",
        "Sumulat ng liham para sa sarili mo sa hinaharap."
    ]

    static let modules: [LearningModule] = [
        LearningModule(title: "Foundations", sections: [
            LearningSection(title: "What Baybayin Is", body: "Baybayin is a precolonial Philippine writing system used for languages such as Tagalog. It is an abugida: each consonant character carries an inherent /a/ vowel unless a mark changes or removes that vowel."),
            LearningSection(title: "Why It Matters", body: "Learning Baybayin connects writing practice with cultural memory. Contemporary learners use it for education, art, signage, tattoos, digital posts, and cultural advocacy."),
            LearningSection(title: "Limits of Translation", body: "Baybayin is phonetic, not a direct letter-for-letter English cipher. Foreign sounds such as f, v, z, j, x, and q often need Filipino spelling adaptation before conversion.")
        ]),
        LearningModule(title: "Reading System", sections: [
            LearningSection(title: "Vowels", body: "The independent vowels are ᜀ for a, ᜁ for i/e, and ᜂ for u/o. Baybayin does not always distinguish e from i or o from u."),
            LearningSection(title: "Consonants", body: "A consonant character is normally read with an a sound: ᜊ is ba, ᜃ is ka, ᜋ is ma, and so on."),
            LearningSection(title: "Kudlit Marks", body: "The upper kudlit ᜒ changes the vowel to i/e, while the lower kudlit ᜓ changes it to u/o. Modern writing often uses ᜔ to remove the vowel for final consonants."),
            LearningSection(title: "Da and Ra", body: "The character ᜇ can represent both da and ra depending on context. This is one reason Baybayin-to-Latin conversion can be ambiguous.")
        ]),
        LearningModule(title: "Writing Practice", sections: [
            LearningSection(title: "Write by Syllable", body: "Break words into sounds first. The word mahal becomes ma-ha-l. With a final consonant mark it becomes ᜋᜑᜎ᜔."),
            LearningSection(title: "Ng Sound", body: "The ng sound has its own character: ᜅ. The syllable nga is ᜅ, while ng without a vowel can be written as ᜅ᜔."),
            LearningSection(title: "Punctuation", body: "Traditional punctuation includes ᜵ and ᜶. This app maps comma to ᜵ and period to ᜶.")
        ]),
        LearningModule(title: "Contemporary Use", sections: [
            LearningSection(title: "Modern Context", body: "Modern Baybayin appears in education, design, social media, local branding, and cultural events. Digital tools make practice easier while preserving offline access."),
            LearningSection(title: "Respectful Use", body: "Use Baybayin with attention to meaning. For names, brands, and public designs, verify spelling and pronunciation before publishing."),
            LearningSection(title: "Practical Workflow", body: "Draft the Filipino or phonetic text, convert it, review syllables, then practice reading it aloud. Repetition builds recognition faster than memorizing isolated charts.")
        ])
    ]
}

// MARK: - Views

struct ContentView: View {
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

struct TranslatorView: View {
    @ObservedObject var achievements: AchievementController
    @ObservedObject var speech: SpeechController
    let textToSpeech: Bool
    @State private var direction: TranslationDirection = .latinToBaybayin
    @State private var input = "mahal kita"

    private var output: String { BaybayinTranslator.shared.translate(input, direction: direction) }

    var body: some View {
        FormShell(title: "Translator", subtitle: "Real-time conversion based on the legacy BayTrans engine.") {
            VStack(spacing: 14) {
                HStack {
                    Text(direction.sourceLabel)
                        .font(.scaled(.headline))
                    Spacer()
                    Button {
                        input = output
                        direction = direction == .latinToBaybayin ? .baybayinToLatin : .latinToBaybayin
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .buttonStyle(BayButtonStyle())
                    Text(direction.outputLabel)
                        .font(.scaled(.headline))
                }

                TextEditor(text: $input)
                    .font(.scaled(.title3))
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onChange(of: input) { _, value in
                        if !value.isEmpty { achievements.unlock("first_translate") }
                    }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Result")
                            .font(.scaled(.headline))
                        Spacer()
                        Button { UIPasteboard.general.string = output } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(BayButtonStyle())
                        Button { speech.speak(output, enabled: textToSpeech) } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        .buttonStyle(BayButtonStyle())
                    }
                    Text(output.isEmpty ? "Your translation appears here." : output)
                        .font(.system(size: direction == .latinToBaybayin ? 34 : 22, weight: .regular, design: .serif))
                        .foregroundStyle(BayTransColors.ink)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .padding(12)
                        .background(BayTransColors.field)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .navigationTitle("Translate")
    }
}

struct QuizView: View {
    @ObservedObject var achievements: AchievementController
    @State private var questionCount = 10.0
    @State private var timed = false
    @State private var timerSeconds = 60.0
    @State private var mode: QuizItemMode = .characters
    @State private var direction: TranslationDirection = .latinToBaybayin
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selected = ""
    @State private var correct = 0
    @State private var startDate = Date()
    @State private var remaining = 60
    @State private var summary: QuizSummary?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        FormShell(title: "Quiz", subtitle: "Identify the correct translation for characters or words.") {
            if let summary {
                QuizSummaryView(summary: summary)
                Button("Start New Quiz") { startQuiz() }
                    .buttonStyle(WideButtonStyle())
            } else if questions.isEmpty {
                quizSettings
                Button("Start Quiz") { startQuiz() }
                    .buttonStyle(WideButtonStyle())
            } else {
                activeQuiz
            }
        }
        .navigationTitle("Quiz")
        .onReceive(timer) { _ in
            guard timed, !questions.isEmpty, summary == nil else { return }
            remaining -= 1
            if remaining <= 0 { finishQuiz() }
        }
    }

    private var quizSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Mode", selection: $mode) {
                ForEach(QuizItemMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Direction", selection: $direction) {
                ForEach(TranslationDirection.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            VStack(alignment: .leading) {
                Text("Questions: \(Int(questionCount))")
                Slider(value: $questionCount, in: 5...30, step: 1)
            }
            Toggle("Optional Timer", isOn: $timed)
            if timed {
                VStack(alignment: .leading) {
                    Text("Timer: \(Int(timerSeconds)) seconds")
                    Slider(value: $timerSeconds, in: 30...180, step: 15)
                }
            }
        }
    }

    private var activeQuiz: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Question \(currentIndex + 1) of \(questions.count)")
                Spacer()
                if timed { Text("\(remaining)s") }
            }
            .font(.scaled(.headline))

            let question = questions[currentIndex]
            Text(question.prompt)
                .font(.system(size: direction == .baybayinToLatin ? 42 : 30, weight: .semibold, design: .serif))
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(BayTransColors.field)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            ForEach(question.choices, id: \.self) { choice in
                Button {
                    selected = choice
                    if choice == question.answer { correct += 1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { advanceQuiz() }
                } label: {
                    HStack {
                        Text(choice)
                        Spacer()
                        if selected == choice { Image(systemName: choice == question.answer ? "checkmark.circle.fill" : "xmark.circle.fill") }
                    }
                }
                .buttonStyle(ChoiceButtonStyle(isSelected: selected == choice, isCorrect: choice == question.answer))
                .disabled(!selected.isEmpty)
            }
        }
    }

    private func startQuiz() {
        let count = Int(questionCount)
        currentIndex = 0
        selected = ""
        correct = 0
        summary = nil
        startDate = Date()
        remaining = Int(timerSeconds)
        questions = makeQuestions(count: count)
    }

    private func advanceQuiz() {
        selected = ""
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            finishQuiz()
        }
    }

    private func finishQuiz() {
        let result = QuizSummary(correct: correct, total: questions.count, elapsed: Date().timeIntervalSince(startDate))
        summary = result
        if result.correct == result.total { achievements.unlock("perfect_quiz") }
        if result.elapsed < 60 { achievements.unlock("quick_quiz") }
        questions = []
    }

    private func makeQuestions(count: Int) -> [QuizQuestion] {
        let source: [(String, String)]
        if mode == .characters {
            source = BayTransData.characters.filter { !$0.latin.contains("kudlit") }.map { ($0.latin, $0.baybayin) }
        } else {
            source = BayTransData.latinWords.map { ($0, BaybayinTranslator.shared.translateLatinToBaybayin($0)) }
        }

        return (0..<count).map { _ in
            let pair = source.randomElement() ?? ("mahal", "ᜋᜑᜎ᜔")
            let prompt = direction == .latinToBaybayin ? pair.0 : pair.1
            let answer = direction == .latinToBaybayin ? pair.1 : pair.0
            let pool = source.map { direction == .latinToBaybayin ? $0.1 : $0.0 }.filter { $0 != answer }.shuffled().prefix(3)
            return QuizQuestion(prompt: prompt, answer: answer, choices: ([answer] + pool).shuffled())
        }
    }
}

struct QuizSummaryView: View {
    let summary: QuizSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Round Complete")
                .font(.scaled(.title2).bold())
            StatGrid(items: [
                ("Score", "\(summary.correct)/\(summary.total)"),
                ("Accuracy", "\(summary.percentage)%"),
                ("Time", formatDuration(summary.elapsed)),
                ("Pace", String(format: "%.1fs/item", summary.elapsed / Double(max(summary.total, 1))))
            ])
        }
    }
}

struct TypingPracticeView: View {
    @ObservedObject var achievements: AchievementController
    @State private var mode: TypingMode = .directBaybayin
    @State private var source: TypingSource = .words
    @State private var timeLimit = 60.0
    @State private var target = ""
    @State private var typed = ""
    @State private var started = false
    @State private var startDate = Date()
    @State private var remaining = 60
    @State private var samples: [TypingSample] = []
    @State private var summary: TypingSummary?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var expected: String {
        switch mode {
        case .directBaybayin, .latinPromptToBaybayin:
            return targetContainsLatin ? BaybayinTranslator.shared.translateLatinToBaybayin(target) : target
        case .baybayinPromptToLatin:
            return BaybayinTranslator.shared.translateBaybayinToLatin(target)
        }
    }

    var targetContainsLatin: Bool { target.range(of: #"[a-zA-Z]"#, options: .regularExpression) != nil }

    var body: some View {
        FormShell(title: "Typing Practice", subtitle: "Practice Baybayin recognition and conversion with live accuracy colors.") {
            if let summary {
                TypingSummaryView(summary: summary)
                Button("New Typing Test") { reset() }
                    .buttonStyle(WideButtonStyle())
            } else {
                settings
                typingArea
            }
        }
        .navigationTitle("Typing")
        .onAppear { resetTarget() }
        .onReceive(timer) { _ in tick() }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Mode", selection: $mode) {
                ForEach(TypingMode.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Source", selection: $source) {
                ForEach(TypingSource.allCases) { Text($0.rawValue).tag($0) }
            }
            VStack(alignment: .leading) {
                Text("Time Limit: \(Int(timeLimit)) seconds")
                Slider(value: $timeLimit, in: 30...180, step: 15)
            }
            Button("Generate Prompt") { resetTarget() }
                .buttonStyle(WideButtonStyle())
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in resetTarget() }
        .onChange(of: source) { _, _ in resetTarget() }
    }

    private var typingArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(started ? "\(remaining)s remaining" : "Ready")
                    .font(.scaled(.headline))
                Spacer()
                Text("WPM \(currentWPM())")
                    .font(.scaled(.headline))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt")
                    .font(.scaled(.caption))
                    .foregroundStyle(BayTransColors.secondaryText)
                Text(target)
                    .font(.system(size: mode == .baybayinPromptToLatin || mode == .directBaybayin ? 30 : 22, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Expected")
                    .font(.scaled(.caption))
                    .foregroundStyle(BayTransColors.secondaryText)
                ColoredTargetText(expected: expected, typed: typed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            TextEditor(text: $typed)
                .font(.system(size: 24, design: .serif))
                .frame(minHeight: 110)
                .padding(8)
                .background(BayTransColors.field)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: typed) { _, _ in
                    if !started { start() }
                    if typed.count >= expected.count { finish() }
                }
        }
    }

    private func reset() {
        summary = nil
        resetTarget()
    }

    private func resetTarget() {
        typed = ""
        started = false
        remaining = Int(timeLimit)
        samples = []
        switch source {
        case .syllables:
            let syllables = BayTransData.characters.filter { !$0.latin.contains("kudlit") && !$0.latin.contains(",") && !$0.latin.contains(".") }.map { $0.baybayin }
            target = (0..<30).map { _ in syllables.randomElement() ?? "ᜀ" }.joined(separator: " ")
        case .words:
            let words = mode == .baybayinPromptToLatin || mode == .directBaybayin ? BayTransData.baybayinWords : BayTransData.latinWords
            target = (0..<18).map { _ in words.randomElement() ?? "ᜋᜑᜎ᜔" }.joined(separator: " ")
        case .article:
            target = mode == .latinPromptToBaybayin ? BayTransData.hardArticleLatin : BayTransData.hardArticleBaybayin
        }
    }

    private func start() {
        started = true
        startDate = Date()
        remaining = Int(timeLimit)
    }

    private func tick() {
        guard started, summary == nil else { return }
        remaining -= 1
        samples.append(TypingSample(second: Int(Date().timeIntervalSince(startDate)), wpm: currentWPM(), mistakes: mistakeCount()))
        if remaining <= 0 { finish() }
    }

    private func finish() {
        guard summary == nil else { return }
        let elapsed = max(Date().timeIntervalSince(startDate), 1)
        let correct = zip(Array(typed), Array(expected)).filter { $0 == $1 }.count
        let result = TypingSummary(typedCharacters: typed.count, correctCharacters: correct, mistakes: mistakeCount(), elapsed: elapsed, samples: samples)
        summary = result
        if result.accuracy >= 90 { achievements.unlock("typing_90") }
        started = false
    }

    private func mistakeCount() -> Int {
        let expectedChars = Array(expected)
        return Array(typed).enumerated().filter { index, char in index >= expectedChars.count || expectedChars[index] != char }.count
    }

    private func currentWPM() -> Int {
        guard started else { return 0 }
        let elapsed = max(Date().timeIntervalSince(startDate), 1)
        let correct = zip(Array(typed), Array(expected)).filter { $0 == $1 }.count
        return Int((Double(correct) / 5.0) / (elapsed / 60.0))
    }
}

struct ColoredTargetText: View {
    let expected: String
    let typed: String

    var body: some View {
        let expectedChars = Array(expected)
        let typedChars = Array(typed)
        Text(attributedText(expectedChars: expectedChars, typedChars: typedChars))
            .font(.system(size: 26, design: .serif))
    }

    private func attributedText(expectedChars: [Character], typedChars: [Character]) -> AttributedString {
        var result = AttributedString("")
        for index in expectedChars.indices {
            var char = AttributedString(String(expectedChars[index]))
            if index >= typedChars.count {
                char.foregroundColor = BayTransColors.secondaryText
            } else if typedChars[index] == expectedChars[index] {
                char.foregroundColor = .green
            } else {
                char.foregroundColor = .red
            }
            result += char
        }
        return result
    }
}

struct TypingSummaryView: View {
    let summary: TypingSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Typing Results")
                .font(.scaled(.title2).bold())
            StatGrid(items: [
                ("WPM", "\(summary.wpm)"),
                ("Accuracy", "\(summary.accuracy)%"),
                ("Typed", "\(summary.typedCharacters)"),
                ("Mistakes", "\(summary.mistakes)"),
                ("Time", formatDuration(summary.elapsed))
            ])
            WPMGraph(samples: summary.samples)
        }
    }
}

struct WPMGraph: View {
    let samples: [TypingSample]

    var body: some View {
        VStack(alignment: .leading) {
            Text("WPM and Mistakes Over Time")
                .font(.scaled(.headline))
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(samples.suffix(24)) { sample in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BayTransColors.accent)
                            .frame(height: CGFloat(max(sample.wpm, 2)) * 1.6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.red.opacity(0.75))
                            .frame(height: CGFloat(min(sample.mistakes, 20)) * 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            .padding(8)
            .background(BayTransColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct LearningView: View {
    @ObservedObject var achievements: AchievementController
    @ObservedObject var speech: SpeechController
    let textToSpeech: Bool
    @State private var selectedCharacter: BaybayinCharacter?

    var body: some View {
        FormShell(title: "Learning", subtitle: "Comprehensive Baybayin modules, audio pronunciation, and flashcards.") {
            VStack(alignment: .leading, spacing: 20) {
                characterGrid
                flashcards
                ForEach(BayTransData.modules) { module in
                    DisclosureGroup(module.title) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(module.sections) { section in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(section.title)
                                        .font(.scaled(.headline))
                                    Text(section.body)
                                        .font(.scaled(.body))
                                        .foregroundStyle(BayTransColors.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(BayTransColors.field)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.scaled(.title3).bold())
                }
            }
        }
        .navigationTitle("Learn")
        .onAppear { achievements.unlock("learner") }
    }

    private var characterGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Character Chart")
                .font(.scaled(.title2).bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 10)], spacing: 10) {
                ForEach(BayTransData.characters) { item in
                    Button {
                        speech.speak(item.pronunciation, enabled: textToSpeech)
                    } label: {
                        VStack(spacing: 5) {
                            Text(item.baybayin)
                                .font(.system(size: 32, design: .serif))
                            Text(item.latin)
                                .font(.scaled(.caption))
                        }
                        .frame(maxWidth: .infinity, minHeight: 74)
                    }
                    .buttonStyle(ChoiceButtonStyle(isSelected: false, isCorrect: true))
                }
            }
        }
    }

    private var flashcards: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Flashcards")
                .font(.scaled(.title2).bold())
            TabView {
                ForEach(BayTransData.characters) { item in
                    VStack(spacing: 10) {
                        Text(item.baybayin)
                            .font(.system(size: 74, design: .serif))
                        Text(item.latin)
                            .font(.scaled(.title3).bold())
                        Text(item.note)
                            .font(.scaled(.subheadline))
                            .foregroundStyle(BayTransColors.secondaryText)
                            .multilineTextAlignment(.center)
                        Button { speech.speak(item.pronunciation, enabled: textToSpeech) } label: {
                            Label("Play", systemImage: "speaker.wave.2")
                        }
                        .buttonStyle(BayButtonStyle())
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 6)
                }
            }
            .frame(height: 250)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
}

struct WritingActivityView: View {
    @ObservedObject var store: WritingStore
    @ObservedObject var achievements: AchievementController
    @State private var mode: WritingMode = .creative
    @State private var prompt = BayTransData.writingPrompts.randomElement() ?? "Sumulat gamit ang Baybayin."
    @State private var title = ""
    @State private var bodyText = ""
    @State private var showTimer = true
    @State private var elapsed = 0
    @State private var exportDocument: ExportDocument?
    @State private var exportType: UTType = .pdf
    @State private var isExporting = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        FormShell(title: "Writing Activity", subtitle: "Create Baybayin writing exercises from randomized prompts.") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Mode", selection: $mode) {
                    ForEach(WritingMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { _, _ in randomizePrompt() }

                HStack {
                    Text(showTimer ? "Writing time: \(formatDuration(TimeInterval(elapsed)))" : "Timer hidden")
                    Spacer()
                    Button { showTimer.toggle() } label: { Image(systemName: showTimer ? "eye.slash" : "eye") }
                        .buttonStyle(BayButtonStyle())
                }

                Text(prompt)
                    .font(.scaled(.headline))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("New Prompt") { randomizePrompt() }
                    .buttonStyle(WideButtonStyle())

                TextField("Title", text: $title)
                    .textFieldStyle(BayTextFieldStyle())

                TextEditor(text: $bodyText)
                    .font(.system(size: 24, design: .serif))
                    .frame(minHeight: 220)
                    .padding(8)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack {
                    Button { save() } label: { Label("Save", systemImage: "tray.and.arrow.down") }
                        .buttonStyle(BayButtonStyle())
                    ShareLink(item: shareText) { Label("Share", systemImage: "square.and.arrow.up") }
                        .buttonStyle(BayButtonStyle())
                    Menu("Export") {
                        Button("PDF") { prepareExport(type: .pdf) }
                        Button("DOC") { prepareExport(type: .html) }
                    }
                    .buttonStyle(BayButtonStyle())
                }
            }
        }
        .navigationTitle("Activities")
        .onReceive(timer) { _ in elapsed += 1 }
        .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: exportType, defaultFilename: defaultExportName) { _ in }
    }

    private var shareText: String {
        "\(title.isEmpty ? "BayTrans Writing" : title)\n\nPrompt: \(prompt)\n\n\(bodyText)"
    }

    private var defaultExportName: String {
        title.isEmpty ? "BayTrans Writing" : title
    }

    private func randomizePrompt() {
        prompt = (mode == .creative ? BayTransData.writingPrompts : BayTransData.letterPrompts).randomElement() ?? prompt
    }

    private func save() {
        let entry = WritingEntry(title: title.isEmpty ? "Untitled Writing" : title, body: bodyText, prompt: prompt, mode: mode)
        store.saveEntry(entry)
        achievements.unlock("writer")
        if store.entries.count >= 3 { achievements.unlock("collector") }
    }

    private func prepareExport(type: UTType) {
        exportType = type
        if type == .pdf {
            exportDocument = ExportDocument(data: makePDFData())
        } else {
            exportDocument = ExportDocument(data: makeHTMLData())
        }
        isExporting = true
    }

    private func makeHTMLData() -> Data {
        let html = """
        <html><head><meta charset='utf-8'><title>\(defaultExportName)</title></head><body><h1>\(defaultExportName)</h1><p><b>Prompt:</b> \(prompt)</p><pre style='font-size:20px; white-space:pre-wrap;'>\(bodyText)</pre></body></html>
        """
        return Data(html.utf8)
    }

    private func makePDFData() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            let text = shareText as NSString
            text.draw(in: CGRect(x: 36, y: 36, width: 540, height: 720), withAttributes: [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.label])
        }
    }
}

struct SavedWorkView: View {
    @ObservedObject var store: WritingStore
    @State private var editingEntry: WritingEntry?

    var body: some View {
        FormShell(title: "Saved Work", subtitle: "Load, edit, share, and delete local writing activities.") {
            if store.entries.isEmpty {
                Text("No saved writing yet.")
                    .foregroundStyle(BayTransColors.secondaryText)
            } else {
                ForEach(store.entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.title)
                            .font(.scaled(.headline))
                        Text(entry.prompt)
                            .font(.scaled(.subheadline))
                            .foregroundStyle(BayTransColors.secondaryText)
                        Text(entry.body)
                            .lineLimit(3)
                            .font(.system(size: 18, design: .serif))
                        HStack {
                            Button { editingEntry = entry } label: { Label("Edit", systemImage: "pencil") }
                                .buttonStyle(BayButtonStyle())
                            ShareLink(item: "\(entry.title)\n\n\(entry.body)") { Label("Share", systemImage: "square.and.arrow.up") }
                                .buttonStyle(BayButtonStyle())
                            Button(role: .destructive) { store.deleteEntry(entry) } label: { Label("Delete", systemImage: "trash") }
                                .buttonStyle(BayButtonStyle())
                        }
                    }
                    .padding(12)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .navigationTitle("Saved Work")
        .sheet(item: $editingEntry) { entry in
            WritingEditView(store: store, entry: entry)
        }
    }
}

struct WritingEditView: View {
    @ObservedObject var store: WritingStore
    @Environment(\.dismiss) private var dismiss
    @State var entry: WritingEntry

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("Title", text: $entry.title)
                    .textFieldStyle(BayTextFieldStyle())
                Text(entry.prompt)
                    .font(.scaled(.subheadline))
                    .foregroundStyle(BayTransColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $entry.body)
                    .font(.system(size: 22, design: .serif))
                    .padding(8)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .background(BayTransColors.background.ignoresSafeArea())
            .navigationTitle("Edit Work")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.updatedAt = Date()
                        store.saveEntry(entry)
                        dismiss()
                    }
                }
            }
        }
    }
}

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

// MARK: - Reusable UI

struct FormShell<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.scaled(.largeTitle).bold())
                        .foregroundStyle(BayTransColors.ink)
                    Text(subtitle)
                        .font(.scaled(.subheadline))
                        .foregroundStyle(BayTransColors.secondaryText)
                }
                content
            }
            .padding(18)
        }
        .background(BayTransColors.background.ignoresSafeArea())
    }
}

struct StatGrid: View {
    let items: [(String, String)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.scaled(.caption))
                        .foregroundStyle(BayTransColors.secondaryText)
                    Text(item.1)
                        .font(.scaled(.title3).bold())
                        .foregroundStyle(BayTransColors.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(BayTransColors.field)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct BayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scaled(.headline))
            .foregroundStyle(BayTransColors.paper)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(configuration.isPressed ? BayTransColors.accentDark : BayTransColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scaled(.headline))
            .foregroundStyle(BayTransColors.paper)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? BayTransColors.accentDark : BayTransColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ChoiceButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isCorrect: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scaled(.body))
            .foregroundStyle(BayTransColors.ink)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }

    private var backgroundColor: Color {
        guard isSelected else { return BayTransColors.field }
        return isCorrect ? .green.opacity(0.25) : .red.opacity(0.25)
    }
}

struct BayTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.scaled(.body))
            .padding(12)
            .background(BayTransColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct BayTransColors {
    static let nearBlack = Color(hex: 0x1f1f1f)
    static let charcoal = Color(hex: 0x333333)
    static let accentDark = Color(hex: 0x716647)
    static let accent = Color(hex: 0x847752)
    static let paper = Color(hex: 0xe7e4d9)

    static let background = paper
    static let surface = Color.white.opacity(0.72)
    static let field = Color.white.opacity(0.58)
    static let ink = nearBlack
    static let secondaryText = charcoal.opacity(0.72)
}

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

private struct FontScaleKey: EnvironmentKey {
    static let defaultValue = 1.0
}

extension EnvironmentValues {
    var fontScale: Double {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }
}

extension Font {
    static func scaled(_ textStyle: Font.TextStyle) -> Font {
        .system(textStyle)
    }
}

func formatDuration(_ interval: TimeInterval) -> String {
    let seconds = Int(interval)
    return "\(seconds / 60):" + String(format: "%02d", seconds % 60)
}

#Preview {
    ContentView()
}
