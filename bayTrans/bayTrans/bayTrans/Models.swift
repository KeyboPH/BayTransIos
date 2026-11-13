import SwiftUI
import Foundation
import UniformTypeIdentifiers

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
