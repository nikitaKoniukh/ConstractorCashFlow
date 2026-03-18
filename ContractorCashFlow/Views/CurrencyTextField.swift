import SwiftUI

/// A TextField that formats monetary values with grouping separators (e.g., 1,000,000) live as the user types.
/// Uses `Locale.current` to determine the correct decimal and grouping separator characters.
struct CurrencyTextField: View {
    let title: LocalizedStringKey
    @Binding var value: Double?
    let currencyCode: String
    
    @State private var text: String = ""
    @State private var isInitialized: Bool = false
    @State private var isUpdatingFromText: Bool = false
    
    private var decimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
    }
    
    /// Returns the currency symbol for the given currency code (e.g., "₪" for ILS, "$" for USD)
    private var currencySymbol: String {
        let locale = Locale.current
        // Try to find symbol from current locale with the given currency code
        if let symbol = locale.currencySymbol,
           locale.currency?.identifier == currencyCode {
            return symbol
        }
        // Fallback: look up symbol by finding a locale that uses this currency
        let identifier = Locale.availableIdentifiers.first { id in
            Locale(identifier: id).currency?.identifier == currencyCode
        }
        if let identifier, let symbol = Locale(identifier: identifier).currencySymbol {
            return symbol
        }
        return currencyCode
    }
    
    init(_ title: LocalizedStringKey, value: Binding<Double?>, currencyCode: String) {
        self.title = title
        self._value = value
        self.currencyCode = currencyCode
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(currencySymbol)
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .accessibilityLabel(title)
                .onChange(of: text) { oldValue, newValue in
                    handleTextChange(oldValue: oldValue, newValue: newValue)
                }
                .onChange(of: value) { _, newVal in
                    handleExternalValueChange(newVal)
                }
                .onAppear {
                    initializeText()
                }
        }
    }
    
    // MARK: - Formatting Logic
    
    private func initializeText() {
        guard !isInitialized else { return }
        isInitialized = true
        if let value = value, value > 0 {
            text = formatNumber(value)
        }
    }
    
    private func handleExternalValueChange(_ newVal: Double?) {
        guard !isUpdatingFromText else { return }
        if let newVal = newVal, newVal > 0 {
            let formatted = formatNumber(newVal)
            if text != formatted {
                text = formatted
            }
        } else if !text.isEmpty {
            text = ""
        }
    }
    
    private func handleTextChange(oldValue: String, newValue: String) {
        let decSep = decimalSeparator
        
        // 1. Strip everything except digits and one decimal separator
        var cleaned = ""
        var hasDecimal = false
        for char in newValue {
            if char.isNumber {
                cleaned.append(char)
            } else if String(char) == decSep && !hasDecimal {
                hasDecimal = true
                cleaned.append(char)
            }
        }
        
        // 2. Limit decimal places to 2
        if let decRange = cleaned.range(of: decSep) {
            let afterDecimal = cleaned[decRange.upperBound...]
            if afterDecimal.count > 2 {
                let endIndex = cleaned.index(decRange.upperBound, offsetBy: 2)
                cleaned = String(cleaned[cleaned.startIndex..<endIndex])
            }
        }
        
        // 3. Parse the numeric value
        let parseString = cleaned.replacingOccurrences(of: decSep, with: ".")
        let numericValue = Double(parseString)
        
        // 4. Update the binding
        isUpdatingFromText = true
        value = cleaned.isEmpty ? nil : numericValue
        isUpdatingFromText = false
        
        // 5. Format with grouping separators
        if cleaned.isEmpty {
            if text != "" { text = "" }
            return
        }
        
        if hasDecimal {
            // Split on decimal separator
            let parts = cleaned.split(separator: Character(decSep),
                                       maxSplits: 1,
                                       omittingEmptySubsequences: false)
            let integerPart = String(parts[0])
            let decimalPart = parts.count > 1 ? String(parts[1]) : ""
            
            // Format integer part with grouping
            let formattedInt = formatIntegerPart(integerPart)
            let formatted = formattedInt + decSep + decimalPart
            if text != formatted { text = formatted }
        } else {
            // No decimal — format the whole number
            let formatted = formatIntegerPart(cleaned)
            if text != formatted { text = formatted }
        }
    }
    
    // MARK: - Helpers
    
    private func formatIntegerPart(_ intString: String) -> String {
        guard let intVal = Int(intString) else { return intString }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: intVal)) ?? intString
    }
    
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
