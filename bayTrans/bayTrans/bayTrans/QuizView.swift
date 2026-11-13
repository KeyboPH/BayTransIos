import SwiftUI
import Combine

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
