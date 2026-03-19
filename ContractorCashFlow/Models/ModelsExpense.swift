//
//  Expense.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Foundation
import SwiftUI
import SwiftData

enum ExpenseCategory: String, Codable, CaseIterable {
    case materials = "Materials"
    case labor = "Labor"
    case equipment = "Equipment"
    case misc = "Miscellaneous"
    
    var displayName: String {
        rawValue
    }

    var localizedDisplayName: LocalizedStringKey {
        switch self {
        case .materials:
            return LocalizationKey.Expense.materials
        case .labor:
            return LocalizationKey.Expense.labor
        case .equipment:
            return LocalizationKey.Expense.equipment
        case .misc:
            return LocalizationKey.Expense.miscellaneous
        }
    }
}

@Model
final class Expense {
    // CloudKit requires all attributes to have default values
    var id: UUID = UUID()
    var category: ExpenseCategory = ExpenseCategory.misc
    var amount: Double = 0
    var descriptionText: String = ""
    var date: Date = Date()
    
    // Relationships (already optional)
    var project: Project?
    var worker: LaborDetails?
    
    // Units worked: hours for hourly, days for daily (nil for contract/subcontractor)
    var unitsWorked: Double?
    
    // Labor type at the time this expense was created (preserved even if worker type changes later)
    var laborTypeSnapshot: LaborType?

    // Scanned receipt/invoice image stored as JPEG data.
    // @Attribute(.externalStorage) makes SwiftData save large blobs as a
    // CKAsset instead of an inline record field, which is required for
    // CloudKit sync to work correctly with binary data.
    @Attribute(.externalStorage) var receiptImageData: Data?

    init(
        id: UUID = UUID(),
        category: ExpenseCategory,
        amount: Double,
        descriptionText: String,
        date: Date = Date(),
        project: Project? = nil,
        worker: LaborDetails? = nil,
        unitsWorked: Double? = nil,
        laborTypeSnapshot: LaborType? = nil,
        receiptImageData: Data? = nil
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.descriptionText = descriptionText
        self.date = date
        self.project = project
        self.worker = worker
        self.unitsWorked = unitsWorked
        self.laborTypeSnapshot = laborTypeSnapshot
        self.receiptImageData = receiptImageData
    }
}

extension ExpenseCategory {
    var iconName: String {
        switch self {
        case .materials: return "hammer.fill"
        case .labor: return "person.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .misc: return "ellipsis.circle.fill"
        }
    }
}
