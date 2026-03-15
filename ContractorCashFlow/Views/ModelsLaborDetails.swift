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
        switch self {
        case .hourly:
            return String(localized: "labor.type.hourly")
        case .daily:
            return String(localized: "labor.type.daily")
        case .contract:
            return String(localized: "labor.type.contract")
        case .subcontractor:
            return String(localized: "labor.type.subcontractor")
        }
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
    var notes: String?
    var createdDate: Date
    
    // Worker owns many labor expenses
    @Relationship(deleteRule: .nullify, inverse: \Expense.worker)
    var expenses: [Expense] = []
    
    init(
        id: UUID = UUID(),
        workerName: String,
        laborType: LaborType,
        hourlyRate: Double? = nil,
        notes: String? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.workerName = workerName
        self.laborType = laborType
        self.hourlyRate = hourlyRate
        self.notes = notes
        self.createdDate = createdDate
    }
    
    // MARK: - Computed Properties (aggregated from linked expenses)
    
    /// Total amount earned across all linked labor expenses
    var totalAmountEarned: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Total hours worked across all linked labor expenses
    var totalHoursWorked: Double {
        expenses.compactMap { $0.hoursWorked }.reduce(0, +)
    }
    
    /// Total number of distinct work days
    var totalDaysWorked: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(expenses.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    /// Projects this worker is associated with (derived from expenses)
    var associatedProjects: [Project] {
        let projects = expenses.compactMap { $0.project }
        var seen = Set<UUID>()
        return projects.filter { seen.insert($0.id).inserted }
    }
}
