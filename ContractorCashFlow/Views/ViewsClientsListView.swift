//
//  ClientsListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct ClientsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .clients)) {
            ClientsListContent(searchText: searchText)
            .navigationTitle(LocalizationKey.ClientS.title)
            .navigationDestination(for: Client.self) { client in
                ClientDetailView(client: client)
            }
            .searchable(text: $searchText, prompt: "Search by name, email, or phone")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isShowingNewClient = true
                    } label: {
                        Label(LocalizationKey.ClientS.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewClient },
                set: { appState.isShowingNewClient = $0 }
            )) {
                NewClientView()
            }
            .alert("Error", isPresented: Binding(
                get: { appState.isShowingError },
                set: { appState.isShowingError = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appState.errorMessage ?? "An error occurred")
            }
        }
    }
}
