//
//  MusicImporter.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// File picker for local audio, shared by all skins. Picks files as copies: the app never
/// holds the original open, so it can still be moved or deleted in the Files app.
/// (SwiftUI's `fileImporter` opens files in place, which Files reports as "in use".)
private struct MusicImporter: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(PlayerModel.self) private var player

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                AudioDocumentPicker { urls in
                    Task {
                        await player.importFiles(urls)
                        // The picker's copies live in our tmp/Inbox; the library has its own now.
                        urls.forEach { try? FileManager.default.removeItem(at: $0) }
                    }
                }
                .ignoresSafeArea()
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") {}
            } message: {
                Text(player.errorMessage ?? "")
            }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { player.errorMessage != nil }, set: { if !$0 { player.errorMessage = nil } })
    }
}

/// `UIDocumentPickerViewController` in copy mode, for audio files.
private struct AudioDocumentPicker: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void

        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}

extension View {
    func musicImporter(isPresented: Binding<Bool>) -> some View {
        modifier(MusicImporter(isPresented: isPresented))
    }
}
