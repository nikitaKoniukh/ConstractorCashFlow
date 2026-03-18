//
//  LaborListView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 14/03/2026.
//

import SwiftUI
import SwiftData

struct LaborListView: View {
    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var allWorkersForCount: [LaborDetails]
    
    @State private var searchText: String = ""
    @State private var isShowingPaywall = false
    @State private var selectedType: LaborType?
    @State private var selectedProject: Project?
    @State private var selectedMonth: Date?
    @State private var isShowingFilters = false
    @State private var sortOrder: SortOrder = .recentlyAdded
    
    enum SortOrder: CaseIterable {
        case recentlyAdded
        case workerName
        case totalEarnedHigh
        case totalEarnedLow
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .recentlyAdded:
                return LocalizationKey.Labor.sortRecentlyAdded
            case .workerName:
                return LocalizationKey.Labor.sortWorkerName
            case .totalEarnedHigh:
                return LocalizationKey.Labor.sortAmountHighToLow
            case .totalEarnedLow:
                return LocalizationKey.Labor.sortAmountLowToHigh
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: appState.navigationPath(for: .labor)) {
            LaborListContentView(
                searchText: searchText,
                selectedType: selectedType,
                selectedProject: selectedProject,
                selectedMonth: selectedMonth,
                sortOrder: sortOrder
            )
            .navigationTitle(LocalizationKey.Labor.title)
            .searchable(text: $searchText, prompt: LocalizationKey.Labor.searchPrompt)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingFilters.toggle()
                    } label: {
                        Label(LocalizationKey.Labor.filtersButton, systemImage: (selectedType != nil || selectedProject != nil || selectedMonth != nil) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker(LocalizationKey.Labor.sortBy, selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.titleKey).tag(order)
                            }
                        }
                    } label: {
                        Label(LocalizationKey.Labor.sortButton, systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if purchaseManager.canCreateWorker(currentCount: allWorkersForCount.count) {
                            appState.isShowingNewLabor = true
                        } else {
                            isShowingPaywall = true
                        }
                    } label: {
                        Label(LocalizationKey.Labor.add, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.isShowingNewLabor },
                set: { appState.isShowingNewLabor = $0 }
            )) {
                AddLaborView()
            }
            .sheet(isPresented: $isShowingFilters) {
                LaborFiltersView(
                    selectedType: $selectedType,
                    selectedProject: $selectedProject,
                    selectedMonth: $selectedMonth
                )
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(limitReachedMessage: LocalizationKey.Subscription.workerLimitReached)
            }
            .alert(LocalizationKey.General.error, isPresented: Binding(
                get: { appState.isShowingError },
                set: { appState.isShowingError = $0 }
            )) {
                Button(LocalizationKey.General.ok, role: .cancel) { }
            } message: {
                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                } else {
                    Text(LocalizationKey.General.genericError)
                }
            }
        }
    }
}
