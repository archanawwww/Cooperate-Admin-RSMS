import Foundation
import Supabase

struct SupabaseUserProfile: Codable {

    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let phoneNumber: String?
    let userRole: String
    let assignedStoreID: UUID?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "First Name"
        case lastName = "Last Name"
        case email = "Email"
        case phoneNumber = "Phone Number"
        case userRole = "User Role"
        case assignedStoreID = "Assigned StoreID"
        case isActive
    }
}

struct SupabaseStore: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let location: String?
    let region: String
    let managerID: UUID?
    let inventoryControllerID: UUID?
    let salesAssociateIDs: [UUID]?
    let currency: String
    let taxType: String
    let taxName: String
    let taxRate: Double
}

struct SupabaseCategory: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String?
}

struct SupabaseCompanyPolicy: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let content: String
    let lastUpdated: Date
}

struct SupabasePricing: Codable, Identifiable, Hashable {
    let id: UUID
    let productID: UUID
    let costPrice: Double
    let basePrice: Double
    let tax: Double
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case productID = "productID"
        case costPrice = "costPrice"
        case basePrice = "basePrice"
        case tax
        case isActive = "isActive"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

final class SupabaseAuthService {

    static let shared = SupabaseAuthService()

    private init() {}

    struct MemberActionRequest: Encodable {
        let action: String
        let email: String?
        let password: String?
        let userProfile: SupabaseUserProfile?
        let targetUserId: UUID?
    }

    struct EdgeFunctionResponse: Decodable {
        struct AuthUser: Decodable {
            let id: UUID
        }
        let user: AuthUser?
    }

    /// Creates a new user securely without logging the current admin out
    func createMember(userProfile: SupabaseUserProfile, password: String) async throws {
        let request = MemberActionRequest(action: "create", email: userProfile.email, password: password, userProfile: userProfile, targetUserId: nil)

        do {
            let _: EdgeFunctionResponse = try await SupabaseManager.shared.client.functions.invoke(
                "manage-member",
                options: FunctionInvokeOptions(body: request)
            )
        } catch let FunctionsError.httpError(code, data) {
            let errorString = String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            print("Edge Function Error (\(code)): \(errorString)")
            throw FunctionsError.httpError(code: code, data: data)
        }
    }

    /// Updates an existing user securely
    func updateMember(userProfile: SupabaseUserProfile, password: String?) async throws {
        let request = MemberActionRequest(action: "update", email: userProfile.email, password: password, userProfile: userProfile, targetUserId: userProfile.id)

        do {
            let _: EdgeFunctionResponse = try await SupabaseManager.shared.client.functions.invoke(
                "manage-member",
                options: FunctionInvokeOptions(body: request)
            )
        } catch let FunctionsError.httpError(code, data) {
            let errorString = String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            print("Edge Function Error (\(code)): \(errorString)")
            throw FunctionsError.httpError(code: code, data: data)
        }
    }

    func deleteMember(id: UUID) async throws {
        let request = MemberActionRequest(action: "delete", email: nil, password: nil, userProfile: nil, targetUserId: id)

        do {
            let _: EdgeFunctionResponse = try await SupabaseManager.shared.client.functions.invoke(
                "manage-member",
                options: FunctionInvokeOptions(body: request)
            )
        } catch let FunctionsError.httpError(code, data) {
            let errorString = String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            print("Edge Function Error (\(code)): \(errorString)")
            throw FunctionsError.httpError(code: code, data: data)
        }
    }

    func fetchUsers() async throws -> [SupabaseUserProfile] {
        try await SupabaseManager.shared.client
            .from("User")
            .select()
            .execute()
            .value
    }

    func fetchStores() async throws -> [SupabaseStore] {
        try await SupabaseManager.shared.client
            .from("Store")
            .select()
            .execute()
            .value
    }

    func createStore(_ store: SupabaseStore) async throws {
        try await SupabaseManager.shared.client
            .from("Store")
            .insert(store)
            .execute()
    }

    func updateStore(_ store: SupabaseStore) async throws {
        try await SupabaseManager.shared.client
            .from("Store")
            .update(store)
            .eq("id", value: store.id.uuidString)
            .execute()
    }

    func deleteStore(id: UUID) async throws {
        try await SupabaseManager.shared.client
            .from("Store")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchCategories() async throws -> [SupabaseCategory] {
        try await SupabaseManager.shared.client
            .from("Category")
            .select()
            .execute()
            .value
    }

    func createCategory(_ category: SupabaseCategory) async throws {
        try await SupabaseManager.shared.client
            .from("Category")
            .insert(category)
            .execute()
    }

    func updateCategory(_ category: SupabaseCategory) async throws {
        try await SupabaseManager.shared.client
            .from("Category")
            .update(category)
            .eq("id", value: category.id.uuidString)
            .execute()
    }

    func deleteCategory(id: UUID) async throws {
        try await SupabaseManager.shared.client
            .from("Category")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchCompanyPolicies() async throws -> [SupabaseCompanyPolicy] {
        try await SupabaseManager.shared.client
            .from("CompanyPolicy")
            .select()
            .execute()
            .value
    }

    func createCompanyPolicy(_ policy: SupabaseCompanyPolicy) async throws {
        try await SupabaseManager.shared.client
            .from("CompanyPolicy")
            .insert(policy)
            .execute()
    }

    func updateCompanyPolicy(_ policy: SupabaseCompanyPolicy) async throws {
        try await SupabaseManager.shared.client
            .from("CompanyPolicy")
            .update(policy)
            .eq("id", value: policy.id.uuidString)
            .execute()
    }

    func deleteCompanyPolicy(id: UUID) async throws {
        try await SupabaseManager.shared.client
            .from("CompanyPolicy")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Pricing Operations
    
    func fetchPricing() async throws -> [SupabasePricing] {
        try await SupabaseManager.shared.client
            .from("Pricing")
            .select()
            .execute()
            .value
    }
    
    func createPricing(pricing: SupabasePricing) async throws {
        try await SupabaseManager.shared.client
            .from("Pricing")
            .insert(pricing)
            .execute()
    }
    
    func updatePricing(pricing: SupabasePricing) async throws {
        try await SupabaseManager.shared.client
            .from("Pricing")
            .update(pricing)
            .eq("id", value: pricing.id.uuidString)
            .execute()
    }
    
    func deletePricing(id: UUID) async throws {
        try await SupabaseManager.shared.client
            .from("Pricing")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func signIn(
        email: String,
        password: String
    ) async throws -> SupabaseUserProfile {

        let normalizedEmail = email.contains("@") ? email : "\(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())@rsms.local"

        let session = try await SupabaseManager.shared.client.auth.signIn(
            email: normalizedEmail,
            password: password
        )

        let authID = session.user.id

        print("✅ Auth Success")
        print("Auth User ID: \(authID.uuidString)")

        return try await fetchUserProfile(authUserID: authID)
    }

    func signOut() async throws {
        try await SupabaseManager.shared.client.auth.signOut()
    }

    private func fetchUserProfile(authUserID: UUID) async throws -> SupabaseUserProfile {
        do {
            let response = try await SupabaseManager.shared.client
                .from("User")
                .select()
                .eq("authUserID", value: authUserID.uuidString)
                .execute()

            let profiles = try JSONDecoder().decode(
                [SupabaseUserProfile].self,
                from: response.data
            )

            guard let profile = profiles.first else {
                throw NSError(
                    domain: "RSMS",
                    code: 404,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                        """
                        No User record found for auth user:
                        \(authUserID.uuidString)

                        Check authUserID column.
                        """
                    ]
                )
            }

            return profile
        } catch {
            throw error
        }
    }

    // MARK: - Product Operations

    func fetchProducts() async throws -> [ProductMasterRecord] {
        try await SupabaseManager.shared.client
            .from("Product")
            .select()
            .execute()
            .value
    }

    func createProduct(product: ProductMasterRecord) async throws {
        try await SupabaseManager.shared.client
            .from("Product")
            .insert(product)
            .execute()
    }

    func updateProduct(product: ProductMasterRecord) async throws {
        try await SupabaseManager.shared.client
            .from("Product")
            .update(product)
            .eq("id", value: product.id.uuidString)
            .execute()
    }

    func deleteProduct(id: UUID) async throws {
        try await SupabaseManager.shared.client
            .from("Product")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
