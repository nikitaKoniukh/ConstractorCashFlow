//
//  ClientRow.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct ClientRow: View {
    let client: Client
    
    private var hasContactInfo: Bool {
        client.email != nil || client.phone != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name
            HStack(alignment: .center) {
                Text(client.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
            }
            
            // Contact info
            if hasContactInfo {
                HStack(spacing: 16) {
                    if let email = client.email {
                        Label {
                            Text(email)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                if let phone = client.phone {
                    Label {
                        Text(phone)
                    } icon: {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
