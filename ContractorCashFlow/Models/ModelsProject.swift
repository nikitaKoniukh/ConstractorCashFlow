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
    var id: UUID
    var name: String
    var clientName: String
    var budget: Double
    var createdDate: Date
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Expense.project)
    var expenses: [Expense] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Invoice.project)
    var invoices: [Invoice] = []
    
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
    
    // MARK: - Computed Properties
    
    /// Workers associated with this project (derived from labor expenses)
    var workers: [LaborDetails] {
        let laborExpenses = expenses.filter { $0.category == .labor }
        let workerList = laborExpenses.compactMap { $0.worker }
        var seen = Set<UUID>()
        return workerList.filter { seen.insert($0.id).inserted }
    }
    
    /// Total amount spent on expenses for this project
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Total income from paid invoices
    var totalIncome: Double {
        invoices.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
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
