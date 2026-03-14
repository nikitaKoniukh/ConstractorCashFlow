//
//  LaborDetails.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 14/03/2026.
//

import Foundation
import SwiftUI
import SwiftData

enum LaborType: String, Codable, CaseIterable {
    case hourly = "Hourly"
    case daily = "Daily"
    case contract = "Contract"
    case subcontractor = "Subcontractor"
    
    var displayName: String {
        rawValue
    }
    
    var localizedDisplayName: LocalizedStringKey {
        switch self {
        case .hourly:
            return LocalizationKey.Labor.hourly
        case .daily:
            return LocalizationKey.Labor.daily
        case .contract:
            return LocalizationKey.Labor.contract
        case .subcontractor:
            return LocalizationKey.Labor.subcontractor
        }
    }
}

@Model
final class LaborDetails {
    var id: UUID
    var workerName: String
    var laborType: LaborType
    var hourlyRate: Double?
    var hoursWorked: Double?
    var totalAmount: Double
    var workDate: Date
    var notes: String?
    var isCompleted: Bool
    
    // Relationship to Expense
    var expense: Expense?
    
    // Relationship to Project (optional direct link)
    var project: Project?
    
    init(
        id: UUID = UUID(),
        workerName: String,
        laborType: LaborType,
        hourlyRate: Double? = nil,
        hoursWorked: Double? = nil,
        totalAmount: Double,
        workDate: Date = Date(),
        notes: String? = nil,
        isCompleted: Bool = false,
        expense: Expense? = nil,
        project: Project? = nil
    ) {
        self.id = id
        self.workerName = workerName
        self.laborType = laborType
        self.hourlyRate = hourlyRate
        self.hoursWorked = hoursWorked
        self.totalAmount = totalAmount
        self.workDate = workDate
        self.notes = notes
        self.isCompleted = isCompleted
        self.expense = expense
        self.project = project
    }
    
    // MARK: - Computed Properties
    
    /// Calculated amount based on hourly rate and hours worked
    var calculatedAmount: Double {
        guard let rate = hourlyRate, let hours = hoursWorked else {
            return totalAmount
        }
        return rate * hours
    }
    
    /// Check if labor is hourly-based
    var isHourlyBased: Bool {
        laborType == .hourly
    }
    
    /// Formatted work duration
    var formattedDuration: String {
        guard let hours = hoursWorked else { return "N/A" }
        if hours == 1 {
            return "1 hour"
        } else {
            return "\(String(format: "%.1f", hours)) hours"
        }
    }
}

// MARK: - Extension for Expense to support Labor
extension Expense {
    @Relationship(deleteRule: .cascade, inverse: \LaborDetails.expense)
    var laborDetails: [LaborDetails]? { get { nil } set { } }
    
    /// Check if this expense has associated labor details
    var hasLaborDetails: Bool {
        laborDetails?.isEmpty == false
    }
    
    /// Get total labor hours if applicable
    var totalLaborHours: Double {
        laborDetails?.compactMap { $0.hoursWorked }.reduce(0, +) ?? 0
    }
}
