import SwiftUI

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
