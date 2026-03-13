//
//  Client.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Foundation
import SwiftData

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
