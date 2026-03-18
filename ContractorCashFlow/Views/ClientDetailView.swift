//
//  ClientDetailView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct ClientDetailView: View {
    @Bindable var client: Client
    @State private var isEditing = false
    
    var body: some View {
        List {
            Section(LocalizationKey.ClientS.information) {
                LabeledContent(LocalizationKey.ClientS.name, value: client.name)
                
                if let email = client.email {
                    LabeledContent(LocalizationKey.ClientS.email, value: email)
                }
                
                if let phone = client.phone {
                    LabeledContent(LocalizationKey.ClientS.phone, value: phone)
                }
                
                if let address = client.address {
                    LabeledContent(LocalizationKey.ClientS.address) {
                        Text(address)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            
            if let notes = client.notes, !notes.isEmpty {
                Section(LocalizationKey.ClientS.notes) {
                    Text(notes)
                }
            }
        }
        .navigationTitle(client.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Text(LocalizationKey.Action.edit)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditClientView(client: client)
        }
    }
}
