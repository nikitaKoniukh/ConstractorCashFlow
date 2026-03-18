//
//  InvoiceStatusFilter.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//


enum InvoiceStatusFilter: String, CaseIterable {
    case all = "All"
    case paid = "Paid"
    case unpaid = "Unpaid"
    case overdue = "Overdue"
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .all: return "doc.text"
        case .paid: return "checkmark.circle.fill"
        case .unpaid: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
}