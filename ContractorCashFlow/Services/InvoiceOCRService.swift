//
//  InvoiceOCRService.swift
//  ContractorCashFlow
//

import Vision
import UIKit

struct ScannedInvoiceData {
    var amount: Double?
    var date: Date?
    var description: String
}

struct InvoiceOCRService {

    /// Runs Vision text recognition on the given image and extracts expense fields.
    static func extractData(from image: UIImage) async -> ScannedInvoiceData {
        guard let cgImage = image.cgImage else {
            return ScannedInvoiceData(amount: nil, date: nil, description: "")
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let result = parse(lines: lines)
                continuation.resume(returning: result)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            request.recognitionLanguages = ["he", "ru", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Parsing

    private static func parse(lines: [String]) -> ScannedInvoiceData {
        var date: Date? = nil
        var descriptionCandidates: [String] = []

        // First pass: collect dates and description candidates
        for line in lines {
            if date == nil, let found = extractDate(from: line) {
                date = found
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.count >= 3 && trimmed.count <= 80 && !isNumericLine(trimmed) {
                descriptionCandidates.append(trimmed)
            }
        }

        // Second pass: find the best "total to pay" amount using keyword context
        let amount = extractTotalAmount(from: lines)
        let description = bestDescription(from: descriptionCandidates)

        return ScannedInvoiceData(amount: amount, date: date, description: description)
    }

    // MARK: - Total amount extraction

    /// Keywords that appear on or near the "total to pay" line in Hebrew, Russian, and English invoices.
    private static let totalKeywords: [String] = [
        // Hebrew
        "סה\"כ לתשלום", "לתשלום", "סכום לתשלום", "סה\"כ",
        // Russian
        "итого к оплате", "итого", "к оплате", "сумма",
        // English
        "total due", "amount due", "total to pay", "balance due",
        "grand total", "total", "amount payable", "pay this amount"
    ]

    private static func extractTotalAmount(from lines: [String]) -> Double? {
        // Strategy 1: line contains a "total" keyword AND a decimal number on the same line
        for line in lines {
            let lower = line.lowercased()
            let hasTotalKeyword = totalKeywords.contains { lower.contains($0.lowercased()) }
            if hasTotalKeyword, let amount = extractAmount(from: line, requireDecimal: true) {
                return amount
            }
        }

        // Strategy 2: "total" keyword line, then look at the next 1-3 lines for a decimal number
        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            let hasTotalKeyword = totalKeywords.contains { lower.contains($0.lowercased()) }
            if hasTotalKeyword {
                let lookAhead = min(index + 4, lines.count)
                for nextLine in lines[(index + 1)..<lookAhead] {
                    if let amount = extractAmount(from: nextLine, requireDecimal: true) {
                        return amount
                    }
                }
            }
        }

        // Strategy 3: line with a currency symbol and a decimal number
        for line in lines {
            let hasCurrency = line.contains("₪") || line.contains("$") || line.contains("€") || line.contains("£")
            if hasCurrency, let amount = extractAmount(from: line, requireDecimal: true) {
                return amount
            }
        }

        // Strategy 4: any decimal number (X.XX format) — avoids plain integer codes like 985
        let decimalAmounts = lines.compactMap { extractAmount(from: $0, requireDecimal: true) }
        if let best = decimalAmounts.max() { return best }

        // Strategy 5: last resort — any number, but only if it's a plausible monetary value
        let allAmounts = lines.compactMap { extractAmount(from: $0) }
            .filter { $0 != $0.rounded() || $0 < 10_000 } // prefer non-round or small values
        return allAmounts.max()
    }

    // MARK: - Amount extraction

    /// Extracts a monetary amount. Requires a decimal point (e.g. 670.10) OR a currency symbol
    /// to avoid picking up plain integers like codes, IDs, and reference numbers.
    private static func extractAmount(from line: String, requireDecimal: Bool = false) -> Double? {
        // Match: ₪670.10 | $1,234.56 | 670.10 | ILS 670
        let pattern = #"(?:[$€£₪]|USD|EUR|GBP|ILS)?\s*(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?|\d+\.\d{1,2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let matchRange = Range(match.range(at: 1), in: line) else { return nil }
        let numberString = String(line[matchRange])
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard let value = Double(numberString), value > 0, value < 1_000_000 else { return nil }

        // If requireDecimal is set, reject whole integers (likely codes/IDs, not money)
        if requireDecimal && !numberString.contains(".") { return nil }

        return value
    }

    // MARK: - Date extraction

    private static func extractDate(from line: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = [
                "MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd",
                "MMM dd, yyyy", "dd MMM yyyy", "MMMM dd, yyyy",
                "MM-dd-yyyy", "dd-MM-yyyy", "d/M/yyyy", "M/d/yyyy",
                "dd.MM.yyyy", "d.M.yyyy"
            ]
            return formats.map { fmt in
                let f = DateFormatter()
                f.dateFormat = fmt
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }
        }()

        let datePattern = #"\b\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}\b|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|янв|фев|мар|апр|май|июн|июл|авг|сен|окт|ноя|дек)\w*\.?\s+\d{1,2},?\s+\d{4}\b"#
        guard let regex = try? NSRegularExpression(pattern: datePattern, options: .caseInsensitive) else { return nil }
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        let substr = nsLine.substring(with: match.range)

        for formatter in formatters {
            if let date = formatter.date(from: substr) {
                return date
            }
        }
        return nil
    }

    // MARK: - Description

    private static func isNumericLine(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: "[$€£₪,. ]", with: "", options: .regularExpression)
        return stripped.allSatisfy { $0.isNumber } && !stripped.isEmpty
    }

    private static func bestDescription(from candidates: [String]) -> String {
        let keywords = [
            // English
            "invoice", "receipt", "bill", "services", "materials", "labor", "supply",
            // Hebrew
            "חשבונית", "קבלה", "שירותים", "חומרים", "עבודה", "ארנונה",
            // Russian
            "счёт", "квитанция", "услуги", "материалы", "работа"
        ]
        let scored = candidates.map { line -> (String, Int) in
            let lower = line.lowercased()
            let score = keywords.reduce(0) { $0 + (lower.contains($1) ? 2 : 0) }
                + (line.count > 5 ? 1 : 0)
            return (line, score)
        }
        return scored.max(by: { $0.1 < $1.1 })?.0 ?? candidates.first ?? ""
    }
}
