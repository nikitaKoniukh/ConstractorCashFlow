//
//  ServicesPurchaseManager.swift
//  ContractorCashFlow
//
//  Created by Nikita Koniukh on 16/03/2026.
//

import SwiftUI
import StoreKit

/// Product identifiers matching App Store Connect configuration
enum SubscriptionProduct {
    static let monthlyID = "com.yetzira.ContractorCashFlow.pro.monthly"
    static let yearlyID = "com.yetzira.ContractorCashFlow.pro.yearly"
    static let allIDs: Set<String> = [monthlyID, yearlyID]
}

/// Free tier limits — 1 of each entity type
enum FreeTierLimit {
    static let maxProjects = 1
    static let maxExpenses = 1
    static let maxInvoices = 1
    static let maxWorkers = 1
}

/// Manages StoreKit 2 auto-renewable subscriptions
@Observable
@MainActor
final class PurchaseManager {
    
    // MARK: - Singleton
    
    static let shared = PurchaseManager()
    
    // MARK: - State
    
    /// Whether the user has an active Pro subscription
    var isProUser: Bool = false
    
    /// Available subscription products from the App Store
    var products: [Product] = []
    
    /// Currently active subscription transaction
    var activeSubscription: StoreKit.Transaction? = nil
    
    /// Whether products are loading
    var isLoading: Bool = false
    
    /// Error message from the last failed operation
    var errorMessage: String? = nil
    
    /// Whether a purchase is in progress
    var isPurchasing: Bool = false
    
    // MARK: - Private
    
    private var transactionListener: Task<Void, Error>? = nil
    
    // MARK: - Init
    
    private init() {
        transactionListener = listenForTransactions()
        Task { @MainActor in
            await checkCurrentEntitlements()
            await loadProducts()
        }
    }
    
    // Note: transactionListener is cancelled when the singleton is deallocated (app termination)
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let storeProducts = try await Product.products(for: SubscriptionProduct.allIDs)
            // Sort: monthly first, yearly second
            products = storeProducts.sorted { p1, _ in
                p1.id == SubscriptionProduct.monthlyID
            }
        } catch {
            errorMessage = String(format: LocalizationKey.General.failedToLoadProducts, error.localizedDescription)
            print("StoreKit: Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        defer { isPurchasing = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkCurrentEntitlements()
            
        case .userCancelled:
            break
            
        case .pending:
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            errorMessage = String(format: LocalizationKey.General.failedToRestorePurchases, error.localizedDescription)
            print("StoreKit: Failed to restore: \(error)")
        }
    }
    
    // MARK: - Entitlement Checking
    
    func checkCurrentEntitlements() async {
        var foundActive = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if SubscriptionProduct.allIDs.contains(transaction.productID),
                   transaction.revocationDate == nil {
                    foundActive = true
                    activeSubscription = transaction
                }
            } catch {
                print("StoreKit: Failed to verify transaction: \(error)")
            }
        }
        
        isProUser = foundActive
        if !foundActive {
            activeSubscription = nil
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.checkCurrentEntitlements()
                } catch {
                    print("StoreKit: Transaction update failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Limit Checking
    
    func canCreateProject(currentCount: Int) -> Bool {
        isProUser || currentCount < FreeTierLimit.maxProjects
    }
    
    func canCreateExpense(currentCount: Int) -> Bool {
        isProUser || currentCount < FreeTierLimit.maxExpenses
    }
    
    func canCreateInvoice(currentCount: Int) -> Bool {
        isProUser || currentCount < FreeTierLimit.maxInvoices
    }
    
    func canCreateWorker(currentCount: Int) -> Bool {
        isProUser || currentCount < FreeTierLimit.maxWorkers
    }
    
    // MARK: - Product Helpers
    
    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.monthlyID }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.yearlyID }
    }
    
    var subscriptionStatusText: LocalizedStringKey {
        if isProUser {
            if let transaction = activeSubscription {
                if transaction.productID == SubscriptionProduct.monthlyID {
                    return LocalizationKey.Subscription.proMonthly
                } else {
                    return LocalizationKey.Subscription.proYearly
                }
            }
            return LocalizationKey.Subscription.proPlan
        }
        return LocalizationKey.Subscription.freePlan
    }
    
    var expirationDate: Date? {
        activeSubscription?.expirationDate
    }
}
