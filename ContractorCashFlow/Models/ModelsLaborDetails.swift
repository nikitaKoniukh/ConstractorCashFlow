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
    case subcontractor = "Subcontractor"
    
    var displayName: String {
        switch self {
        case .hourly:
            return LocalizationKey.Labor.hourlyString
        case .daily:
            return LocalizationKey.Labor.dailyString
        case .subcontractor:
            return LocalizationKey.Labor.subcontractorString
        }
    }
    
    var localizedDisplayName: LocalizedStringKey {
        switch self {
        case .hourly:
            return LocalizationKey.Labor.hourly
        case .daily:
            return LocalizationKey.Labor.daily
        case .subcontractor:
            return LocalizationKey.Labor.subcontractor
        }
    }
    
    /// Whether this type charges per unit of time (hours/days) vs a fixed price
    var usesQuantity: Bool {
        switch self {
        case .hourly, .daily: return true
        case .subcontractor: return false
        }
    }
    
    /// Label for the rate field when creating/editing a worker
    var rateLabel: LocalizedStringKey {
        switch self {
        case .hourly: return LocalizationKey.Labor.ratePerHour
        case .daily: return LocalizationKey.Labor.ratePerDay
        case .subcontractor: return LocalizationKey.Labor.contractPrice
        }
    }
    
    /// Short suffix for displaying rate (e.g. "/hr", "/day")
    var rateSuffix: String {
        switch self {
        case .hourly: return LocalizationKey.Labor.rateSuffixHourly
        case .daily: return LocalizationKey.Labor.rateSuffixDaily
        case .subcontractor: return ""
        }
    }
    
    /// Label for the quantity input when creating a labor expense
    var quantityLabel: LocalizedStringKey {
        switch self {
        case .hourly: return LocalizationKey.Labor.hoursWorkedLabel
        case .daily: return LocalizationKey.Labor.daysWorkedLabel
        case .subcontractor: return LocalizationKey.Labor.hoursWorkedLabel // unused
        }
    }
    
    /// Unit name for display (e.g. "hours", "days")
    var unitName: String {
        switch self {
        case .hourly: return LocalizationKey.Labor.unitHours
        case .daily: return LocalizationKey.Labor.unitDays
        case .subcontractor: return ""
        }
    }
}

@Model
final class LaborDetails {
    // CloudKit requires all attributes to have default values
    var id: UUID = UUID()
    var workerName: String = ""
    var laborType: LaborType = LaborType.hourly
    var rate: Double?           // legacy / default rate
    var hourlyRate: Double?     // rate per hour (if worker supports hourly billing)
    var dailyRate: Double?      // rate per day (if worker supports daily billing)
    var notes: String?
    var createdDate: Date = Date()
    
    // CloudKit requires all relationships to be optional
    @Relationship(deleteRule: .nullify, inverse: \Expense.worker)
    var expenses: [Expense]?
    
    init(
        id: UUID = UUID(),
        workerName: String,
        laborType: LaborType,
        rate: Double? = nil,
        hourlyRate: Double? = nil,
        dailyRate: Double? = nil,
        notes: String? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.workerName = workerName
        self.laborType = laborType
        self.rate = rate
        self.hourlyRate = hourlyRate
        self.dailyRate = dailyRate
        self.notes = notes
        self.createdDate = createdDate
    }
    
    /// Effective rate for a given labor type
    func effectiveRate(for type: LaborType) -> Double? {
        switch type {
        case .hourly: return hourlyRate ?? (laborType == .hourly ? rate : nil)
        case .daily: return dailyRate ?? (laborType == .daily ? rate : nil)
        case .subcontractor: return rate
        }
    }
    
    /// Whether this worker can bill by the hour
    var supportsHourly: Bool { hourlyRate != nil || laborType == .hourly }
    
    /// Whether this worker can bill by the day
    var supportsDaily: Bool { dailyRate != nil || laborType == .daily }
    
    // MARK: - Safe Accessor
    
    var safeExpenses: [Expense] { expenses ?? [] }
    
    // MARK: - Computed Properties (aggregated from linked expenses)
    
    /// Total amount earned across all linked labor expenses
    var totalAmountEarned: Double {
        safeExpenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Total units worked across all linked labor expenses (hours or days depending on type)
    var totalUnitsWorked: Double {
        safeExpenses.compactMap { $0.unitsWorked }.reduce(0, +)
    }
    
    /// Projects this worker is associated with (derived from expenses)
    var associatedProjects: [Project] {
        let projects = safeExpenses.compactMap { $0.project }
        var seen = Set<UUID>()
        return projects.filter { seen.insert($0.id).inserted }
    }
}
