//
//  Project.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Foundation
import SwiftData

@Model
final class Project {
    // CloudKit requires all attributes to have default values
    var id: UUID = UUID()
    var name: String = ""
    var clientName: String = ""
    var budget: Double = 0
    var createdDate: Date = Date()
    var isActive: Bool = true
    
    // CloudKit requires all relationships to be optional
    @Relationship(deleteRule: .cascade, inverse: \Expense.project)
    var expenses: [Expense]?
    
    @Relationship(deleteRule: .cascade, inverse: \Invoice.project)
    var invoices: [Invoice]?
    
    init(
        id: UUID = UUID(),
        name: String,
        clientName: String,
        budget: Double,
        createdDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.budget = budget
        self.createdDate = createdDate
        self.isActive = isActive
    }
    
    // MARK: - Safe Accessors
    
    var safeExpenses: [Expense] { expenses ?? [] }
    var safeInvoices: [Invoice] { invoices ?? [] }
    
    // MARK: - Computed Properties
    
    /// Workers associated with this project (derived from labor expenses)
    var workers: [LaborDetails] {
        let laborExpenses = safeExpenses.filter { $0.category == .labor }
        let workerList = laborExpenses.compactMap { $0.worker }
        var seen = Set<UUID>()
        return workerList.filter { seen.insert($0.id).inserted }
    }
    
    /// Total amount spent on expenses for this project
    var totalExpenses: Double {
        safeExpenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Total income from paid invoices
    var totalIncome: Double {
        safeInvoices.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    /// Current balance (income minus expenses)
    var balance: Double {
        totalIncome - totalExpenses
    }
    
    /// Profit margin percentage
    var profitMargin: Double {
        guard totalIncome > 0 else { return 0 }
        return ((totalIncome - totalExpenses) / totalIncome) * 100
    }
    
    /// Budget utilization percentage
    var budgetUtilization: Double {
        guard budget > 0 else { return 0 }
        return (totalExpenses / budget) * 100
    }
}
