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
    
    @State private var selectedDates: Set<DateComponents> = []
    
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
                    MultiDatePicker("Select Days", selection: $selectedDates)
                        .padding(.vertical, 4)
                        .onChange(of: selectedDates) { _, newValue in
                            fillContiguousRange(from: newValue)
                        }

                    if !selectedDates.isEmpty {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text("\(selectedDates.count) day\(selectedDates.count == 1 ? "" : "s") selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let start = resolvedStartDate, let end = resolvedEndDate {
                                if Calendar.current.isDate(start, inSameDayAs: end) {
                                    Text(start, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("\(start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
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
                // Restore selected dates from existing start/end range
                if let start = startDate, let end = endDate {
                    var dates: Set<DateComponents> = []
                    var current = start
                    while current <= end {
                        dates.insert(Calendar.current.dateComponents([.year, .month, .day], from: current))
                        current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
                    }
                    selectedDates = dates
                } else if let start = startDate {
                    selectedDates = [Calendar.current.dateComponents([.year, .month, .day], from: start)]
                }
            }
        }
    }
    
    // Fill all days between min and max to keep selection contiguous
    private func fillContiguousRange(from dates: Set<DateComponents>) {
        let resolved = dates.compactMap { Calendar.current.date(from: $0) }
        guard let min = resolved.min(), let max = resolved.max(), min < max else { return }
        var filled: Set<DateComponents> = []
        var current = min
        while current <= max {
            filled.insert(Calendar.current.dateComponents([.year, .month, .day], from: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        if filled != selectedDates {
            selectedDates = filled
        }
    }

    // Earliest selected date
    private var resolvedStartDate: Date? {
        selectedDates
            .compactMap { Calendar.current.date(from: $0) }
            .min()
    }
    
    // Latest selected date (end of day)
    private var resolvedEndDate: Date? {
        selectedDates
            .compactMap { Calendar.current.date(from: $0) }
            .max()
            .map { Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: $0)! }
    }
    
    private func applyFilters() {
        if !selectedDates.isEmpty {
            startDate = resolvedStartDate
            endDate = resolvedEndDate
        } else {
            startDate = nil
            endDate = nil
        }
    }
    
    private func clearFilters() {
        selectedCategory = nil
        startDate = nil
        endDate = nil
        selectedDates = []
        dismiss()
    }
}
