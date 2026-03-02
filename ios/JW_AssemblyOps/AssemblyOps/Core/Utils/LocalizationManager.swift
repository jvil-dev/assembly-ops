//
//  LocalizationManager.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//
//  Manages app language selection and localization.
//  Stores preference in UserDefaults and provides localized strings.
//
//  Usage:
//    Text("common.cancel".localized)
//    Text("volunteer.addedSuccess".localized(with: volunteerName))
//
//    Picker("Language", selection: $localizationManager.currentLanguage) {
//        ForEach(localizationManager.availableLanguages, id: \.code) { lang in
//            Text(lang.name).tag(lang.code)
//        }
//    }
//

import Foundation
import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
        }
    }

    private init() {
        // Load saved language or default to device language
        if let saved = UserDefaults.standard.string(forKey: "app_language") {
            currentLanguage = saved
        } else {
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = ["en", "es"].contains(deviceLanguage) ? deviceLanguage : "en"
        }
    }

    var availableLanguages: [(code: String, name: String)] {
        [
            ("en", "English"),
            ("es", "Español"),
        ]
    }

    func setLanguage(_ code: String) {
        guard ["en", "es"].contains(code) else { return }
        currentLanguage = code
    }
}

// MARK: - String Extension for Localization

extension String {
    var localized: String {
        let language = LocalizationManager.shared.currentLanguage

        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }

        return NSLocalizedString(self, bundle: bundle, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
