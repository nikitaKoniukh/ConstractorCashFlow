//
//  PaywallView.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 16/03/2026.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var selectedProduct: Product? = nil
    @State private var showError = false
    
    /// Optional message describing which limit was reached
    var limitReachedMessage: LocalizedStringKey? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        
                        Text(LocalizationKey.Subscription.upgradeTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let message = limitReachedMessage {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text(LocalizationKey.Subscription.upgradeSubtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 32)
                    
                    // Feature comparison
                    VStack(alignment: .leading, spacing: 16) {
                        PaywallFeatureRow(
                            icon: "folder.fill",
                            title: LocalizationKey.Subscription.unlimitedProjects,
                            freeLimit: "1",
                            proLimit: LocalizationKey.Subscription.unlimited
                        )
                        PaywallFeatureRow(
                            icon: "dollarsign.circle.fill",
                            title: LocalizationKey.Subscription.unlimitedExpenses,
                            freeLimit: "1",
                            proLimit: LocalizationKey.Subscription.unlimited
                        )
                        PaywallFeatureRow(
                            icon: "doc.text.fill",
                            title: LocalizationKey.Subscription.unlimitedInvoices,
                            freeLimit: "1",
                            proLimit: LocalizationKey.Subscription.unlimited
                        )
                        PaywallFeatureRow(
                            icon: "person.3.fill",
                            title: LocalizationKey.Subscription.unlimitedWorkers,
                            freeLimit: "1",
                            proLimit: LocalizationKey.Subscription.unlimited
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Product selection
                    if purchaseManager.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            if let monthly = purchaseManager.monthlyProduct {
                                PaywallProductButton(
                                    product: monthly,
                                    isSelected: selectedProduct?.id == monthly.id,
                                    badge: nil
                                ) {
                                    selectedProduct = monthly
                                }
                            }
                            
                            if let yearly = purchaseManager.yearlyProduct {
                                PaywallProductButton(
                                    product: yearly,
                                    isSelected: selectedProduct?.id == yearly.id,
                                    badge: LocalizationKey.Subscription.saveBadge
                                ) {
                                    selectedProduct = yearly
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Subscribe button
                    Button {
                        Task { await handlePurchase() }
                    } label: {
                        Group {
                            if purchaseManager.isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(LocalizationKey.Subscription.subscribe)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedProduct != nil ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                    .disabled(selectedProduct == nil || purchaseManager.isPurchasing)
                    .padding(.horizontal)
                    
                    // Restore purchases
                    Button {
                        Task { await purchaseManager.restorePurchases() }
                    } label: {
                        Text(LocalizationKey.Subscription.restore)
                            .font(.subheadline)
                    }
                    
                    // Legal links
                    HStack(spacing: 16) {
                        Text(LocalizationKey.Subscription.termsOfService)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(LocalizationKey.Subscription.privacyPolicy)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKey.Action.cancel) {
                        dismiss()
                    }
                }
            }
            .alert(LocalizationKey.General.error, isPresented: $showError) {
                Button(LocalizationKey.General.ok, role: .cancel) { }
            } message: {
                Text(purchaseManager.errorMessage ?? "An unexpected error occurred")
            }
            .onAppear {
                // Pre-select yearly (best value)
                selectedProduct = purchaseManager.yearlyProduct ?? purchaseManager.monthlyProduct
            }
            .onChange(of: purchaseManager.isProUser) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }
    
    private func handlePurchase() async {
        guard let product = selectedProduct else { return }
        do {
            try await purchaseManager.purchase(product)
        } catch {
            showError = true
        }
    }
}

// MARK: - Feature Row

private struct PaywallFeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let freeLimit: String
    let proLimit: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(proLimit)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                Text("Free: \(freeLimit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Product Button

private struct PaywallProductButton: View {
    let product: Product
    let isSelected: Bool
    let badge: LocalizedStringKey?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(4)
                        }
                    }
                    HStack(spacing: 4) {
                        Text(product.displayPrice)
                        Text("/")
                        Text(subscriptionPeriodKey)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var subscriptionPeriodKey: LocalizedStringKey {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .month: return LocalizationKey.Subscription.perMonth
        case .year: return LocalizationKey.Subscription.perYear
        default: return ""
        }
    }
}

#Preview("Paywall") {
    PaywallView()
}

#Preview("Paywall - Limit Reached") {
    PaywallView(limitReachedMessage: LocalizationKey.Subscription.projectLimitReached)
}
