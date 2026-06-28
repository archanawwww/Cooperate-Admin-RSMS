import Foundation
import Combine
import Security

public enum UserRole: String, Codable, CaseIterable, Identifiable {
    case corporateAdmin = "Corporate Admin"
    case boutiqueManager = "Boutique Manager"
    case inventoryController = "Inventory Controller"
    case salesAssociate = "Sales Associate"

    public var id: String { rawValue }

    var icon: String {
        switch self {
        case .corporateAdmin:
            return "shield.lefthalf.filled"
        case .boutiqueManager:
            return "building.2"
        case .inventoryController:
            return "shippingbox"
        case .salesAssociate:
            return "person.2"
        }
    }
}

public enum AuthPermissionModule: String, Codable, CaseIterable, Identifiable {
    case userManagement = "User Management"
    case storeOperations = "Store Operations"
    case customerManagement = "Customer Management"
    case sales = "Sales"
    case inventory = "Inventory"
    case localInventory = "Local Inventory"
    case approvals = "Approvals"
    case reports = "Reports"
    case companyReports = "Company Reports"
    case events = "Events"

    public var id: String { rawValue }
}

public enum AuthPermissionAction: String, Codable, CaseIterable, Identifiable {
    case create = "Create"
    case read = "Read"
    case update = "Update"
    case approve = "Approve"
    case assign = "Assign"
    case report = "Report"

    public var id: String { rawValue }
}

public struct AuthPermission: Codable, Hashable, Identifiable {
    public let id: UUID
    let module: AuthPermissionModule
    let actions: Set<AuthPermissionAction>

    init(
        id: UUID = UUID(),
        module: AuthPermissionModule,
        actions: Set<AuthPermissionAction>
    ) {
        self.id = id
        self.module = module
        self.actions = actions
    }
}

private extension UserRole {
    var authPermissions: [AuthPermission] {
        switch self {
        case .corporateAdmin:
            return [
                AuthPermission(module: .userManagement, actions: [.create, .read, .update, .approve, .assign]),
                AuthPermission(module: .storeOperations, actions: [.read, .assign, .report]),
                AuthPermission(module: .inventory, actions: [.read, .approve, .report]),
                AuthPermission(module: .localInventory, actions: [.read]),
                AuthPermission(module: .approvals, actions: [.read, .approve]),
                AuthPermission(module: .reports, actions: [.read, .report]),
                AuthPermission(module: .companyReports, actions: [.read, .report])
            ]
        case .boutiqueManager:
            return [
                AuthPermission(module: .userManagement, actions: [.create, .read, .assign]),
                AuthPermission(module: .storeOperations, actions: [.read, .update, .assign, .report]),
                AuthPermission(module: .customerManagement, actions: [.read]),
                AuthPermission(module: .sales, actions: [.read, .report]),
                AuthPermission(module: .localInventory, actions: [.create, .read, .update, .report]),
                AuthPermission(module: .inventory, actions: [.read]),
                AuthPermission(module: .approvals, actions: [.create, .approve]),
                AuthPermission(module: .events, actions: [.create, .read, .update])
            ]
        case .inventoryController:
            return [
                AuthPermission(module: .inventory, actions: [.create, .read, .update, .report]),
                AuthPermission(module: .storeOperations, actions: [.read]),
                AuthPermission(module: .approvals, actions: [.create])
            ]
        case .salesAssociate:
            return [
                AuthPermission(module: .customerManagement, actions: [.create, .read, .update]),
                AuthPermission(module: .sales, actions: [.create, .read]),
                AuthPermission(module: .approvals, actions: [.create]),
                AuthPermission(module: .events, actions: [.read])
            ]
        }
    }

    func allows(_ action: AuthPermissionAction, in module: AuthPermissionModule) -> Bool {
        authPermissions.contains { permission in
            permission.module == module && permission.actions.contains(action)
        }
    }
}

public enum Country: String, Codable, CaseIterable, Identifiable {
    case india = "India"
    case unitedStates = "United States"
    case unitedKingdom = "United Kingdom"
    case france = "France"
    case singapore = "Singapore"

    public var id: String { rawValue }
}

public enum Region: String, Codable, CaseIterable, Identifiable {
    case mumbai = "Mumbai"
    case delhi = "Delhi"
    case bangalore = "Bangalore"
    case chennai = "Chennai"
    case hyderabad = "Hyderabad"
    case kolkata = "Kolkata"
    case pune = "Pune"
    case jaipur = "Jaipur"

    public var id: String { rawValue }
}

public struct StoreLocation: Codable, Equatable, Identifiable {
    public let id: UUID
    let name: String
    let country: Country
    let region: Region

    init(id: UUID = UUID(), name: String, country: Country, region: Region) {
        self.id = id
        self.name = name
        self.country = country
        self.region = region
    }
}

public struct ManagedUser: Codable, Equatable, Identifiable {
    public let id: UUID
    var firstName: String
    var lastName: String
    var username: String
    var email: String
    var phoneNumber: String
    var displayName: String
    var role: UserRole
    var assignedStoreID: UUID?
    var storeLocation: StoreLocation
    var isApprovedByAdmin: Bool
    var isActive: Bool
    var createdByUserID: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        role: UserRole,
        storeLocation: StoreLocation,
        isApprovedByAdmin: Bool,
        isActive: Bool? = nil,
        createdByUserID: UUID?,
        email: String? = nil,
        phoneNumber: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        let nameParts = ManagedUser.nameParts(from: displayName)
        self.id = id
        self.firstName = nameParts.first
        self.lastName = nameParts.last
        self.username = username
        self.email = email ?? "\(normalizedUsername(username))@rsms.local"
        self.phoneNumber = phoneNumber
        self.displayName = ManagedUser.displayName(firstName: nameParts.first, lastName: nameParts.last)
        self.role = role
        self.assignedStoreID = role == .corporateAdmin ? nil : storeLocation.id
        self.storeLocation = storeLocation
        self.isApprovedByAdmin = isApprovedByAdmin
        self.isActive = isActive ?? isApprovedByAdmin
        self.createdByUserID = createdByUserID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case username
        case email
        case phoneNumber
        case displayName
        case role
        case assignedStoreID
        case storeLocation
        case isApprovedByAdmin
        case isActive
        case createdByUserID
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        let nameParts = ManagedUser.nameParts(from: displayName)

        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? nameParts.first
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? nameParts.last
        username = try container.decode(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? "\(normalizedUsername(username))@rsms.local"
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber) ?? ""
        self.displayName = ManagedUser.displayName(firstName: firstName, lastName: lastName)
        role = try container.decode(UserRole.self, forKey: .role)
        storeLocation = try container.decode(StoreLocation.self, forKey: .storeLocation)
        assignedStoreID = try container.decodeIfPresent(UUID.self, forKey: .assignedStoreID) ?? (role == .corporateAdmin ? nil : storeLocation.id)
        isApprovedByAdmin = try container.decode(Bool.self, forKey: .isApprovedByAdmin)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? isApprovedByAdmin
        createdByUserID = try container.decodeIfPresent(UUID.self, forKey: .createdByUserID)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    static func displayName(firstName: String, lastName: String) -> String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func nameParts(from displayName: String) -> (first: String, last: String) {
        let parts = displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ", maxSplits: 1)
            .map(String.init)

        return (
            first: parts.first ?? "",
            last: parts.count > 1 ? parts[1] : ""
        )
    }
}

public struct AuthenticatedUser: Equatable {
    let id: UUID
    let role: UserRole
    let assignedStoreID: UUID?
    let region: Region
    let country: Country
    let storeName: String
    let displayName: String
    let username: String
    let permissions: [AuthPermission]
}

public enum AuthState: Equatable {
    case idle
    case authenticating
    case authenticated
    case failed(String)
}

public struct NewUserRequest {
    let username: String
    let password: String
    let displayName: String
    let role: UserRole
    let storeLocation: StoreLocation
}

public enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    public var id: String { rawValue }
}

public enum WorkTaskStatus: String, Codable, CaseIterable, Identifiable {
    case assigned = "Assigned"
    case inProgress = "In Progress"
    case completed = "Completed"

    public var id: String { rawValue }
}

public struct WorkTask: Codable, Equatable, Identifiable {
    public let id: UUID
    let title: String
    let notes: String
    let priority: TaskPriority
    var status: WorkTaskStatus
    let assignedToUserID: UUID
    let assignedByUserID: UUID
    let storeLocation: StoreLocation
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String,
        priority: TaskPriority,
        status: WorkTaskStatus = .assigned,
        assignedToUserID: UUID,
        assignedByUserID: UUID,
        storeLocation: StoreLocation,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.status = status
        self.assignedToUserID = assignedToUserID
        self.assignedByUserID = assignedByUserID
        self.storeLocation = storeLocation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

private enum AuthenticationError: LocalizedError {
    case emptyUsername
    case emptyPassword
    case emptyDisplayName
    case emptyTaskTitle
    case invalidCredentials
    case userNotApproved
    case userInactive
    case usernameTaken
    case userNotFound
    case storeNotFound
    case actionNotAllowed
    case unavailable

    var errorDescription: String? {
        switch self {
        case .emptyUsername:
            return "Enter your username."
        case .emptyPassword:
            return "Enter your password."
        case .emptyDisplayName:
            return "Enter a display name."
        case .emptyTaskTitle:
            return "Enter a task title."
        case .invalidCredentials:
            return "The username or password is incorrect."
        case .userNotApproved:
            return "This user must be approved by the admin before sign in."
        case .userInactive:
            return "This user is not active."
        case .usernameTaken:
            return "That username is already assigned."
        case .userNotFound:
            return "User record was not found."
        case .storeNotFound:
            return "Assigned store was not found."
        case .actionNotAllowed:
            return "You do not have permission to perform this action."
        case .unavailable:
            return "Authentication is unavailable right now. Please try again."
        }
    }
}

private struct UserDirectoryStore {
    private let key = "auth-management.user-directory"

    func loadUsers() throws -> [ManagedUser] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([ManagedUser].self, from: data)
        } catch {
            throw AuthenticationError.unavailable
        }
    }

    func saveUsers(_ users: [ManagedUser]) throws {
        do {
            let data = try JSONEncoder().encode(users)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            throw AuthenticationError.unavailable
        }
    }
}

private struct StoreDirectoryStore {
    private let key = "auth-management.store-directory"

    func loadStores() throws -> [StoreLocation] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([StoreLocation].self, from: data)
        } catch {
            throw AuthenticationError.unavailable
        }
    }

    func saveStores(_ stores: [StoreLocation]) throws {
        do {
            let data = try JSONEncoder().encode(stores)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            throw AuthenticationError.unavailable
        }
    }
}

private struct WorkTaskStore {
    private let key = "auth-management.work-tasks"

    func loadTasks() throws -> [WorkTask] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WorkTask].self, from: data)
        } catch {
            throw AuthenticationError.unavailable
        }
    }

    func saveTasks(_ tasks: [WorkTask]) throws {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            throw AuthenticationError.unavailable
        }
    }
}

private struct KeychainCredentialStore {
    private let service = Bundle.main.bundleIdentifier ?? "AuthManagement"

    func validate(username: String, password: String) throws -> Bool {
        guard !password.isEmpty else {
            throw AuthenticationError.emptyPassword
        }

        return try readPassword(for: username) == password
    }

    func save(password: String, for username: String) throws {
        guard !password.isEmpty else {
            throw AuthenticationError.emptyPassword
        }

        let data = Data(password.utf8)
        let query = baseQuery(username: username)
        let attributes = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw AuthenticationError.unavailable
        }

        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw AuthenticationError.unavailable
        }
    }

    func delete(username: String) throws {
        let status = SecItemDelete(baseQuery(username: username) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthenticationError.unavailable
        }
    }

    func readPassword(for username: String) throws -> String? {
        var query = baseQuery(username: username)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess,
              let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw AuthenticationError.unavailable
        }

        return password
    }

    private func baseQuery(username: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: normalizedUsername(username)
        ]
    }
}

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published private(set) var currentUser: AuthenticatedUser?
    @Published private(set) var authState: AuthState = .idle
    @Published private(set) var users: [ManagedUser] = []
    @Published private(set) var stores: [StoreLocation] = []
    @Published private(set) var tasks: [WorkTask] = []

    // Mock Inventory Database
    @Published var products: [Product] = []
    @Published var inventoryRecords: [InventoryRecord] = []
    @Published var varianceRecords: [VarianceRecord] = []
    @Published var actionLogs: [InventoryActionLog] = []

    private let directoryStore = UserDirectoryStore()
    private let storeStore = StoreDirectoryStore()
    private let taskStore = WorkTaskStore()
    private let credentialStore = KeychainCredentialStore()

    public init() {
        loadStores()
        loadDirectory()
        loadTasks()
        loadInventory()
    }

    func login(username: String, password: String) async {
        authState = .authenticating

        do {
            let username = try validateUsername(username)

            // Verify all users against the MockLoginBackend
            guard MockLoginBackend.shared.verify(username: username, password: password) else {
                throw AuthenticationError.invalidCredentials
            }

            // Find the user in the local directory
            guard let user = users.first(where: { normalizedUsername($0.username) == normalizedUsername(username) }) else {
                throw AuthenticationError.invalidCredentials
            }

            guard user.isApprovedByAdmin else {
                throw AuthenticationError.userNotApproved
            }

            guard user.isActive else {
                throw AuthenticationError.userInactive
            }

            currentUser = AuthenticatedUser(user: user)
            authState = .authenticated
        } catch {
            currentUser = nil
            authState = .failed(error.localizedDescription)
        }
    }

    func logout() {
        currentUser = nil
        authState = .idle
    }

    func createUser(_ request: NewUserRequest) throws {
        guard let creator = currentManagedUser else {
            throw AuthenticationError.actionNotAllowed
        }

        guard creator.isActive, canCreate(role: request.role, creatorRole: creator.role) else {
            throw AuthenticationError.actionNotAllowed
        }

        let username = try validateUsername(request.username)
        let displayName = try validateDisplayName(request.displayName)
        guard !request.password.isEmpty else {
            throw AuthenticationError.emptyPassword
        }

        guard users.contains(where: { normalizedUsername($0.username) == normalizedUsername(username) }) == false else {
            throw AuthenticationError.usernameTaken
        }

        let storeLocation = try validatedStoreLocation(for: request.storeLocation, creator: creator, newRole: request.role)
        let isAdminCreated = creator.role == .corporateAdmin
        let user = ManagedUser(
            username: username,
            displayName: displayName,
            role: request.role,
            storeLocation: storeLocation,
            isApprovedByAdmin: isAdminCreated,
            isActive: isAdminCreated,
            createdByUserID: creator.id
        )

        users.append(user)
        try credentialStore.save(password: request.password, for: username)
        try persistDirectory()
    }

    func approveUser(id: UUID) throws {
        guard currentManagedUser?.role == .corporateAdmin else {
            throw AuthenticationError.actionNotAllowed
        }

        guard let index = users.firstIndex(where: { $0.id == id }) else {
            throw AuthenticationError.userNotFound
        }

        users[index].isApprovedByAdmin = true
        users[index].isActive = true
        users[index].updatedAt = Date()
        try persistDirectory()
    }

    func updateOwnCredentials(username: String, password: String) throws {
        guard let currentUser else {
            throw AuthenticationError.actionNotAllowed
        }

        let newUsername = try validateUsername(username)
        guard users.contains(where: { $0.id != currentUser.id && normalizedUsername($0.username) == normalizedUsername(newUsername) }) == false else {
            throw AuthenticationError.usernameTaken
        }

        guard let index = users.firstIndex(where: { $0.id == currentUser.id }) else {
            throw AuthenticationError.userNotFound
        }

        let oldUsername = users[index].username
        users[index].username = newUsername
        users[index].updatedAt = Date()

        try credentialStore.save(password: password, for: newUsername)
        if normalizedUsername(oldUsername) != normalizedUsername(newUsername) {
            try credentialStore.delete(username: oldUsername)
        }

        try persistDirectory()
        self.currentUser = AuthenticatedUser(user: users[index])
    }

    func updateManagedUser(
        id: UUID,
        displayName: String,
        username: String,
        password: String?,
        role: UserRole,
        storeLocation: StoreLocation,
        isActive: Bool
    ) throws {
        guard let creator = currentManagedUser, creator.role == .corporateAdmin else {
            throw AuthenticationError.actionNotAllowed
        }

        guard let index = users.firstIndex(where: { $0.id == id }) else {
            throw AuthenticationError.userNotFound
        }

        let newUsername = try validateUsername(username)
        let newDisplayName = try validateDisplayName(displayName)

        guard users.contains(where: { $0.id != id && normalizedUsername($0.username) == normalizedUsername(newUsername) }) == false else {
            throw AuthenticationError.usernameTaken
        }

        let oldUsername = users[index].username

        // Validate or dynamically create the store
        let validatedStore = try validatedStoreLocation(for: storeLocation, creator: creator, newRole: role)

        users[index].displayName = newDisplayName
        users[index].username = newUsername
        users[index].role = role
        users[index].storeLocation = validatedStore
        users[index].assignedStoreID = role == .corporateAdmin ? nil : validatedStore.id
        users[index].isActive = isActive
        users[index].updatedAt = Date()

        if let password = password, !password.isEmpty {
            try credentialStore.save(password: password, for: newUsername)
            MockLoginBackend.shared.updateCredentials(
                oldUsername: oldUsername,
                newUsername: newUsername,
                newPassword: password,
                role: role.rawValue
            )
        } else {
            MockLoginBackend.shared.updateCredentials(
                oldUsername: oldUsername,
                newUsername: newUsername,
                newPassword: nil,
                role: role.rawValue
            )
            if normalizedUsername(oldUsername) != normalizedUsername(newUsername) {
                if let oldPassword = try? credentialStore.readPassword(for: oldUsername) {
                    try? credentialStore.save(password: oldPassword, for: newUsername)
                    try? credentialStore.delete(username: oldUsername)
                }
            }
        }

        try persistDirectory()

        if currentUser?.id == id {
            self.currentUser = AuthenticatedUser(user: users[index])
        }
    }

    var corporateHeadquartersID: UUID {
        SeedData.corporateHeadquartersID
    }

    func users(for country: Country? = nil, region: Region? = nil) -> [ManagedUser] {
        users.filter { user in
            let matchesCountry = country.map { user.storeLocation.country == $0 } ?? true
            let matchesRegion = region.map { user.storeLocation.region == $0 } ?? true
            return user.isActive && matchesCountry && matchesRegion
        }
    }

    func canCurrentUser(_ action: AuthPermissionAction, in module: AuthPermissionModule) -> Bool {
        currentManagedUser?.role.allows(action, in: module) ?? false
    }

    // MARK: - Store-Based Data Isolation Helpers

    /// Users belonging to the current user's store (for Boutique Manager / SA views)
    func usersInCurrentStore() -> [ManagedUser] {
        guard let storeID = currentUser?.assignedStoreID else {
            return users // Corporate Admin sees all
        }
        return users.filter { $0.assignedStoreID == storeID }
    }

    /// Sales Associates created by the current Boutique Manager
    func salesAssociatesUnderCurrentManager() -> [ManagedUser] {
        guard let manager = currentManagedUser, manager.role == .boutiqueManager else {
            return []
        }
        return users.filter {
            $0.role == .salesAssociate
            && $0.createdByUserID == manager.id
            && $0.assignedStoreID == manager.assignedStoreID
        }
    }

    /// Pending approval users visible to the current user
    func pendingApprovalUsers() -> [ManagedUser] {
        guard let role = currentUser?.role else { return [] }
        switch role {
        case .corporateAdmin:
            return users.filter { !$0.isApprovedByAdmin }
        case .boutiqueManager:
            guard let manager = currentManagedUser else { return [] }
            return users.filter { !$0.isApprovedByAdmin && $0.createdByUserID == manager.id }
        default:
            return []
        }
    }

    func eligibleTaskAssignees() -> [ManagedUser] {
        guard let assigner = currentManagedUser else {
            return []
        }

        return users
            .filter { user in
                user.isApprovedByAdmin
                && user.isActive
                && user.id != assigner.id
                && canAssignTask(to: user, assigner: assigner)
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func tasksVisibleToCurrentUser() -> [WorkTask] {
        guard let user = currentManagedUser else {
            return []
        }

        switch user.role {
        case .corporateAdmin:
            return tasks.sortedByNewest()
        case .boutiqueManager:
            return tasks
                .filter { $0.assignedByUserID == user.id || $0.assignedToUserID == user.id || $0.storeLocation.id == user.storeLocation.id }
                .sortedByNewest()
        case .inventoryController, .salesAssociate:
            return tasks
                .filter { $0.assignedToUserID == user.id }
                .sortedByNewest()
        }
    }

    func assignTask(title: String, notes: String, priority: TaskPriority, assigneeID: UUID) throws {
        guard let assigner = currentManagedUser else {
            throw AuthenticationError.actionNotAllowed
        }

        guard assigner.isActive else {
            throw AuthenticationError.actionNotAllowed
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AuthenticationError.emptyTaskTitle
        }

        guard let assignee = users.first(where: { $0.id == assigneeID && $0.isApprovedByAdmin }) else {
            throw AuthenticationError.userNotFound
        }

        guard canAssignTask(to: assignee, assigner: assigner) else {
            throw AuthenticationError.actionNotAllowed
        }

        let task = WorkTask(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            assignedToUserID: assignee.id,
            assignedByUserID: assigner.id,
            storeLocation: assignee.storeLocation
        )

        tasks.insert(task, at: 0)
        try persistTasks()
    }

    func updateTaskStatus(id: UUID, status: WorkTaskStatus) throws {
        guard let user = currentManagedUser else {
            throw AuthenticationError.actionNotAllowed
        }

        guard user.isActive else {
            throw AuthenticationError.actionNotAllowed
        }

        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw AuthenticationError.userNotFound
        }

        let task = tasks[index]
        guard user.role == .corporateAdmin || task.assignedToUserID == user.id || task.assignedByUserID == user.id else {
            throw AuthenticationError.actionNotAllowed
        }

        tasks[index].status = status
        tasks[index].updatedAt = Date()
        try persistTasks()
    }

    private var currentManagedUser: ManagedUser? {
        guard let currentUser else {
            return nil
        }

        return users.first(where: { $0.id == currentUser.id })
    }

    private func loadDirectory() {
        do {
            users = try directoryStore.loadUsers()
            if users.isEmpty {
                try seedAdminUser()
            }
            try ensureRequiredRoleSeedUsers()
        } catch {
            users = []
            authState = .failed(error.localizedDescription)
        }
    }

    private func loadStores() {
        do {
            stores = try storeStore.loadStores()
            if stores.isEmpty {
                stores = SeedData.stores
                try persistStores()
            }
        } catch {
            stores = []
            authState = .failed(error.localizedDescription)
        }
    }

    private func loadTasks() {
        do {
            tasks = try taskStore.loadTasks()
        } catch {
            tasks = []
            authState = .failed(error.localizedDescription)
        }
    }

    private func seedAdminUser() throws {
        let adminDetails = MockLoginBackend.shared.getAdminUsernames()
        users = []
        for username in adminDetails {
            let admin = ManagedUser(
                username: username,
                displayName: username,
                role: .corporateAdmin,
                storeLocation: SeedData.corporateHeadquarters,
                isApprovedByAdmin: true,
                isActive: true,
                createdByUserID: nil
            )
            users.append(admin)
        }
        try persistDirectory()
    }

    private func ensureRequiredRoleSeedUsers() throws {
        var didChange = false

        if users.contains(where: { $0.role == .boutiqueManager }) == false {
            let manager = ManagedUser(
                username: "Manager",
                displayName: "Priya Sharma",
                role: .boutiqueManager,
                storeLocation: SeedData.mumbaiFlagship,
                isApprovedByAdmin: true,
                isActive: true,
                createdByUserID: users.first(where: { $0.role == .corporateAdmin })?.id,
                email: "priya.sharma@rsms.local",
                phoneNumber: "+91 90000 10001"
            )
            if users.contains(where: { normalizedUsername($0.username) == normalizedUsername(manager.username) }) == false {
                users.append(manager)
                try credentialStore.save(password: "1234", for: manager.username)
                didChange = true
            }
        }

        if users.contains(where: { $0.role == .salesAssociate }) == false {
            let creatorID = users.first(where: { $0.role == .boutiqueManager })?.id
            let associates = [
                ManagedUser(
                    username: "Associate",
                    displayName: "Aarav Mehta",
                    role: .salesAssociate,
                    storeLocation: SeedData.mumbaiFlagship,
                    isApprovedByAdmin: true,
                    isActive: true,
                    createdByUserID: creatorID,
                    email: "aarav.mehta@rsms.local",
                    phoneNumber: "+91 90000 10002"
                ),
                ManagedUser(
                    username: "Associate2",
                    displayName: "Nisha Rao",
                    role: .salesAssociate,
                    storeLocation: SeedData.mumbaiFlagship,
                    isApprovedByAdmin: true,
                    isActive: true,
                    createdByUserID: creatorID,
                    email: "nisha.rao@rsms.local",
                    phoneNumber: "+91 90000 10003"
                )
            ]

            for associate in associates where users.contains(where: { normalizedUsername($0.username) == normalizedUsername(associate.username) }) == false {
                users.append(associate)
                try credentialStore.save(password: "1234", for: associate.username)
                didChange = true
            }
        }

        if users.contains(where: { $0.role == .inventoryController }) == false {
            let ic = ManagedUser(
                username: "Inventory",
                displayName: "Rahul Verma",
                role: .inventoryController,
                storeLocation: SeedData.corporateHeadquarters,
                isApprovedByAdmin: true,
                isActive: true,
                createdByUserID: users.first(where: { $0.role == .corporateAdmin })?.id,
                email: "rahul.verma@rsms.local",
                phoneNumber: "+91 90000 10004"
            )
            if users.contains(where: { normalizedUsername($0.username) == normalizedUsername(ic.username) }) == false {
                users.append(ic)
                try credentialStore.save(password: "1234", for: ic.username)
                didChange = true
            }
        }

        if didChange {
            try persistDirectory()
        }
    }

    private func persistDirectory() throws {
        try directoryStore.saveUsers(users)
    }

    private func persistStores() throws {
        try storeStore.saveStores(stores)
    }

    private func persistTasks() throws {
        try taskStore.saveTasks(tasks)
    }

    private func canCreate(role: UserRole, creatorRole: UserRole) -> Bool {
        switch creatorRole {
        case .corporateAdmin:
            return creatorRole.allows(.create, in: .userManagement) && (role == .boutiqueManager || role == .inventoryController)
        case .boutiqueManager:
            return creatorRole.allows(.create, in: .userManagement) && role == .salesAssociate
        case .inventoryController, .salesAssociate:
            return false
        }
    }

    private func canAssignTask(to assignee: ManagedUser, assigner: ManagedUser) -> Bool {
        switch assigner.role {
        case .corporateAdmin:
            return assigner.role.allows(.assign, in: .userManagement)
            && (assignee.role == .boutiqueManager || assignee.role == .inventoryController)
        case .boutiqueManager:
            return assigner.role.allows(.assign, in: .userManagement)
            && assignee.role == .salesAssociate
            && assignee.assignedStoreID == assigner.assignedStoreID
        case .inventoryController, .salesAssociate:
            return false
        }
    }

    private func validatedStoreLocation(for requestedStore: StoreLocation, creator: ManagedUser, newRole: UserRole) throws -> StoreLocation {
        switch creator.role {
        case .corporateAdmin:
            guard newRole != .corporateAdmin else {
                throw AuthenticationError.actionNotAllowed
            }
            if let store = knownStore(matching: requestedStore) {
                return store
            } else {
                // Dynamically create a new store and save it!
                let newStore = StoreLocation(
                    id: UUID(),
                    name: requestedStore.name.isEmpty ? "\(requestedStore.region.rawValue) Boutique" : requestedStore.name,
                    country: requestedStore.country,
                    region: requestedStore.region
                )
                stores.append(newStore)
                try persistStores()
                return newStore
            }
        case .boutiqueManager:
            guard newRole == .salesAssociate,
                  let assignedStoreID = creator.assignedStoreID,
                  let store = stores.first(where: { $0.id == assignedStoreID }) else {
                throw AuthenticationError.storeNotFound
            }
            return store
        case .inventoryController, .salesAssociate:
            throw AuthenticationError.actionNotAllowed
        }
    }

    private func knownStore(matching storeLocation: StoreLocation) -> StoreLocation? {
        stores.first { $0.id == storeLocation.id }
        ?? stores.first {
            $0.name.localizedCaseInsensitiveCompare(storeLocation.name) == .orderedSame
            && $0.country == storeLocation.country
            && $0.region == storeLocation.region
        }
    }

    private func validateUsername(_ username: String) throws -> String {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            throw AuthenticationError.emptyUsername
        }

        return trimmedUsername
    }

    private func validateDisplayName(_ displayName: String) throws -> String {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDisplayName.isEmpty else {
            throw AuthenticationError.emptyDisplayName
        }

        return trimmedDisplayName
    }
}

private extension AuthenticatedUser {
    init(user: ManagedUser) {
        self.id = user.id
        self.role = user.role
        self.assignedStoreID = user.assignedStoreID
        self.region = user.storeLocation.region
        self.country = user.storeLocation.country
        self.storeName = user.storeLocation.name
        self.displayName = user.displayName
        self.username = user.username
        self.permissions = user.role.authPermissions
    }
}

private enum SeedData {
    static let corporateHeadquartersID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let mumbaiFlagshipID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
    static let delhiBoutiqueID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!

    static let corporateHeadquarters = StoreLocation(
        id: corporateHeadquartersID,
        name: "Corporate Headquarters",
        country: .india,
        region: .mumbai
    )

    static let mumbaiFlagship = StoreLocation(
        id: mumbaiFlagshipID,
        name: "Mumbai Flagship",
        country: .india,
        region: .mumbai
    )

    static let delhiBoutique = StoreLocation(
        id: delhiBoutiqueID,
        name: "Delhi Boutique",
        country: .india,
        region: .delhi
    )

    static let stores = [
        corporateHeadquarters,
        mumbaiFlagship,
        delhiBoutique
    ]
}

private func normalizedUsername(_ username: String) -> String {
    username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

private extension Array where Element == WorkTask {
    func sortedByNewest() -> [WorkTask] {
        sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Inventory Logging Structure & Extensions

struct InventoryActionLog: Identifiable, Codable, Hashable {
    public let id: UUID
    public let date: Date
    public let username: String
    public let actionType: String // e.g. "Influx", "Outflux", "Variance"
    public let details: String
    public let storeName: String

    public init(id: UUID = UUID(), date: Date = Date(), username: String, actionType: String, details: String, storeName: String) {
        self.id = id
        self.date = date
        self.username = username
        self.actionType = actionType
        self.details = details
        self.storeName = storeName
    }
}

extension AuthenticationManager {
    private func loadInventory() {
        // Master Catalog of Products
        self.products = [
            Product(sku: "SKU-1001", name: "Classic Leather Tote", brand: "Noir Luxe", category: .leather, barcode: "1234567890123", basePrice: 2400.0),
            Product(sku: "SKU-1002", name: "Silk Evening Clutch", brand: "Noir Luxe", category: .accessories, barcode: "1234567890124", basePrice: 1200.0),
            Product(sku: "SKU-1003", name: "Diamond Cufflinks", brand: "Noir Luxe", category: .jewelry, barcode: "1234567890125", basePrice: 4500.0),
            Product(sku: "SKU-1004", name: "Cashmere Scarf", brand: "Noir Luxe", category: .readyToWear, barcode: "1234567890126", basePrice: 850.0),
            Product(sku: "SKU-1005", name: "GMT Master Watch", brand: "Noir Luxe", category: .watches, barcode: "1234567890127", basePrice: 12500.0)
        ]

        // Load or create initial InventoryRecords
        var records: [InventoryRecord] = []
        let savedRecordsKey = "auth-management.inventory-records"
        if let data = UserDefaults.standard.data(forKey: savedRecordsKey),
           let decoded = try? JSONDecoder().decode([InventoryRecord].self, from: data) {
            records = decoded
        } else {
            // Seed initial quantities
            records.append(InventoryRecord(productID: products[0].id, storeID: SeedData.mumbaiFlagshipID, quantity: 12, reorderThreshold: 5))
            records.append(InventoryRecord(productID: products[1].id, storeID: SeedData.mumbaiFlagshipID, quantity: 3, reorderThreshold: 5))
            records.append(InventoryRecord(productID: products[2].id, storeID: SeedData.mumbaiFlagshipID, quantity: 8, reorderThreshold: 4))
            records.append(InventoryRecord(productID: products[3].id, storeID: SeedData.mumbaiFlagshipID, quantity: 2, reorderThreshold: 5))
            records.append(InventoryRecord(productID: products[4].id, storeID: SeedData.mumbaiFlagshipID, quantity: 5, reorderThreshold: 2))

            records.append(InventoryRecord(productID: products[0].id, storeID: SeedData.delhiBoutiqueID, quantity: 6, reorderThreshold: 3))
            records.append(InventoryRecord(productID: products[1].id, storeID: SeedData.delhiBoutiqueID, quantity: 7, reorderThreshold: 3))
            records.append(InventoryRecord(productID: products[2].id, storeID: SeedData.delhiBoutiqueID, quantity: 2, reorderThreshold: 4))
            records.append(InventoryRecord(productID: products[3].id, storeID: SeedData.delhiBoutiqueID, quantity: 10, reorderThreshold: 5))
            records.append(InventoryRecord(productID: products[4].id, storeID: SeedData.delhiBoutiqueID, quantity: 1, reorderThreshold: 2))

            records.append(InventoryRecord(productID: products[0].id, storeID: SeedData.corporateHeadquartersID, quantity: 150, reorderThreshold: 20))
            records.append(InventoryRecord(productID: products[1].id, storeID: SeedData.corporateHeadquartersID, quantity: 80, reorderThreshold: 15))
            records.append(InventoryRecord(productID: products[2].id, storeID: SeedData.corporateHeadquartersID, quantity: 45, reorderThreshold: 10))
            records.append(InventoryRecord(productID: products[3].id, storeID: SeedData.corporateHeadquartersID, quantity: 200, reorderThreshold: 25))
            records.append(InventoryRecord(productID: products[4].id, storeID: SeedData.corporateHeadquartersID, quantity: 20, reorderThreshold: 5))

            persistInventoryRecords(records)
        }
        self.inventoryRecords = records

        // Load or seed Variance Records
        let varianceKey = "auth-management.variance-records"
        if let data = UserDefaults.standard.data(forKey: varianceKey),
           let decoded = try? JSONDecoder().decode([VarianceRecord].self, from: data) {
            self.varianceRecords = decoded
        } else {
            let v1 = VarianceRecord(
                productID: products[1].id,
                expectedQuantity: 4,
                actualQuantity: 3,
                reason: "Silk Evening Clutch - Found damaged on arrival.",
                status: .resolved
            )
            let v2 = VarianceRecord(
                productID: products[4].id,
                expectedQuantity: 2,
                actualQuantity: 1,
                reason: "GMT Master Watch - Discrepancy during monthly cycle count.",
                status: .open
            )
            self.varianceRecords = [v1, v2]
            persistVarianceRecords(self.varianceRecords)
        }

        // Load or seed Action Logs
        let logsKey = "auth-management.action-logs"
        if let data = UserDefaults.standard.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([InventoryActionLog].self, from: data) {
            self.actionLogs = decoded
        } else {
            self.actionLogs = [
                InventoryActionLog(
                    id: UUID(),
                    date: Date().addingTimeInterval(-86400),
                    username: "Inventory",
                    actionType: "Influx (Vendor Receipt)",
                    details: "Received 50 units of Classic Leather Tote at Corporate Headquarters.",
                    storeName: "Corporate Headquarters"
                ),
                InventoryActionLog(
                    id: UUID(),
                    date: Date().addingTimeInterval(-3600 * 2),
                    username: "Inventory",
                    actionType: "Outflux (Store Transfer)",
                    details: "Transferred 10 units of GMT Master Watch to Delhi Boutique.",
                    storeName: "Corporate Headquarters"
                )
            ]
            persistActionLogs(self.actionLogs)
        }
    }

    func persistInventoryRecords(_ records: [InventoryRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "auth-management.inventory-records")
        }
    }

    func persistVarianceRecords(_ records: [VarianceRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "auth-management.variance-records")
        }
    }

    func persistActionLogs(_ logs: [InventoryActionLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: "auth-management.action-logs")
        }
    }

    // Update inventory quantity
    func updateInventoryQuantity(productID: UUID, storeID: UUID, newQuantity: Int) throws {
        guard let user = currentUser else {
            throw AuthenticationError.actionNotAllowed
        }

        // Check write permission
        // Boutique Managers can only write to their own store.
        if user.role == .boutiqueManager {
            guard user.assignedStoreID == storeID else {
                throw AuthenticationError.actionNotAllowed
            }
        } else if user.role == .inventoryController {
            // IC can update central/any warehouse
        } else if user.role == .corporateAdmin {
            // Admin can write anything
        } else {
            throw AuthenticationError.actionNotAllowed
        }

        if let idx = inventoryRecords.firstIndex(where: { $0.productID == productID && $0.storeID == storeID }) {
            let oldQty = inventoryRecords[idx].quantity
            inventoryRecords[idx].quantity = newQuantity
            inventoryRecords[idx].lastUpdated = Date()
            persistInventoryRecords(inventoryRecords)

            // Log action
            let storeObj = stores.first(where: { $0.id == storeID })
            let productObj = products.first(where: { $0.id == productID })
            let change = newQuantity - oldQty
            let type = change >= 0 ? "Influx (Adjustment)" : "Outflux (Adjustment)"
            let log = InventoryActionLog(
                id: UUID(),
                date: Date(),
                username: user.username,
                actionType: type,
                details: "Adjusted \(productObj?.name ?? "Unknown Product") quantity from \(oldQty) to \(newQuantity) (\(change >= 0 ? "+" : "")\(change) units).",
                storeName: storeObj?.name ?? "Unknown Store"
            )
            actionLogs.insert(log, at: 0)
            persistActionLogs(actionLogs)
        }
    }

    // Add Variance Record
    func addVarianceRecord(productID: UUID, expected: Int, actual: Int, reason: String) throws {
        guard let user = currentUser else {
            throw AuthenticationError.actionNotAllowed
        }
        
        let newRecord = VarianceRecord(
            id: UUID(),
            productID: productID,
            expectedQuantity: expected,
            actualQuantity: actual,
            reason: reason,
            status: .open
        )
        varianceRecords.insert(newRecord, at: 0)
        persistVarianceRecords(varianceRecords)
        
        // Log action
        let productObj = products.first(where: { $0.id == productID })
        let log = InventoryActionLog(
            id: UUID(),
            date: Date(),
            username: user.username,
            actionType: "Variance Report",
            details: "Reported stock discrepancy for \(productObj?.name ?? "Unknown Product") (Expected: \(expected), Actual: \(actual), Variance: \(actual - expected)). Reason: \(reason)",
            storeName: user.storeName
        )
        actionLogs.insert(log, at: 0)
        persistActionLogs(actionLogs)
    }

    // Resolve / update variance record status
    internal func updateVarianceStatus(id: UUID, status: VarianceStatus) throws {
        guard let user = currentUser else {
            throw AuthenticationError.actionNotAllowed
        }

        // Only Admin and IC can resolve variances
        guard user.role == .corporateAdmin || user.role == .inventoryController else {
            throw AuthenticationError.actionNotAllowed
        }

        if let idx = varianceRecords.firstIndex(where: { $0.id == id }) {
            varianceRecords[idx].status = status
            persistVarianceRecords(varianceRecords)

            let productObj = products.first(where: { $0.id == varianceRecords[idx].productID })
            let log = InventoryActionLog(
                id: UUID(),
                date: Date(),
                username: user.username,
                actionType: "Variance Status Updated",
                details: "Updated variance status for \(productObj?.name ?? "Unknown Product") to \(status.rawValue).",
                storeName: user.storeName
            )
            actionLogs.insert(log, at: 0)
            persistActionLogs(actionLogs)
        }
    }

    // Record custom movement (influx / outflux)
    func transferStock(productID: UUID, fromStoreID: UUID, toStoreID: UUID, quantity: Int) throws {
        guard let user = currentUser else {
            throw AuthenticationError.actionNotAllowed
        }

        guard quantity > 0 else { return }

        // Find from store inventory record
        guard let fromIdx = inventoryRecords.firstIndex(where: { $0.productID == productID && $0.storeID == fromStoreID }),
              inventoryRecords[fromIdx].quantity >= quantity else {
            throw NSError(domain: "InventoryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Insufficient stock at source store."])
        }

        // Deduct
        inventoryRecords[fromIdx].quantity -= quantity
        inventoryRecords[fromIdx].lastUpdated = Date()

        // Add
        if let toIdx = inventoryRecords.firstIndex(where: { $0.productID == productID && $0.storeID == toStoreID }) {
            inventoryRecords[toIdx].quantity += quantity
            inventoryRecords[toIdx].lastUpdated = Date()
        } else {
            inventoryRecords.append(InventoryRecord(productID: productID, storeID: toStoreID, quantity: quantity))
        }

        persistInventoryRecords(inventoryRecords)

        let productObj = products.first(where: { $0.id == productID })
        let fromStore = stores.first(where: { $0.id == fromStoreID })?.name ?? "Central"
        let toStore = stores.first(where: { $0.id == toStoreID })?.name ?? "Boutique"

        // Log action
        let log = InventoryActionLog(
            id: UUID(),
            date: Date(),
            username: user.username,
            actionType: "Outflux (Store Transfer)",
            details: "Transferred \(quantity) units of \(productObj?.name ?? "Unknown Product") from \(fromStore) to \(toStore).",
            storeName: fromStore
        )
        actionLogs.insert(log, at: 0)
        persistActionLogs(actionLogs)
    }
}

