import SwiftUI

// MARK: - Profile Sheet View

/// Shared profile sheet accessible from the top-right toolbar across all roles.
/// Shows profile details and sign out for everyone.
/// Conditionally shows "Create User" for Corporate Admin and Boutique Manager.
struct ProfileSheetView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var newDisplayName = ""
    @State private var newStoreName = ""
    @State private var newRole: UserRole = .boutiqueManager
    @State private var newCountry: Country = .india
    @State private var newRegion: Region = .mumbai
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    profileCard
                    if canCreateUsers {
                        createUserCard
                    }
                    signOutButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MatteTheme.Colors.espresso)
                }
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let user = authManager.currentUser {
                HStack(spacing: 14) {
                    Circle()
                        .fill(MatteTheme.Colors.roleColor(for: user.role).opacity(0.14))
                        .frame(width: 58, height: 58)
                        .overlay(
                            Image(systemName: user.role.icon)
                                .font(.title2.weight(.semibold))
                                .foregroundColor(MatteTheme.Colors.roleColor(for: user.role))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                }

                Divider().background(MatteTheme.Colors.border)

                profileRow(title: "Role", value: user.role.rawValue)
                profileRow(title: "Store", value: user.storeName)
                profileRow(title: "Region", value: "\(user.region.rawValue), \(user.country.rawValue)")
            }
        }
        .padding(20)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }

    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(MatteTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(MatteTheme.Colors.textPrimary)
        }
    }

    // MARK: - Create User Card

    private var createUserCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(MatteTheme.Colors.primaryGold)
                Text("Create User")
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }

            TextField("Display name", text: $newDisplayName)
                .matteFieldStyle()
            TextField("Username", text: $newUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .matteFieldStyle()
            SecureField("Password", text: $newPassword)
                .matteFieldStyle()

            if authManager.currentUser?.role == .corporateAdmin {
                TextField("Store name", text: $newStoreName)
                    .matteFieldStyle()

                Picker("Role", selection: $newRole) {
                    ForEach(creatableRoles) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.menu)
                .tint(MatteTheme.Colors.primaryGold)

                HStack {
                    Picker("Country", selection: $newCountry) {
                        ForEach(Country.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Region", selection: $newRegion) {
                        ForEach(Region.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .tint(MatteTheme.Colors.primaryGold)
            } else {
                // Boutique Manager — role is locked to Sales Associate, store is auto-assigned
                Text("Role: Sales Associate (auto-assigned to your store)")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }

            Button(action: createUser) {
                Label("Create Account", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.ivoryMatte)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MatteTheme.Colors.espresso)
                    .cornerRadius(14)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
        }
        .padding(20)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(action: {
            withAnimation {
                authManager.logout()
                dismiss()
            }
        }) {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline)
                .foregroundColor(MatteTheme.Colors.ivoryMatte)
                .frame(maxWidth: .infinity)
                .padding()
                .background(MatteTheme.Colors.espresso)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(MatteTheme.Colors.primaryGold.opacity(0.22), lineWidth: 1)
                )
        }
    }

    // MARK: - Helpers

    private var canCreateUsers: Bool {
        guard let role = authManager.currentUser?.role else { return false }
        return role == .corporateAdmin || role == .boutiqueManager
    }

    private var creatableRoles: [UserRole] {
        switch authManager.currentUser?.role {
        case .corporateAdmin:
            return [.boutiqueManager, .inventoryController]
        case .boutiqueManager:
            return [.salesAssociate]
        default:
            return []
        }
    }

    private func createUser() {
        do {
            let role = authManager.currentUser?.role == .boutiqueManager ? UserRole.salesAssociate : newRole

            let storeLocation: StoreLocation
            if authManager.currentUser?.role == .boutiqueManager {
                // Auto-assign to manager's store
                storeLocation = StoreLocation(
                    name: authManager.currentUser?.storeName ?? "Store",
                    country: authManager.currentUser?.country ?? .india,
                    region: authManager.currentUser?.region ?? .mumbai
                )
            } else {
                let name = newStoreName.trimmingCharacters(in: .whitespacesAndNewlines)
                storeLocation = StoreLocation(
                    name: name.isEmpty ? "\(newRegion.rawValue) Boutique" : name,
                    country: newCountry,
                    region: newRegion
                )
            }

            let request = NewUserRequest(
                username: newUsername,
                password: newPassword,
                displayName: newDisplayName,
                role: role,
                storeLocation: storeLocation
            )

            try authManager.createUser(request)

            // Also register in MockLoginBackend
            MockLoginBackend.shared.addCredentials(
                username: newUsername,
                password: newPassword,
                role: role.rawValue
            )

            newUsername = ""
            newPassword = ""
            newDisplayName = ""
            newStoreName = ""
            statusMessage = "Account created successfully."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

// MARK: - Matte Field Style

extension View {
    func matteFieldStyle() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(14)
            .background(MatteTheme.Colors.surface.opacity(0.9))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MatteTheme.Colors.border, lineWidth: 1)
            )
    }
}

// MARK: - Profile Toolbar Modifier

/// Adds the standard top-right profile button to any view.
struct ProfileToolbar: ViewModifier {
    @Binding var showProfile: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .foregroundColor(MatteTheme.Colors.espresso)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileSheetView()
            }
    }
}

extension View {
    func profileToolbar(showProfile: Binding<Bool>) -> some View {
        modifier(ProfileToolbar(showProfile: showProfile))
    }
}
