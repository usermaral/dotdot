//
//  AppFonts.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import CoreText
import SwiftUI

/// Bundled Google Fonts (Resources/Fonts). Registered at launch instead of via
/// Info.plist `UIAppFonts`, because the target uses a generated Info.plist.
enum AppFonts {
    static func register() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                print("Font registration failed: \(url.lastPathComponent)")
            }
        }
    }
}

extension Font {
    /// Pixelify Sans, sizes in design points (not scaled by Dynamic Type, like the mockups).
    static func pixelify(_ size: CGFloat, semibold: Bool = false) -> Font {
        .custom(semibold ? "PixelifySans-SemiBold" : "PixelifySans-Regular", fixedSize: size)
    }

    static func vt323(_ size: CGFloat) -> Font {
        .custom("VT323-Regular", fixedSize: size)
    }

    static func shareTechMono(_ size: CGFloat) -> Font {
        .custom("ShareTechMono-Regular", fixedSize: size)
    }

    static func spaceMono(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "SpaceMono-Bold" : "SpaceMono-Regular", fixedSize: size)
    }

    static func yellowtail(_ size: CGFloat) -> Font {
        .custom("Yellowtail-Regular", fixedSize: size)
    }
}
