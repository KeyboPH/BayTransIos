import SwiftUI
import Combine
import UniformTypeIdentifiers
import UIKit

struct WritingActivityView: View {
    @ObservedObject var store: WritingStore
    @ObservedObject var achievements: AchievementController
    @StateObject private var controller: WritingController

    init(store: WritingStore, achievements: AchievementController) {
        self.store = store
        self.achievements = achievements
        _controller = StateObject(wrappedValue: WritingController(store: store, achievements: achievements))
    }

    var body: some View {
        FormShell(title: "Writing Activity", subtitle: "Create Baybayin writing exercises from randomized prompts.") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Mode", selection: $controller.mode) {
                    ForEach(WritingMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: controller.mode) { _, _ in controller.randomizePrompt() }

                HStack {
                    Text(controller.showTimer ? "Writing time: \(formatDuration(TimeInterval(controller.elapsed)))" : "Timer hidden")
                    Spacer()
                    Button { controller.toggleTimer() } label: { Image(systemName: controller.showTimer ? "eye.slash" : "eye") }
                        .buttonStyle(BayButtonStyle())
                }

                Text(controller.prompt)
                    .font(.scaled(.headline))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("New Prompt") { controller.randomizePrompt() }
                    .buttonStyle(WideButtonStyle())

                TextField("Title", text: $controller.title)
                    .textFieldStyle(BayTextFieldStyle())

                TextEditor(text: $controller.bodyText)
                    .font(.system(size: 24, design: .serif))
                    .frame(minHeight: 220)
                    .padding(8)
                    .background(BayTransColors.field)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack {
                    Button { controller.save() } label: { Label("Save", systemImage: "tray.and.arrow.down") }
                        .buttonStyle(BayButtonStyle())
                    ShareLink(item: controller.shareText) { Label("Share", systemImage: "square.and.arrow.up") }
                        .buttonStyle(BayButtonStyle())
                    Menu("Export") {
                        Button("PDF") { controller.prepareExport(type: .pdf) }
                        Button("DOC") { controller.prepareExport(type: .html) }
                    }
                    .buttonStyle(BayButtonStyle())
                }
            }
        }
        .navigationTitle("Activities")
        .fileExporter(isPresented: $controller.isExporting, document: controller.exportDocument, contentType: controller.exportType, defaultFilename: controller.defaultExportName) { _ in }
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
