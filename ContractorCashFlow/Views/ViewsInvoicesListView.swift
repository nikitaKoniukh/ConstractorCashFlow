//
//  InvoicesListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import SwiftUI
import SwiftData

struct InvoicesListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var allInvoicesForCount: [Invoice]
    
    @State private var searchText: String = ""
    @State private var selectedStatusFilter: InvoiceStatusFilter = .all
    @State private var isShowingPaywall = false
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .invoices)) {
            InvoicesListContent(
                searchText: searchText,
                statusFilter: selectedStatusFilter
            )
            .navigationTitle(LocalizationKey.Invoice.title)
            .searchable(text: $searchText, prompt: "Search invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter", selection: $selectedStatusFilter) {
                            ForEach(InvoiceStatusFilter.allCases, id: \.self) { filter in
                                Label(filter.displayName, systemImage: filter.iconName)
                                    .tag(filter)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: selectedStatusFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if purchaseManager.canCreateInvoice(currentCount: allInvoicesForCount.count) {
                            appState.isShowingNewInvoice = true
                        } else {
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Invoice.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewInvoice },
                set: { appState.isShowingNewInvoice = $0 }
            )) {
                NewInvoiceView()
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(limitReachedMessage: LocalizationKey.Subscription.invoiceLimitReached)
            }
        }
    }
}
