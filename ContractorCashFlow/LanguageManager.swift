//
//  LanguageManager.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI

/// Manages application language preferences and runtime language switching
@Observable
final class LanguageManager {
    /// Shared singleton instance
    static let shared = LanguageManager()
    
    /// Currently selected locale
    var currentLocale: Locale {
        didSet {
            saveLocale()
        }
    }
    
    /// Available languages
    enum SupportedLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case hebrew = "he"
        case russian = "ru"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .hebrew: return "עברית"
            case .russian: return "Русский"
            }
        }
        
        var locale: Locale {
            Locale(identifier: rawValue)
        }
        
        var layoutDirection: LayoutDirection {
            switch self {
            case .hebrew:
                return .rightToLeft
            case .english, .russian:
                return .leftToRight
            }
        }
    }
    
    /// Current language based on locale
    var currentLanguage: SupportedLanguage {
        get {
            SupportedLanguage(rawValue: currentLocale.language.languageCode?.identifier ?? "en") ?? .english
        }
        set {
            currentLocale = newValue.locale
        }
    }
    
    /// Layout direction for current language
    var layoutDirection: LayoutDirection {
        currentLanguage.layoutDirection
    }
    
    private init() {
        // Load saved locale from UserDefaults or use system default
        if let savedLanguageCode = UserDefaults.standard.string(forKey: StorageKey.appLanguage),
           let language = SupportedLanguage(rawValue: savedLanguageCode) {
            self.currentLocale = language.locale
        } else {
            // Try to match system language
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            if let matchedLanguage = SupportedLanguage(rawValue: systemLanguage) {
                self.currentLocale = matchedLanguage.locale
            } else {
                self.currentLocale = SupportedLanguage.english.locale
            }
        }
    }
    
    /// Save current locale to UserDefaults
    private func saveLocale() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: StorageKey.appLanguage)
    }
    
    /// Switch to a specific language
    func switchLanguage(to language: SupportedLanguage) {
        currentLanguage = language
    }
}

/// Environment key for language manager
struct LanguageManagerKey: EnvironmentKey {
    static let defaultValue = LanguageManager.shared
}

extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}
