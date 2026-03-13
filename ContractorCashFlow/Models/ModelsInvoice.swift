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
    var id: UUID
    var amount: Double
    var dueDate: Date
    var isPaid: Bool
    var clientName: String
    var createdDate: Date
    
    // Relationship
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
