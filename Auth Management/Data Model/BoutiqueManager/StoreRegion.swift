//
//  StoreRegion.swift
//  Noir Luxe — RSMS
//
//  ┌──────────────────────────────────────────────┐
//  │  OWNER: Boutique Manager Team                │
//  │  DOMAIN: Core Organization — Store Region    │
//  │  USER STORIES: All roles                     │
//  └──────────────────────────────────────────────┘
//
//  WHO USES THIS MODEL:
//  • Boutique Manager — determines region-specific compliance rules and tax formats
//  • Corporate Admin — oversees global boutique deployment, assigning stores to correct regions
//  • Sales Associate — handles customer purchases according to region-defined rules
//
//  WHAT THIS MODEL DOES:
//  An enum representing the international regions where Noir Luxe boutiques operate.
//  Provides standard defaults for currency and taxation when a store is first initialized.
//

import Foundation

/// Multinational regions where Noir Luxe stores operate.
enum StoreRegion: String, Codable, CaseIterable, Hashable {
    case india = "India"
    case unitedStates = "United States"
    case unitedKingdom = "United Kingdom"
    case europe = "Europe"
    case uae = "UAE"
    case japan = "Japan"
    case other = "Other"

    /// Default operational currency when setting up a store in this region
    var defaultCurrency: Currency {
        switch self {
        case .india: return .inr
        case .unitedStates: return .usd
        case .unitedKingdom: return .gbp
        case .europe: return .eur
        case .uae: return .aed
        case .japan: return .jpy
        case .other: return .eur
        }
    }

    /// Default taxation profile when setting up a store in this region
    var defaultTaxConfig: RegionalTaxConfig {
        switch self {
        case .india:
            return RegionalTaxConfig(taxType: .gst, taxName: "GST", taxRate: 0.18) // 18% standard luxury GST
        case .unitedStates:
            return RegionalTaxConfig(taxType: .salesTax, taxName: "Sales Tax", taxRate: 0.08875) // NY Sales Tax (8.875%)
        case .unitedKingdom:
            return RegionalTaxConfig(taxType: .vat, taxName: "VAT", taxRate: 0.20) // 20% VAT
        case .europe:
            return RegionalTaxConfig(taxType: .vat, taxName: "VAT", taxRate: 0.20) // 20% European VAT
        case .uae:
            return RegionalTaxConfig(taxType: .vat, taxName: "VAT", taxRate: 0.05) // 5% VAT in UAE
        case .japan:
            return RegionalTaxConfig(taxType: .consumptionTax, taxName: "Consumption Tax", taxRate: 0.10) // 10% Japanese tax
        case .other:
            return RegionalTaxConfig(taxType: .none, taxName: "Tax", taxRate: 0.0)
        }
    }

    /// Regulatory privacy and compliance framework governing data in this region
    var privacyRegulation: String {
        switch self {
        case .india: return "DPDPA 2023"
        case .unitedStates: return "CCPA"
        case .unitedKingdom: return "UK GDPR"
        case .europe: return "EU GDPR"
        case .uae: return "PDPL"
        case .japan: return "APPI"
        case .other: return "Standard Privacy Policy"
        }
    }
}
