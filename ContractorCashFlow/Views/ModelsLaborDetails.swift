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
    
    /// Whether this type charges per unit of time (hours/days) vs a fixed price
    var usesQuantity: Bool {
        switch self {
        case .hourly, .daily: return true
        case .contract, .subcontractor: return false
        }
    }
    
    /// Label for the rate field when creating/editing a worker
    var rateLabel: LocalizedStringKey {
        switch self {
        case .hourly: return LocalizationKey.Labor.ratePerHour
        case .daily: return LocalizationKey.Labor.ratePerDay
        case .contract: return LocalizationKey.Labor.contractPrice
        case .subcontractor: return LocalizationKey.Labor.contractPrice
        }
    }
    
    /// Short suffix for displaying rate (e.g. "/hr", "/day")
    var rateSuffix: String {
        switch self {
        case .hourly: return String(localized: "labor.rateSuffix.hourly")
        case .daily: return String(localized: "labor.rateSuffix.daily")
        case .contract, .subcontractor: return ""
        }
    }
    
    /// Label for the quantity input when creating a labor expense
    var quantityLabel: LocalizedStringKey {
        switch self {
        case .hourly: return LocalizationKey.Labor.hoursWorkedLabel
        case .daily: return LocalizationKey.Labor.daysWorkedLabel
        case .contract, .subcontractor: return LocalizationKey.Labor.hoursWorkedLabel // unused
        }
    }
    
    /// Unit name for display (e.g. "hours", "days")
    var unitName: String {
        switch self {
        case .hourly: return String(localized: "labor.unit.hours")
        case .daily: return String(localized: "labor.unit.days")
        case .contract, .subcontractor: return ""
        }
    }
}

@Model
final class LaborDetails {
    var id: UUID
    var workerName: String
    var laborType: LaborType
    var rate: Double?
    var notes: String?
    var createdDate: Date
    
    // Worker owns many labor expenses
    @Relationship(deleteRule: .nullify, inverse: \Expense.worker)
    var expenses: [Expense] = []
    
    init(
        id: UUID = UUID(),
        workerName: String,
        laborType: LaborType,
        rate: Double? = nil,
        notes: String? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.workerName = workerName
        self.laborType = laborType
        self.rate = rate
        self.notes = notes
        self.createdDate = createdDate
    }
    
    // MARK: - Computed Properties (aggregated from linked expenses)
    
    /// Total amount earned across all linked labor expenses
    var totalAmountEarned: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Total units worked across all linked labor expenses (hours or days depending on type)
    var totalUnitsWorked: Double {
        expenses.compactMap { $0.unitsWorked }.reduce(0, +)
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
