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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let searchText: String

    init(searchText: String) {
        self.searchText = searchText

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

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if isIPad {
                iPadGrid
            } else {
                iPhoneList
            }
        }
        .overlay {
            if clients.isEmpty {
                if searchText.isEmpty {
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

    // MARK: iPhone – plain list
    private var iPhoneList: some View {
        List {
            ForEach(clients) { client in
                NavigationLink(value: client) {
                    ClientRow(client: client)
                }
            }
            .onDelete(perform: deleteClients)
        }
    }

    // MARK: iPad – card grid
    private var iPadGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 300, maximum: 420), spacing: 16)],
                spacing: 16
            ) {
                ForEach(clients) { client in
                    NavigationLink(value: client) {
                        ClientCardView(client: client)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteClient(client)
                        } label: {
                            Label(LocalizationKey.General.delete, systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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

    private func deleteClient(_ client: Client) {
        do {
            modelContext.delete(client)
            try modelContext.save()
        } catch {
            appState.showError("Failed to delete client: \(error.localizedDescription)")
        }
    }
}
// MARK: - iPad Client Card
private struct ClientCardView: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Avatar circle with initials
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(client.name.initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(client.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let email = client.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()

            // Contact details footer (only when present)
            let hasPhone = client.phone != nil
            let hasAddress = client.address != nil
            if hasPhone || hasAddress {
                Divider()
                HStack(spacing: 16) {
                    if let phone = client.phone {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let address = client.address {
                        Label(address, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - String initials helper
private extension String {
    var initials: String {
        let words = split(separator: " ").prefix(2)
        return words.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

