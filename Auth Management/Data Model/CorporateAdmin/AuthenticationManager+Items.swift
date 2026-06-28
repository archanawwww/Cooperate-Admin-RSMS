import Foundation
import Combine
extension AuthenticationManager {
    
    // MARK: - Corporate Admin Items (Mock Data)
    
    // We store these mock records in UserDefaults for persistence
    private var categoriesKey: String { "auth-management.categories" }
    private var productMasterKey: String { "auth-management.product-master" }
    private var auditLogsKey: String { "auth-management.audit-logs" }
    
    public var itemCategories: [Category] {
        get {
            guard let data = UserDefaults.standard.data(forKey: categoriesKey),
                  let decoded = try? JSONDecoder().decode([Category].self, from: data), !decoded.isEmpty else {
                return MockDataStore.categories
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: categoriesKey)
            }
        }
    }
    
    public var productMasterRecords: [ProductMasterRecord] {
        get {
            guard let data = UserDefaults.standard.data(forKey: productMasterKey),
                  let decoded = try? JSONDecoder().decode([ProductMasterRecord].self, from: data), !decoded.isEmpty else {
                return MockDataStore.productMasterRecords
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: productMasterKey)
            }
        }
    }
    
    public var productAuditLogs: [AuditLog] {
        get {
            guard let data = UserDefaults.standard.data(forKey: auditLogsKey),
                  let decoded = try? JSONDecoder().decode([AuditLog].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: auditLogsKey)
            }
        }
    }
    
    // MARK: - Corporate Admin Item Methods
    
    public func addCategory(name: String, description: String?) {
        let newCat = Category(name: name, description: description)
        var cats = itemCategories
        cats.append(newCat)
        itemCategories = cats
        objectWillChange.send()
    }
    
    public func addProductMasterRecord(_ record: ProductMasterRecord) {
        var records = productMasterRecords
        records.append(record)
        productMasterRecords = records
        logAuditAction(action: .create, tableName: "ProductMasterRecord", recordID: record.id, previousValues: nil, newValues: encodeToString(record))
        objectWillChange.send()
    }
    
    public func updateProductMasterRecord(_ record: ProductMasterRecord) {
        var records = productMasterRecords
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            let oldRecord = records[index]
            records[index] = record
            productMasterRecords = records
            logAuditAction(action: .update, tableName: "ProductMasterRecord", recordID: record.id, previousValues: encodeToString(oldRecord), newValues: encodeToString(record))
            objectWillChange.send()
        }
    }
    
    public func deleteProductMasterRecord(id: UUID) {
        var records = productMasterRecords
        if let index = records.firstIndex(where: { $0.id == id }) {
            let oldRecord = records[index]
            records.remove(at: index)
            productMasterRecords = records
            logAuditAction(action: .delete, tableName: "ProductMasterRecord", recordID: id, previousValues: encodeToString(oldRecord), newValues: nil)
            objectWillChange.send()
        }
    }
    
    private func logAuditAction(action: AuditAction, tableName: String, recordID: UUID, previousValues: String?, newValues: String?) {
        guard let currentUser = currentUser else { return }
        let log = AuditLog(tableName: tableName, recordID: recordID, action: action, modifiedBy: currentUser.id, previousValues: previousValues, newValues: newValues)
        var logs = productAuditLogs
        logs.insert(log, at: 0)
        productAuditLogs = logs
    }
    
    private func encodeToString<T: Encodable>(_ object: T) -> String? {
        guard let data = try? JSONEncoder().encode(object) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
