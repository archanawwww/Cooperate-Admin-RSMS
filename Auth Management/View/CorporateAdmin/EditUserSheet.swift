import SwiftUI

struct EditUserSheet: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    let user: ManagedUser

    @State private var displayName: String
    @State private var username: String
    @State private var password = ""
    @State private var storeName: String
    @State private var role: UserRole
    @State private var country: Country
    @State private var region: Region
    @State private var isActive: Bool
    @State private var statusMessage: String?
    @State private var isSuccess = false

    init(user: ManagedUser) {
        self.user = user
        _displayName = State(initialValue: user.displayName)
        _username = State(initialValue: user.username)
        _storeName = State(initialValue: user.storeLocation.name)
        _role = State(initialValue: user.role)
        _country = State(initialValue: user.storeLocation.country)
        _region = State(initialValue: user.storeLocation.region)
        _isActive = State(initialValue: user.isActive)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Details") {
                    TextField("Display Name", text: $displayName)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Password (Leave blank to keep unchanged)") {
                    SecureField("New Password", text: $password)
                }

                Section("Role & Assignment") {
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.menu)

                    if role != .corporateAdmin {
                        TextField("Store Name", text: $storeName)
                    }
                }

                if role != .corporateAdmin {
                    Section("Store Location") {
                        Picker("Country", selection: $country) {
                            ForEach(Country.allCases) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Region", selection: $region) {
                            ForEach(Region.allCases) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Status") {
                    Toggle("Is Active Account", isOn: $isActive)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundColor(isSuccess ? MatteTheme.Colors.success : MatteTheme.Colors.error)
                    }
                }
            }
            .navigationTitle("Edit User")
            .navigationBarTitleDisplayMode(.inline)
            .tint(MatteTheme.Colors.primaryGold)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MatteTheme.Colors.espresso)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(MatteTheme.Colors.primaryGold)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        do {
            let countryValue = role == .corporateAdmin ? Country.india : country
            let regionValue = role == .corporateAdmin ? Region.mumbai : region
            let storeNameValue = role == .corporateAdmin ? "Corporate Headquarters" : storeName.trimmingCharacters(in: .whitespacesAndNewlines)

            let targetStore = StoreLocation(
                name: storeNameValue.isEmpty ? "\(regionValue.rawValue) Boutique" : storeNameValue,
                country: countryValue,
                region: regionValue
            )

            try authManager.updateManagedUser(
                id: user.id,
                displayName: displayName,
                username: username,
                password: password.isEmpty ? nil : password,
                role: role,
                storeLocation: targetStore,
                isActive: isActive
            )

            isSuccess = true
            statusMessage = "User updated successfully."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } catch {
            isSuccess = false
            statusMessage = error.localizedDescription
        }
    }
}
