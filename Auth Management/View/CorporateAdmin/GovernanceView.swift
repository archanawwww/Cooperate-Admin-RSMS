import SwiftUI

// MARK: - Governance View (Tab 1)

/// Tab 1 — Store Managers, Company Policies & Business Rules, Audit Logs.
/// Full CRUD for users and policies with 2FA gating, search, and filter.
struct GovernanceView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false

    // MARK: - User Management State

    @State private var newUsername = ""
    @State private var newPhoneNumber = ""
    @State private var newPassword = ""
    @State private var newFirstName = ""
    @State private var newLastName = ""
    @State private var newStoreID: UUID? = nil
    @State private var newRole: UserRole = .boutiqueManager
    @State private var statusMessage: String?

    @State private var editingUser: ManagedUser? = nil
    @State private var userToDelete: ManagedUser? = nil
    @State private var showUserDeleteConfirmation = false
    @State private var userAssignmentNotice: UserAssignmentNotice? = nil

    @State private var userSearchText = ""
    @State private var selectedRoleFilter: UserRole? = nil

    // 2FA gating
    @State private var show2FAForEdit = false
    @State private var show2FAForDelete = false
    @State private var pending2FAUser: ManagedUser? = nil

    // MARK: - Policy Management State

    @State private var editingPolicy: CompanyPolicy? = nil
    @State private var isAddingPolicy = false
    @State private var policyToDelete: CompanyPolicy? = nil
    @State private var showDeleteConfirmation = false

    // MARK: - Audit Log State

    @State private var auditSearchText = ""
    @State private var auditFilterAction: AuditAction? = nil

    // MARK: - Section Expansion

    @State private var expandedSection: GovernanceSection? = .managers

    enum GovernanceSection: String, CaseIterable {
        case managers = "Store Managers"
        case policies = "Company Policies"
        case auditLog = "Audit Logs"
    }

    private var creatableRoles: [UserRole] {
        [.boutiqueManager, .inventoryController]
    }

    private var manageableUserRoles: [UserRole] {
        [.boutiqueManager, .inventoryController]
    }

    private struct UserAssignmentNotice: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    // MARK: - Filtered Data

    private var filteredUsers: [ManagedUser] {
        var result = authManager.users.filter { manageableUserRoles.contains($0.role) }
        if let roleFilter = selectedRoleFilter {
            result = result.filter { $0.role == roleFilter }
        }
        guard !userSearchText.isEmpty else { return result }
        let query = userSearchText.lowercased()
        return result.filter {
            $0.displayName.lowercased().contains(query)
            || $0.username.lowercased().contains(query)
            || $0.storeLocation.name.lowercased().contains(query)
            || $0.storeLocation.region.rawValue.lowercased().contains(query)
        }
    }

    private var filteredAuditLogs: [AuditLog] {
        var result = authManager.productAuditLogs
        if let actionFilter = auditFilterAction {
            result = result.filter { $0.action == actionFilter }
        }
        guard !auditSearchText.isEmpty else { return result }
        let query = auditSearchText.lowercased()
        return result.filter {
            $0.tableName.lowercased().contains(query)
            || $0.action.rawValue.lowercased().contains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MatteTheme.Spacing.sectionSpacing) {
                    governanceHeader

                    // Store Managers Section
                    governanceSectionCard(
                        section: .managers,
                        icon: "building.2.fill",
                        badge: "\(filteredUsers.count)"
                    ) {
                        storeManagersContent
                    }

                    // Company Policies Section
                    governanceSectionCard(
                        section: .policies,
                        icon: "doc.text.fill",
                        badge: "\(authManager.companyPolicies.count)"
                    ) {
                        companyPoliciesContent
                    }

                    // Audit Logs Section
                    governanceSectionCard(
                        section: .auditLog,
                        icon: "clock.arrow.circlepath",
                        badge: "\(authManager.productAuditLogs.count)"
                    ) {
                        auditLogsContent
                    }
                }
                .padding(.horizontal, MatteTheme.Spacing.horizontalMargin)
                .padding(.top, MatteTheme.Spacing.lg)
                .padding(.bottom, 100)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Governance")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
            .task {
                await authManager.refreshUsersFromSupabase()
                await authManager.fetchCompanyPolicies()
            }
            // 2FA → Edit
            .sheet(isPresented: $show2FAForEdit) {
                if let user = pending2FAUser {
                    TwoFactorVerificationSheet(
                        title: "Verify to Edit",
                        subtitle: "2FA required to modify \(user.displayName.isEmpty ? user.username : user.displayName)",
                        onSuccess: {
                            editingUser = user
                        }
                    )
                }
            }
            .sheet(item: $editingUser) { user in
                EditUserSheet(user: user) { updatedUser in
                    showNoticeAfterEditing(original: user, updated: updatedUser)
                }
                .environmentObject(authManager)
            }
            // 2FA → Delete
            .sheet(isPresented: $show2FAForDelete) {
                if let user = pending2FAUser {
                    TwoFactorVerificationSheet(
                        title: "Verify to Delete",
                        subtitle: "2FA required to delete \(user.displayName.isEmpty ? user.username : user.displayName)",
                        onSuccess: {
                            userToDelete = user
                            showUserDeleteConfirmation = true
                        }
                    )
                }
            }
            .alert("Delete User", isPresented: $showUserDeleteConfirmation, presenting: userToDelete) { user in
                Button("Delete", role: .destructive) { deleteUser(user) }
                Button("Cancel", role: .cancel) {}
            } message: { user in
                Text("Delete \(user.displayName.isEmpty ? user.username : user.displayName) from \(user.storeLocation.name)?")
            }
            .alert(item: $userAssignmentNotice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Policies
            .sheet(isPresented: $isAddingPolicy) {
                PolicyEditorSheet(policy: nil)
                    .environmentObject(authManager)
            }
            .sheet(item: $editingPolicy) { policy in
                PolicyEditorSheet(policy: policy)
                    .environmentObject(authManager)
            }
            .alert("Delete Policy", isPresented: $showDeleteConfirmation, presenting: policyToDelete) { policy in
                Button("Delete", role: .destructive) {
                    authManager.deleteCompanyPolicy(id: policy.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: { policy in
                Text("Are you sure you want to permanently delete the policy '\(policy.title)'?")
            }
        }
    }

    // MARK: - Header

    private var governanceHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Governance")
                .font(MatteTheme.Typography.largeTitle)
                .foregroundColor(MatteTheme.Colors.textPrimary)
            Text("Manage store managers, policies & audit trails")
                .font(MatteTheme.Typography.caption)
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    // MARK: - Section Card Builder

    @ViewBuilder
    private func governanceSectionCard<Content: View>(
        section: GovernanceSection,
        icon: String,
        badge: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header (tap to expand/collapse)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedSection = expandedSection == section ? nil : section
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                        .frame(width: 38, height: 38)
                        .background(MatteTheme.Colors.luxuryGold.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(section.rawValue)
                        .font(MatteTheme.Typography.headline)
                        .foregroundColor(MatteTheme.Colors.textPrimary)

                    Spacer()

                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MatteTheme.Colors.luxuryGold.opacity(0.12))
                        .cornerRadius(8)

                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
                .padding(MatteTheme.Spacing.cardPadding)
            }
            .buttonStyle(.plain)

            // Content
            if expandedSection == section {
                Divider()
                    .padding(.horizontal, MatteTheme.Spacing.cardPadding)

                content()
                    .padding(MatteTheme.Spacing.cardPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.large))
    }

    // MARK: - Store Managers Content

    @ViewBuilder
    private var storeManagersContent: some View {
        VStack(spacing: 14) {
            // Search Bar
            HStack(spacing: MatteTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(MatteTheme.Colors.textTertiary)
                TextField("Search users by name, email, store…", text: $userSearchText)
                    .font(MatteTheme.Typography.subheadline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                if !userSearchText.isEmpty {
                    Button { userSearchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(MatteTheme.Colors.dashboardBackground)
            .cornerRadius(12)

            // Role Filter
            HStack(spacing: 8) {
                roleFilterChip(title: "All", role: nil)
                roleFilterChip(title: "Managers", role: .boutiqueManager)
                roleFilterChip(title: "Inventory", role: .inventoryController)
                Spacer()
            }

            // Create User Card
            createUserCard

            // User List
            let managers = filteredUsers.filter { $0.role == .boutiqueManager }
            let controllers = filteredUsers.filter { $0.role == .inventoryController }

            if !managers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BOUTIQUE MANAGERS")
                        .font(.caption.weight(.bold))
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                        .kerning(1)

                    ForEach(managers) { user in
                        userRowWith2FAActions(user: user)
                    }
                }
            }

            if !controllers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("INVENTORY CONTROLLERS")
                        .font(.caption.weight(.bold))
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                        .kerning(1)

                    ForEach(controllers) { user in
                        userRowWith2FAActions(user: user)
                    }
                }
            }

            if managers.isEmpty && controllers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.slash")
                        .font(.title2)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("No users found matching your criteria.")
                        .font(MatteTheme.Typography.subheadline)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
    }

    private func roleFilterChip(title: String, role: UserRole?) -> some View {
        let isSelected = selectedRoleFilter == role
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRoleFilter = role
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? MatteTheme.Colors.surface : MatteTheme.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? MatteTheme.Colors.deepBlack : MatteTheme.Colors.subtleAccent)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create User Card

    private var createUserCard: some View {
        VStack(alignment: .leading, spacing: MatteTheme.Spacing.md) {
            HStack(spacing: MatteTheme.Spacing.sm) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                Text("Create User")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }

            HStack(spacing: MatteTheme.Spacing.sm) {
                TextField("First Name", text: $newFirstName)
                    .matteFieldStyle()
                TextField("Last Name", text: $newLastName)
                    .matteFieldStyle()
            }
            TextField("Email", text: $newUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .matteFieldStyle()
            TextField("Phone Number", text: $newPhoneNumber)
                .keyboardType(.phonePad)
                .matteFieldStyle()
            SecureField("Password", text: $newPassword)
                .matteFieldStyle()

            if newRole != .corporateAdmin {
                Picker("Store", selection: $newStoreID) {
                    Text("Select a Store").tag(UUID?(nil))
                    ForEach(authManager.availableSupabaseStores) { store in
                        Text("\(store.name) (\(store.location ?? "Unknown"))").tag(UUID?(store.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(MatteTheme.Colors.accent)
            }

            Picker("Role", selection: $newRole) {
                ForEach(creatableRoles) { role in
                    Text(role.rawValue).tag(role)
                }
            }
            .pickerStyle(.menu)
            .tint(MatteTheme.Colors.accent)

            LiquidGlassButton(title: "Create Account", action: createUser)

            if let statusMessage {
                Text(statusMessage)
                    .font(MatteTheme.Typography.footnote)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
        }
        .padding(16)
        .background(MatteTheme.Colors.dashboardBackground)
        .cornerRadius(16)
    }

    // MARK: - User Row with 2FA Actions

    private func userRowWith2FAActions(user: ManagedUser) -> some View {
        HStack(spacing: MatteTheme.Spacing.sm) {
            userRow(user: user)
            Spacer(minLength: MatteTheme.Spacing.xs)

            Button {
                pending2FAUser = user
                show2FAForEdit = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MatteTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background(MatteTheme.Colors.accent.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                pending2FAUser = user
                show2FAForDelete = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MatteTheme.Colors.error)
                    .frame(width: 38, height: 38)
                    .background(MatteTheme.Colors.error.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func userRow(user: ManagedUser) -> some View {
        HStack(spacing: MatteTheme.Spacing.md) {
            Circle()
                .fill(MatteTheme.Colors.roleColor(for: user.role).opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: user.role.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MatteTheme.Colors.roleColor(for: user.role))
                )

            VStack(alignment: .leading, spacing: MatteTheme.Spacing.xs) {
                Text(user.displayName.isEmpty ? user.username : user.displayName)
                    .font(MatteTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text("\(user.role.rawValue) — \(user.storeLocation.region.rawValue)")
                    .font(MatteTheme.Typography.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: MatteTheme.Spacing.xs)

            BadgeView(
                text: user.isActive ? "Active" : "Inactive",
                color: user.isActive ? MatteTheme.Colors.success : Color.orange
            )
        }
        .padding(.vertical, MatteTheme.Spacing.xs)
    }

    // MARK: - Company Policies Content

    @ViewBuilder
    private var companyPoliciesContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if authManager.companyPolicies.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("No company policies have been created yet.")
                        .font(MatteTheme.Typography.subheadline)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(authManager.companyPolicies) { policy in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(policy.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(MatteTheme.Colors.textPrimary)
                            Spacer()

                            HStack(spacing: 14) {
                                Button {
                                    editingPolicy = policy
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.subheadline)
                                        .foregroundColor(MatteTheme.Colors.primaryGold)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    policyToDelete = policy
                                    showDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .foregroundColor(MatteTheme.Colors.error)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text(policy.content)
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                            .lineLimit(3)

                        Text("Last updated: \(policy.lastUpdated, style: .date) \(policy.lastUpdated, style: .time)")
                            .font(.system(size: 10))
                            .foregroundColor(MatteTheme.Colors.textTertiary)

                        if policy.id != authManager.companyPolicies.last?.id {
                            Divider().padding(.top, 6)
                        }
                    }
                }
            }

            Button {
                isAddingPolicy = true
            } label: {
                Label("Add Policy", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.surface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(MatteTheme.Colors.deepBlack)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: - Audit Logs Content

    @ViewBuilder
    private var auditLogsContent: some View {
        VStack(spacing: 14) {
            // Search & Filter
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                        .font(.caption)
                    TextField("Search logs…", text: $auditSearchText)
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
                .padding(10)
                .background(MatteTheme.Colors.dashboardBackground)
                .cornerRadius(10)

                Menu {
                    Button("All Actions") { auditFilterAction = nil }
                    Button("Create") { auditFilterAction = .create }
                    Button("Update") { auditFilterAction = .update }
                    Button("Delete") { auditFilterAction = .delete }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(auditFilterAction?.rawValue ?? "Filter")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(MatteTheme.Colors.dashboardBackground)
                    .cornerRadius(10)
                }
            }

            let logs = filteredAuditLogs
            if logs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("No audit entries found.")
                        .font(MatteTheme.Typography.subheadline)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(Array(logs.prefix(15))) { log in
                    HStack(spacing: 12) {
                        Image(systemName: auditIcon(for: log.action))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(auditColor(for: log.action))
                            .frame(width: 30, height: 30)
                            .background(auditColor(for: log.action).opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(log.action.rawValue)
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(auditColor(for: log.action))
                                Text("—")
                                    .font(.caption)
                                    .foregroundColor(MatteTheme.Colors.textTertiary)
                                Text(log.tableName)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(MatteTheme.Colors.textPrimary)
                            }
                            Text(log.modifiedAt, style: .relative)
                                .font(.system(size: 10))
                                .foregroundColor(MatteTheme.Colors.textTertiary)
                        }

                        Spacer()

                        Circle()
                            .fill(auditColor(for: log.action))
                            .frame(width: 6, height: 6)
                    }
                    .padding(.vertical, 3)

                    if log.id != logs.prefix(15).last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func auditIcon(for action: AuditAction) -> String {
        switch action {
        case .create: return "plus.circle.fill"
        case .update: return "pencil.circle.fill"
        case .delete: return "trash.circle.fill"
        }
    }

    private func auditColor(for action: AuditAction) -> Color {
        switch action {
        case .create: return MatteTheme.Colors.success
        case .update: return MatteTheme.Colors.primaryGold
        case .delete: return MatteTheme.Colors.error
        }
    }

    private func createUser() {
        let request = NewUserRequest(
            username: newUsername,
            password: newPassword,
            displayName: "\(newFirstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(newLastName.trimmingCharacters(in: .whitespacesAndNewlines))".trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: newPhoneNumber,
            role: newRole,
            storeID: newStoreID
        )
        Task {
            do {
                try await authManager.createUser(request)
                await MainActor.run {
                    newUsername = ""
                    newPassword = ""
                    newFirstName = ""
                    newLastName = ""
                    newPhoneNumber = ""
                    newStoreID = nil
                    statusMessage = "Account created successfully."
                }
            } catch {
                await MainActor.run {
                    statusMessage = error.localizedDescription
                }
            }
        }
    }

    private func deleteUser(_ user: ManagedUser) {
        Task {
            do {
                let removedUser = try await authManager.deleteManagedUser(id: user.id)
                await MainActor.run {
                    userAssignmentNotice = replacementNotice(for: removedUser)
                }
            } catch {
                await MainActor.run {
                    userAssignmentNotice = UserAssignmentNotice(
                        title: "Delete Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func showNoticeAfterEditing(original: ManagedUser, updated: ManagedUser) {
        let changedAssignment = original.assignedStoreID != updated.assignedStoreID
        let changedRole = original.role != updated.role
        let deactivated = original.isActive && !updated.isActive
        guard changedAssignment || changedRole || deactivated else { return }
        userAssignmentNotice = replacementNotice(for: original)
    }

    private func replacementNotice(for user: ManagedUser) -> UserAssignmentNotice? {
        let replacementRole: String
        switch user.role {
        case .boutiqueManager:
            replacementRole = "Boutique Manager"
        case .inventoryController:
            replacementRole = "Inventory Controller"
        case .corporateAdmin, .salesAssociate:
            return nil
        }
        let person = user.displayName.isEmpty ? user.username : user.displayName
        return UserAssignmentNotice(
            title: "Store Assignment Needed",
            message: "\(person) was related to \(user.storeLocation.name), \(user.storeLocation.region.rawValue). This store will need a new \(replacementRole) now."
        )
    }
}
