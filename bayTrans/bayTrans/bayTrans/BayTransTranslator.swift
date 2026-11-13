import SwiftUI
import AVFoundation
import Combine

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
