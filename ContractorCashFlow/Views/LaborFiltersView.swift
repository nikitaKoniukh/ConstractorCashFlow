//
//  LaborFiltersView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI
import SwiftData

struct LaborFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]
    
    @Binding var selectedType: LaborType?
    @Binding var selectedProject: Project?
    @Binding var selectedMonth: Date?
    
    @State private var monthFilterEnabled: Bool = false
    @State private var monthPickerDate: Date = Date()
    
    private var availableMonths: [Date] {
        let calendar = Calendar.current
        var months: [Date] = []
        let now = Date()
        for i in (0..<12).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                months.append(startOfMonth)
            }
        }
        return months
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizationKey.Labor.laborType)) {
                    Picker(LocalizationKey.Labor.typeLabel, selection: $selectedType) {
                        Text(LocalizationKey.Labor.allTypes).tag(nil as LaborType?)
                        ForEach(LaborType.allCases, id: \.self) { type in
                            Text(type.localizedDisplayName).tag(type as LaborType?)
                        }
                    }
                }
                
                Section(header: Text(LocalizationKey.Labor.filterByProject)) {
                    Picker(LocalizationKey.Labor.projectLabel, selection: $selectedProject) {
                        Text(LocalizationKey.Labor.allProjects).tag(nil as Project?)
                        ForEach(projects) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                }
                
                Section(header: Text(LocalizationKey.Labor.filterByMonth)) {
                    Toggle(LocalizationKey.Labor.filterByMonthToggle, isOn: $monthFilterEnabled)
                        .onChange(of: monthFilterEnabled) { _, enabled in
                            selectedMonth = enabled ? monthPickerDate : nil
                        }
                    
                    if monthFilterEnabled {
                        Picker(LocalizationKey.Labor.selectMonth, selection: $monthPickerDate) {
                            ForEach(availableMonths, id: \.self) { month in
                                Text(month.formatted(.dateTime.month(.wide).year()))
                                    .tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .onChange(of: monthPickerDate) { _, newMonth in
                            selectedMonth = newMonth
                        }
                    }
                }
                
                Section {
                    Button(LocalizationKey.Labor.clearFilters) {
                        selectedType = nil
                        selectedProject = nil
                        selectedMonth = nil
                        monthFilterEnabled = false
                        monthPickerDate = Date()
                        dismiss()
                    }
                }
            }
            .navigationTitle(LocalizationKey.Labor.filters)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKey.General.done) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let month = selectedMonth {
                    monthFilterEnabled = true
                    monthPickerDate = month
                }
            }
        }
    }
}

#Preview {
    LaborListView()
        .environment(AppState())
        .modelContainer(for: [LaborDetails.self, Project.self, Expense.self], inMemory: true)
}
