//
//  Planogram.swift
//  Noir Luxe — RSMS
//
//  ┌──────────────────────────────────────────────┐
//  │  OWNER: Corporate Admin Team                 │
//  │  DOMAIN: Product & Merchandising — Visual    │
//  │  USER STORIES: CA-06, BM Compliance          │
//  └──────────────────────────────────────────────┘
//
//  WHO USES THIS MODEL:
//  • Corporate Admin — creates planograms and publishes to stores
//  • Boutique Manager — receives planograms and submits compliance proof
//
//  WHAT THIS MODEL DOES:
//  A planogram is a visual merchandising directive — it tells a store
//  how to arrange products on shelves, in windows, on mannequins, etc.
//  Corporate Admin publishes it; Boutique Manager executes it in-store
//  and submits photos via ComplianceReport (in BoutiqueManager folder).
//
//  WORKFLOW:
//  1. Corporate Admin creates planogram → status = .draft
//  2. Corporate Admin publishes → status = .published
//  3. Boutique Manager receives it → status = .pendingCompliance
//  4. Boutique Manager submits ComplianceReport with photos
//  5. Corporate Admin reviews → status = .compliant or .rejected
//

import Foundation

// MARK: - Planogram

struct Planogram: Identifiable, Codable, Hashable {

    let id: UUID
    var title: String          // e.g. "Monsoon Window Display V2"
    var version: String        // e.g. "2.0"
    var storeID: UUID          // which store this is for
    var createdBy: UUID        // Corporate Admin User.id
    var status: PlanogramStatus
    var documentURL: String?   // link to the planogram PDF/image
    var feedback: String?      // reviewer notes after compliance check

    init(
        id: UUID = UUID(),
        title: String,
        version: String = "1.0",
        storeID: UUID,
        createdBy: UUID,
        status: PlanogramStatus = .draft,
        documentURL: String? = nil,
        feedback: String? = nil
    ) {
        self.id = id
        self.title = title
        self.version = version
        self.storeID = storeID
        self.createdBy = createdBy
        self.status = status
        self.documentURL = documentURL
        self.feedback = feedback
    }
}

// MARK: - PlanogramStatus

enum PlanogramStatus: String, Codable, CaseIterable, Hashable {
    case draft             = "Draft"
    case published         = "Published"
    case pendingCompliance = "Pending Compliance"
    case compliant         = "Compliant"
    case rejected          = "Rejected"
}
