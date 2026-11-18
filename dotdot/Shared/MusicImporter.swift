//
//  MusicImporter.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI
import UniformTypeIdentifiers

/// File picker for local audio, shared by all skins.
private struct MusicImporter: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(PlayerModel.self) private var player

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isPresented, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls): Task { await player.importFiles(urls) }
                case .failure(let error): player.errorMessage = error.localizedDescription
                }
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

extension View {
    func musicImporter(isPresented: Binding<Bool>) -> some View {
        modifier(MusicImporter(isPresented: isPresented))
    }
}
