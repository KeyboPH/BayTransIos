import SwiftUI
import Combine

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
