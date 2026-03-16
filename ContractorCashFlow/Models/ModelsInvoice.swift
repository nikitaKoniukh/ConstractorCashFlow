//
//  Invoice.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Foundation
import SwiftData

@Model
final class Invoice {
    // CloudKit requires all attributes to have default values
    var id: UUID = UUID()
    var amount: Double = 0
    var dueDate: Date = Date()
    var isPaid: Bool = false
    var clientName: String = ""
    var createdDate: Date = Date()
    
    // Relationship (already optional)
    var project: Project?
    
    init(
        id: UUID = UUID(),
        amount: Double,
        dueDate: Date,
        isPaid: Bool = false,
        clientName: String,
        createdDate: Date = Date(),
        project: Project? = nil
    ) {
        self.id = id
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.clientName = clientName
        self.createdDate = createdDate
        self.project = project
    }
    
    // MARK: - Computed Properties
    
    /// Whether the invoice is overdue
    var isOverdue: Bool {
        dueDate < Date() && !isPaid
    }
}
