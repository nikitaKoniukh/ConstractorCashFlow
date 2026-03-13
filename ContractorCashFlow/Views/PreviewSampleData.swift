//
//  PreviewSampleData.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Foundation
import SwiftData

/// Helper for generating sample data for SwiftUI previews
@MainActor
struct PreviewSampleData {
    
    /// Creates a model container with sample data for previews
    static func makePreviewContainer() -> ModelContainer {
        let schema = Schema([
            Project.self,
            Expense.self,
            Invoice.self,
            Client.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        guard let container = try? ModelContainer(for: schema, configurations: [configuration]) else {
            fatalError("Failed to create preview container")
        }
        
        let context = container.mainContext
        
        // Create sample projects
        let project1 = Project(
            name: "Kitchen Remodel",
            clientName: "John Smith",
            budget: 15000,
            createdDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
            isActive: true
        )
        
        let project2 = Project(
            name: "Bathroom Renovation",
            clientName: "Jane Doe",
            budget: 8000,
            createdDate: Date().addingTimeInterval(-45 * 24 * 60 * 60),
            isActive: true
        )
        
        let project3 = Project(
            name: "Deck Construction",
            clientName: "Bob Johnson",
            budget: 12000,
            createdDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            isActive: false
        )
        
        context.insert(project1)
        context.insert(project2)
        context.insert(project3)
        
        // Create sample expenses
        let expenses = [
            // Project 1 expenses
            Expense(
                category: .materials,
                amount: 3500,
                descriptionText: "Cabinets and countertops",
                date: Date().addingTimeInterval(-55 * 24 * 60 * 60),
                project: project1
            ),
            Expense(
                category: .labor,
                amount: 2000,
                descriptionText: "Installation labor",
                date: Date().addingTimeInterval(-50 * 24 * 60 * 60),
                project: project1
            ),
            Expense(
                category: .equipment,
                amount: 500,
                descriptionText: "Tool rental",
                date: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                project: project1
            ),
            
            // Project 2 expenses
            Expense(
                category: .materials,
                amount: 1500,
                descriptionText: "Tiles and fixtures",
                date: Date().addingTimeInterval(-40 * 24 * 60 * 60),
                project: project2
            ),
            Expense(
                category: .labor,
                amount: 1200,
                descriptionText: "Plumbing work",
                date: Date().addingTimeInterval(-35 * 24 * 60 * 60),
                project: project2
            ),
            
            // Project 3 expenses
            Expense(
                category: .materials,
                amount: 4000,
                descriptionText: "Lumber and decking",
                date: Date().addingTimeInterval(-25 * 24 * 60 * 60),
                project: project3
            ),
            Expense(
                category: .labor,
                amount: 3000,
                descriptionText: "Construction labor",
                date: Date().addingTimeInterval(-20 * 24 * 60 * 60),
                project: project3
            ),
            Expense(
                category: .misc,
                amount: 800,
                descriptionText: "Permits and inspections",
                date: Date().addingTimeInterval(-15 * 24 * 60 * 60),
                project: project3
            ),
            
            // General expenses
            Expense(
                category: .equipment,
                amount: 350,
                descriptionText: "Power tools",
                date: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                project: nil
            ),
            Expense(
                category: .misc,
                amount: 150,
                descriptionText: "Office supplies",
                date: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                project: nil
            )
        ]
        
        expenses.forEach { context.insert($0) }
        
        // Create sample invoices
        let invoices = [
            // Project 1 invoices
            Invoice(
                amount: 7500,
                dueDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                isPaid: true,
                clientName: "John Smith",
                createdDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                project: project1
            ),
            Invoice(
                amount: 7500,
                dueDate: Date().addingTimeInterval(15 * 24 * 60 * 60),
                isPaid: false,
                clientName: "John Smith",
                createdDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                project: project1
            ),
            
            // Project 2 invoices
            Invoice(
                amount: 4000,
                dueDate: Date().addingTimeInterval(-20 * 24 * 60 * 60),
                isPaid: true,
                clientName: "Jane Doe",
                createdDate: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                project: project2
            ),
            Invoice(
                amount: 4000,
                dueDate: Date().addingTimeInterval(10 * 24 * 60 * 60),
                isPaid: false,
                clientName: "Jane Doe",
                createdDate: Date().addingTimeInterval(-15 * 24 * 60 * 60),
                project: project2
            ),
            
            // Project 3 invoices
            Invoice(
                amount: 12000,
                dueDate: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                isPaid: true,
                clientName: "Bob Johnson",
                createdDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                project: project3
            )
        ]
        
        invoices.forEach { context.insert($0) }
        
        // Create sample clients
        let clients = [
            Client(
                name: "John Smith",
                email: "john.smith@example.com",
                phone: "(555) 123-4567",
                address: "123 Main St, Anytown, USA",
                notes: "Preferred contractor, repeat customer"
            ),
            Client(
                name: "Jane Doe",
                email: "jane.doe@example.com",
                phone: "(555) 987-6543",
                address: "456 Oak Ave, Springfield, USA",
                notes: "Referred by John Smith"
            ),
            Client(
                name: "Bob Johnson",
                email: "bob.j@example.com",
                phone: "(555) 555-5555",
                address: "789 Pine Rd, Metropolis, USA",
                notes: "Large project budget, excellent communication"
            )
        ]
        
        clients.forEach { context.insert($0) }
        
        return container
    }
}

// MARK: - Client Model (if not already defined)

#if DEBUG
@Model
final class Client {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var notes: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.notes = notes
    }
}
#endif
