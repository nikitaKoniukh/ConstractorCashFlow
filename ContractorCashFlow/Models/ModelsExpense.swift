//
//  Expense.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Foundation
import SwiftData

enum ExpenseCategory: String, Codable, CaseIterable {
    case materials = "Materials"
    case labor = "Labor"
    case equipment = "Equipment"
    case misc = "Miscellaneous"
    
    var displayName: String {
        rawValue
    }
}

@Model
final class Expense {
    var id: UUID
    var category: ExpenseCategory
    var amount: Double
    var descriptionText: String
    var date: Date
    
    // Relationship
    var project: Project?
    
    init(
        id: UUID = UUID(),
        category: ExpenseCategory,
        amount: Double,
        descriptionText: String,
        date: Date = Date(),
        project: Project? = nil
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.descriptionText = descriptionText
        self.date = date
        self.project = project
    }
}

