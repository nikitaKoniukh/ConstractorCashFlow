//
//  ClientsListContent.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct ClientsListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        
        // Build predicate based on search text
        let predicate: Predicate<Client>
        if searchText.isEmpty {
            predicate = #Predicate<Client> { _ in true }
        } else {
            predicate = #Predicate<Client> { client in
                client.name.localizedStandardContains(searchText) ||
                (client.email != nil && client.email!.localizedStandardContains(searchText)) ||
                (client.phone != nil && client.phone!.localizedStandardContains(searchText))
            }
        }
        
        _clients = Query(filter: predicate, sort: \Client.name)
    }
    
    @Query private var clients: [Client]
    
    var body: some View {
        List {
            ForEach(clients) { client in
                NavigationLink(value: client) {
                    ClientRow(client: client)
                }
            }
            .onDelete(perform: deleteClients)
        }
        .overlay {
            if clients.isEmpty {
                if searchText.isEmpty {
                    // Enhanced empty state with CTA button
                    ContentUnavailableView {
                        Label("No Clients", systemImage: "person.2")
                    } description: {
                        Text("Add your first client to manage contacts and projects")
                    } actions: {
                        Button {
                            appState.isShowingNewClient = true
                        } label: {
                            Text("Add Client")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                do {
                    modelContext.delete(clients[index])
                    try modelContext.save()
                } catch {
                    appState.showError("Failed to delete client: \(error.localizedDescription)")
                }
            }
        }
    }
}
