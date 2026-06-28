import Foundation

/// Centralized mock data store — all seed data lives here,
/// separated from the view and business-logic layers.
public struct MockDataStore {

    // MARK: - Stable IDs (so categories ↔ products stay linked across launches)

    private static let handbagsCatID  = UUID(uuidString: "A1B2C3D4-1111-2222-3333-444455556666")!
    private static let watchesCatID   = UUID(uuidString: "A1B2C3D4-1111-2222-3333-444455557777")!
    private static let fragrancesCatID = UUID(uuidString: "A1B2C3D4-1111-2222-3333-444455558888")!
    private static let footwearCatID  = UUID(uuidString: "A1B2C3D4-1111-2222-3333-444455559999")!

    // MARK: - Categories

    public static var categories: [Category] {
        [
            Category(id: handbagsCatID,   name: "Handbags",   description: "Luxury leather goods & clutches"),
            Category(id: watchesCatID,    name: "Watches",    description: "Premium timepieces & chronographs"),
            Category(id: fragrancesCatID, name: "Fragrances", description: "Designer perfumes & colognes"),
            Category(id: footwearCatID,   name: "Footwear",   description: "High-end shoes & boots")
        ]
    }

    // MARK: - Product Master Records

    public static var productMasterRecords: [ProductMasterRecord] {
        [
            // ── Handbags ────────────────────────────────────────────
            ProductMasterRecord(
                name: "Classic Flap Bag",
                description: "Quilted lambskin leather with gold-tone hardware",
                categoryID: handbagsCatID,
                sku: "HB-CLFLP-001",
                authenticitySettings: AuthenticitySettings(
                    isNFCEnabled: true,
                    requiresCertificate: true,
                    notes: "NFC chip embedded in inner flap; certificate of authenticity included"
                ),
                brand: "Chanel",
                price: 820000.0,
                costPrice: 540000.0,
                tax: 18.0,
                barcode: "313132009841",
                isActive: true
            ),
            ProductMasterRecord(
                name: "Tote Shopper",
                description: "Full-grain calfskin, reversible interior",
                categoryID: handbagsCatID,
                sku: "HB-TTSHR-002",
                authenticitySettings: AuthenticitySettings(
                    isNFCEnabled: true,
                    requiresCertificate: false,
                    notes: "NFC tag on base; no paper certificate"
                ),
                brand: "Hermès",
                price: 340000.0,
                costPrice: 220000.0,
                tax: 18.0,
                barcode: "313132009842",
                isActive: true
            ),

            // ── Watches ─────────────────────────────────────────────
            ProductMasterRecord(
                name: "Chronograph Elite",
                description: "Swiss automatic movement, sapphire crystal",
                categoryID: watchesCatID,
                sku: "WT-CHELT-001",
                authenticitySettings: AuthenticitySettings(
                    isNFCEnabled: true,
                    requiresCertificate: true,
                    notes: "NFC in case-back; COSC certificate required"
                ),
                brand: "Rolex",
                price: 1250000.0,
                costPrice: 850000.0,
                tax: 18.0,
                barcode: "404142009901",
                isActive: true
            ),
            ProductMasterRecord(
                name: "Dress Watch Slim",
                description: "Ultra-thin rose-gold case, alligator strap",
                categoryID: watchesCatID,
                sku: "WT-DRSLM-002",
                authenticitySettings: AuthenticitySettings(
                    isNFCEnabled: false,
                    requiresCertificate: true,
                    notes: "No NFC; paper certificate with serial match"
                ),
                brand: "Patek Philippe",
                price: 2850000.0,
                costPrice: 1950000.0,
                tax: 18.0,
                barcode: "404142009902",
                isActive: true
            ),

            // ── Fragrances ──────────────────────────────────────────
            ProductMasterRecord(
                name: "Oud Royale EDP",
                description: "100 ml Eau de Parfum, Middle-Eastern oud blend",
                categoryID: fragrancesCatID,
                sku: "FR-OUDRYL-001",
                authenticitySettings: AuthenticitySettings(
                    isNFCEnabled: false,
                    requiresCertificate: false,
                    notes: "Batch code verification via QR"
                ),
                brand: "Creed",
                price: 28500.0,
                costPrice: 18000.0,
                tax: 18.0,
                barcode: "505152003301",
                isActive: true
            ),

            // ── Footwear ────────────────────────────────────────────
            ProductMasterRecord(
                name: "Oxford Brogue",
                description: "Hand-stitched Italian leather, Goodyear welted",
                categoryID: footwearCatID,
                sku: "FW-OXBRG-001",
                authenticitySettings: AuthenticitySettings(
                    isNFCEnabled: true,
                    requiresCertificate: false,
                    notes: "NFC tag inside tongue; sole stamp verification"
                ),
                brand: "John Lobb",
                price: 110000.0,
                costPrice: 70000.0,
                tax: 18.0,
                barcode: "606162007701",
                isActive: true
            ),
            ProductMasterRecord(
                name: "Chelsea Boot",
                description: "Suede upper, Blake-stitched sole",
                categoryID: footwearCatID,
                sku: "FW-CHBOO-002",
                authenticitySettings: AuthenticitySettings(
                    isNFCEnabled: false,
                    requiresCertificate: true,
                    notes: "Certificate with hologram sticker"
                ),
                brand: "Saint Laurent",
                price: 85000.0,
                costPrice: 55000.0,
                tax: 18.0,
                barcode: "606162007702",
                isActive: false
            )
        ]
    }
}
