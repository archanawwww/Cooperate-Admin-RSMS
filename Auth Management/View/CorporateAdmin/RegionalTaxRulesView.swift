import SwiftUI

// MARK: - Regional Tax Rules View (Sprint 1)

/// Displays and manages regional tax configurations per store location.
/// Corporate Admin can create new rules or edit existing tax rates.
struct RegionalTaxRulesView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var editingStore: StoreLocation? = nil
    @State private var editTaxType: TaxType = .gst
    @State private var editTaxName: String = ""
    @State private var editTaxRate: String = ""
    @State private var showEditor = false
    @State private var isCreatingNew = false

    // 2FA
    @State private var show2FA = false
    @State private var pendingAction: (() -> Void)?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(authManager.stores) { store in
                    taxRuleCard(for: store)
                }

                if authManager.stores.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "globe.central.south.asia")
                            .font(.system(size: 48))
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                        Text("No store locations configured.")
                            .font(.subheadline)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
        .navigationTitle("Regional Tax Rules")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showEditor) {
            taxEditorSheet
        }
        .sheet(isPresented: $show2FA) {
            TwoFactorVerificationSheet(
                title: "Verify to Edit",
                subtitle: "2FA required to modify tax rules",
                onSuccess: {
                    pendingAction?()
                    pendingAction = nil
                }
            )
        }
    }

    // MARK: - Tax Rule Card

    private func taxRuleCard(for store: StoreLocation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "building.2.fill")
                    .foregroundColor(MatteTheme.Colors.primaryGold)
                Text(store.name)
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Spacer()
                BadgeView(
                    text: store.region.rawValue,
                    color: MatteTheme.Colors.info
                )
            }

            // Tax config for this store
            let taxConfig = taxConfigForStore(store)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tax Type")
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text(taxConfig.taxType.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }

                Divider().frame(height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tax Name")
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text(taxConfig.taxName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }

                Divider().frame(height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate")
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("\(Int(taxConfig.taxRate * 100))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(MatteTheme.Colors.primaryGold)
                }
            }

            Button {
                require2FA {
                    editingStore = store
                    editTaxType = taxConfig.taxType
                    editTaxName = taxConfig.taxName
                    editTaxRate = String(format: "%.1f", taxConfig.taxRate * 100)
                    isCreatingNew = false
                    showEditor = true
                }
            } label: {
                Label("Edit Tax Rule", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.ivoryMatte)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(MatteTheme.Colors.espresso)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Tax Editor Sheet

    private var taxEditorSheet: some View {
        NavigationStack {
            Form {
                if let store = editingStore {
                    Section(header: Text("Store")) {
                        Text("\(store.name) — \(store.region.rawValue)")
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                }

                Section(header: Text("Tax Configuration")) {
                    Picker("Tax Type", selection: $editTaxType) {
                        ForEach(TaxType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Tax Name (e.g. CGST + SGST)", text: $editTaxName)

                    HStack {
                        TextField("Tax Rate (%)", text: $editTaxRate)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                    }
                }
            }
            .navigationTitle(isCreatingNew ? "New Tax Rule" : "Edit Tax Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showEditor = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTaxRule()
                        showEditor = false
                    }
                    .fontWeight(.semibold)
                    .disabled(editTaxName.isEmpty)
                }
            }
        }
    }

    // MARK: - Helpers

    private func taxConfigForStore(_ store: StoreLocation) -> RegionalTaxConfig {
        // Use a default GST 18% config for India stores
        switch store.region {
        case .mumbai, .pune:
            return RegionalTaxConfig(taxType: .gst, taxName: "CGST + SGST", taxRate: 0.18)
        case .delhi:
            return RegionalTaxConfig(taxType: .gst, taxName: "CGST + SGST", taxRate: 0.18)
        case .bangalore, .chennai, .hyderabad:
            return RegionalTaxConfig(taxType: .gst, taxName: "IGST", taxRate: 0.18)
        case .kolkata:
            return RegionalTaxConfig(taxType: .gst, taxName: "CGST + SGST", taxRate: 0.12)
        case .jaipur:
            return RegionalTaxConfig(taxType: .gst, taxName: "CGST + SGST + Luxury Cess", taxRate: 0.28)
        }
    }

    private func saveTaxRule() {
        // In Sprint 1 this saves locally. Future sprints will persist to Supabase.
        // For now we just dismiss — the data model doesn't yet have per-store persistence for tax configs.
    }

    private func require2FA(action: @escaping () -> Void) {
        pendingAction = action
        show2FA = true
    }
}
