import SwiftUI

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
