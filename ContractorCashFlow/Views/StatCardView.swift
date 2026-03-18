//
//  StatCardView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 18/03/2026.
//


import SwiftUI

struct StatCardView: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}
