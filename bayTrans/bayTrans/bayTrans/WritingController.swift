import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers
import UIKit

final class WritingController: ObservableObject {
    @Published var mode: WritingMode = .creative
    @Published var prompt: String
    @Published var title: String = ""
    @Published var bodyText: String = ""
    @Published var showTimer: Bool = true
    @Published var elapsed: Int = 0
    @Published var exportDocument: ExportDocument?
    @Published var exportType: UTType = .pdf
    @Published var isExporting: Bool = false

    private let store: WritingStore
    private let achievements: AchievementController
    private var timerCancellable: AnyCancellable?

    init(store: WritingStore, achievements: AchievementController) {
        self.store = store
        self.achievements = achievements
        self.prompt = BayTransData.writingPrompts.randomElement() ?? "Sumulat gamit ang Baybayin."
        self.exportDocument = nil

        self.timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed += 1
            }
    }

    var shareText: String {
        "\(title.isEmpty ? "BayTrans Writing" : title)\n\nPrompt: \(prompt)\n\n\(bodyText)"
    }

    var defaultExportName: String {
        title.isEmpty ? "BayTrans Writing" : title
    }

    func randomizePrompt() {
        prompt = (mode == .creative ? BayTransData.writingPrompts : BayTransData.letterPrompts).randomElement() ?? prompt
    }

    func toggleTimer() {
        showTimer.toggle()
    }

    func save() {
        let entry = WritingEntry(title: title.isEmpty ? "Untitled Writing" : title, body: bodyText, prompt: prompt, mode: mode)
        store.saveEntry(entry)
        achievements.unlock("writer")
        if store.entries.count >= 3 { achievements.unlock("collector") }
    }

    func prepareExport(type: UTType) {
        exportType = type
        exportDocument = type == .pdf ? ExportDocument(data: makePDFData()) : ExportDocument(data: makeHTMLData())
        isExporting = true
    }

    func makeHTMLData() -> Data {
        let html = """
        <html><head><meta charset='utf-8'><title>\(defaultExportName)</title></head><body><h1>\(defaultExportName)</h1><p><b>Prompt:</b> \(prompt)</p><pre style='font-size:20px; white-space:pre-wrap;'>\(bodyText)</pre></body></html>
        """
        return Data(html.utf8)
    }

    func makePDFData() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            let text = self.shareText as NSString
            text.draw(in: CGRect(x: 36, y: 36, width: 540, height: 720), withAttributes: [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.label])
        }
    }
}
