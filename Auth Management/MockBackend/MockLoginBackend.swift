import Foundation

// MARK: - Admin Login Details

public struct AdminLoginDetails {
    public var username: String
    public var password: String
    public var role: String // "Corporate Admin", "Boutique Manager", "Inventory Controller", "Sales Associate"
}

// MARK: - Mock Login Backend

/// Centralized mock backend that holds all login credentials.
/// The Corporate Admin creates credentials for Boutique Managers and Inventory Controllers.
/// Boutique Managers create credentials for Sales Associates.
public class MockLoginBackend {
    public static let shared = MockLoginBackend()

    // Admin-managed credential store
    private var credentials: [AdminLoginDetails] = [
        // Default Corporate Admin
        AdminLoginDetails(username: "Admin", password: "AdminPassword123!", role: "Corporate Admin"),
        // Seeded Boutique Manager for Mumbai Flagship
        AdminLoginDetails(username: "Manager", password: "Manager123!", role: "Boutique Manager"),
        // Seeded Inventory Controller
        AdminLoginDetails(username: "Inventory", password: "Inventory123!", role: "Inventory Controller"),
        // Seeded Sales Associates under Manager
        AdminLoginDetails(username: "Associate", password: "Associate123!", role: "Sales Associate"),
        AdminLoginDetails(username: "Associate2", password: "Associate123!", role: "Sales Associate")
    ]

    private init() {}

    /// Verify credentials against the mock store
    public func verify(username: String, password: String) -> Bool {
        credentials.contains {
            $0.username.lowercased() == username.lowercased() && $0.password == password
        }
    }

    /// Look up the role for a given username
    public func role(for username: String) -> String? {
        credentials.first(where: { $0.username.lowercased() == username.lowercased() })?.role
    }

    /// Get all usernames that are registered as admins (Corporate Admin role)
    public func getAdminUsernames() -> [String] {
        credentials.filter { $0.role == "Corporate Admin" }.map { $0.username }
    }

    /// Get all registered usernames
    public func getAllUsernames() -> [String] {
        credentials.map { $0.username }
    }

    /// Check if a username already exists
    public func usernameExists(_ username: String) -> Bool {
        credentials.contains { $0.username.lowercased() == username.lowercased() }
    }

    /// Add a new user's credentials (called when Admin/Manager creates a user)
    public func addCredentials(username: String, password: String, role: String) {
        guard !usernameExists(username) else { return }
        credentials.append(AdminLoginDetails(username: username, password: password, role: role))
    }

    /// Update password for a user
    public func updatePassword(username: String, newPassword: String) {
        if let index = credentials.firstIndex(where: { $0.username.lowercased() == username.lowercased() }) {
            credentials[index].password = newPassword
        }
    }
}
