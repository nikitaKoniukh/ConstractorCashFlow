//
//  ContractorCashFlowTests.swift
//  ContractorCashFlowTests
//
//  Created by Nikita Koniukh on 13/03/2026.
//

import Testing
@testable import ContractorCashFlow

@MainActor
struct ContractorCashFlowTests {

    @Test func settingsTabUsesGearIcon() async throws {
        #expect(AppTab.settings.iconName == "gearshape.fill")
    }

    @Test func settingsTabExistsInMainTabs() async throws {
        #expect(AppTab.allCases.contains(.settings))
    }
}
