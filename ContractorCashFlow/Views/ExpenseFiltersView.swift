//
//  ExpenseFiltersView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//

import SwiftUI

struct ExpenseFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    @State private var isUsingStartDate = false
    @State private var isUsingEndDate = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Filter by Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as ExpenseCategory?)
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category as ExpenseCategory?)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section("Date Range") {
                    Toggle("Start Date", isOn: $isUsingStartDate)
                    if isUsingStartDate {
                        DatePicker("From", selection: $tempStartDate, displayedComponents: .date)
                    }
                    
                    Toggle("End Date", isOn: $isUsingEndDate)
                    if isUsingEndDate {
                        DatePicker("To", selection: $tempEndDate, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        clearFilters()
                    }
                }
            }
            .navigationTitle("Filter Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
            .onAppear {
                isUsingStartDate = startDate != nil
                isUsingEndDate = endDate != nil
                if let start = startDate {
                    tempStartDate = start
                }
                if let end = endDate {
                    tempEndDate = end
                }
            }
        }
    }
    
    private func applyFilters() {
        startDate = isUsingStartDate ? tempStartDate : nil
        endDate = isUsingEndDate ? tempEndDate : nil
    }
    
    private func clearFilters() {
        selectedCategory = nil
        startDate = nil
        endDate = nil
        isUsingStartDate = false
        isUsingEndDate = false
        dismiss()
    }
}
