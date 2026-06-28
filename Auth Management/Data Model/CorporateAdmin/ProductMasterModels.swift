import Foundation

public struct Category: Codable, Equatable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var createdAt: Date
    
    public init(id: UUID = UUID(), name: String, description: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
    }
}

public struct AuthenticitySettings: Codable, Equatable, Hashable {
    public var isNFCEnabled: Bool
    public var requiresCertificate: Bool
    public var notes: String?
    
    public init(isNFCEnabled: Bool = false, requiresCertificate: Bool = false, notes: String? = nil) {
        self.isNFCEnabled = isNFCEnabled
        self.requiresCertificate = requiresCertificate
        self.notes = notes
    }
}

public struct ProductMasterRecord: Codable, Equatable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var categoryID: UUID?
    public var sku: String
    public var authenticitySettings: AuthenticitySettings
    public var createdAt: Date
    public var updatedAt: Date
    
    // New fields for premium iOS 26 management screen
    public var brand: String
    public var price: Double
    public var costPrice: Double
    public var tax: Double
    public var barcode: String
    public var isActive: Bool
    public var isArchived: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, categoryID, sku, authenticitySettings, createdAt, updatedAt
        case brand, price, costPrice, tax, barcode, isActive, isArchived
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        categoryID: UUID? = nil,
        sku: String,
        authenticitySettings: AuthenticitySettings = AuthenticitySettings(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        brand: String = "Noir Luxe",
        price: Double = 0.0,
        costPrice: Double = 0.0,
        tax: Double = 18.0,
        barcode: String = "",
        isActive: Bool = true,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.categoryID = categoryID
        self.sku = sku
        self.authenticitySettings = authenticitySettings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.brand = brand
        self.price = price
        self.costPrice = costPrice
        self.tax = tax
        self.barcode = barcode
        self.isActive = isActive
        self.isArchived = isArchived
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
        sku = try container.decode(String.self, forKey: .sku)
        authenticitySettings = try container.decodeIfPresent(AuthenticitySettings.self, forKey: .authenticitySettings) ?? AuthenticitySettings()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? "Noir Luxe"
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        costPrice = try container.decodeIfPresent(Double.self, forKey: .costPrice) ?? 0.0
        tax = try container.decodeIfPresent(Double.self, forKey: .tax) ?? 18.0
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode) ?? ""
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }
}

public enum AuditAction: String, Codable {
    case create = "CREATE"
    case update = "UPDATE"
    case delete = "DELETE"
}

public struct AuditLog: Codable, Identifiable {
    public let id: UUID
    public let tableName: String
    public let recordID: UUID
    public let action: AuditAction
    public let modifiedBy: UUID
    public let modifiedAt: Date
    public let previousValues: String? // JSON string
    public let newValues: String? // JSON string
    
    public init(id: UUID = UUID(), tableName: String, recordID: UUID, action: AuditAction, modifiedBy: UUID, modifiedAt: Date = Date(), previousValues: String? = nil, newValues: String? = nil) {
        self.id = id
        self.tableName = tableName
        self.recordID = recordID
        self.action = action
        self.modifiedBy = modifiedBy
        self.modifiedAt = modifiedAt
        self.previousValues = previousValues
        self.newValues = newValues
    }
}
