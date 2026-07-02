import SwiftUI

// MARK: - Master Catalog View (Tab 2)

/// Tab 2 — Product Master, Categories, SKU Management, Authenticity, Regional Pricing & Tax Rules.
/// Replaces the original CorporateAdminItemsView with an enhanced 5-module hub.
struct MasterCatalogView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false

    // Grid columns
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    // View state for modal views
    @State private var showCategories = false
    @State private var showAuthenticity = false
    @State private var showSKUManagement = false

    // Company Policy states (removed — now in Governance tab)

    // Categories: Add/Edit/Delete
    @State private var showAddCategory = false
    @State private var editingCategory: Category? = nil
    @State private var categoryToDelete: Category? = nil
    @State private var showDeleteCategoryConfirmation = false
    @State private var showCategoryProductEditor = false
    @State private var categoryForNewProduct: Category? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                MatteTheme.Colors.dashboardBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Master Catalog")
                                .font(MatteTheme.Typography.largeTitle)
                                .foregroundColor(MatteTheme.Colors.textPrimary)
                            Text("Product management, categories & pricing hub")
                                .font(MatteTheme.Typography.caption)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, 4)

                        // Stats Summary Bar
                        catalogStatsBar

                        // 5-Card Grid
                        LazyVGrid(columns: columns, spacing: 14) {
                            // 1. Product Master Records
                            NavigationLink(destination: ProductMasterManagementView().environmentObject(authManager)) {
                                catalogHubCard(
                                    title: "Product Master",
                                    subtitle: "Create, edit & manage catalog",
                                    icon: "shippingbox.fill",
                                    badgeText: "\(authManager.productMasterRecords.count) SKUs",
                                    badgeColor: MatteTheme.Colors.luxuryGold,
                                    accentColor: MatteTheme.Colors.luxuryGold
                                )
                            }
                            .buttonStyle(.plain)

                            // 2. Categories
                            Button { showCategories = true } label: {
                                catalogHubCard(
                                    title: "Categories",
                                    subtitle: "Manage collections & products",
                                    icon: "folder.fill",
                                    badgeText: "\(authManager.itemCategories.count) Groups",
                                    badgeColor: MatteTheme.Colors.info,
                                    accentColor: MatteTheme.Colors.info
                                )
                            }
                            .buttonStyle(.plain)

                            // 3. SKU Management
                            Button { showSKUManagement = true } label: {
                                catalogHubCard(
                                    title: "SKU Management",
                                    subtitle: "Barcodes, codes & tracking",
                                    icon: "barcode.viewfinder",
                                    badgeText: "\(authManager.productMasterRecords.count)",
                                    badgeColor: MatteTheme.Colors.accent,
                                    accentColor: MatteTheme.Colors.accent
                                )
                            }
                            .buttonStyle(.plain)

                            // 4. Authenticity (RFID / NFC / Serialisation)
                            Button { showAuthenticity = true } label: {
                                catalogHubCard(
                                    title: "Authenticity",
                                    subtitle: "RFID, NFC & certificates",
                                    icon: "checkmark.shield.fill",
                                    badgeText: "Verify",
                                    badgeColor: MatteTheme.Colors.success,
                                    accentColor: MatteTheme.Colors.success
                                )
                            }
                            .buttonStyle(.plain)

                            // 5. Regional Pricing & Tax Rules (spans full width)
                            NavigationLink(destination: PricingRulesView().environmentObject(authManager)) {
                                catalogHubCard(
                                    title: "Pricing Rules",
                                    subtitle: "Edit pricing with tax mapping",
                                    icon: "indianrupeesign.circle.fill",
                                    badgeText: "Edit",
                                    badgeColor: MatteTheme.Colors.luxuryGold,
                                    accentColor: MatteTheme.Colors.luxuryGold
                                )
                            }
                            .buttonStyle(.plain)

                            // 6. Regional Tax Rules
                            NavigationLink(destination: RegionalTaxRulesView().environmentObject(authManager)) {
                                catalogHubCard(
                                    title: "Regional Tax Rules",
                                    subtitle: "Define regional tax codes",
                                    icon: "globe",
                                    badgeText: "Configure",
                                    badgeColor: MatteTheme.Colors.info,
                                    accentColor: MatteTheme.Colors.info
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, MatteTheme.Spacing.horizontalMargin)
                    .padding(.top, 18)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .profileToolbar(showProfile: $showProfile)
            // Modal Sheets
            .sheet(isPresented: $showCategories) { categoriesSheet }
            .sheet(isPresented: $showAuthenticity) { authenticitySheet }
            .sheet(isPresented: $showSKUManagement) { skuManagementSheet }
            .task {
                await authManager.fetchProductMasterRecords()
                await authManager.fetchCategories()
            }
        }
    }

    // MARK: - Stats Summary Bar

    private var catalogStatsBar: some View {
        HStack(spacing: 0) {
            catalogStatItem(
                value: "\(authManager.productMasterRecords.count)",
                label: "Total SKUs",
                color: MatteTheme.Colors.luxuryGold
            )
            Divider().frame(height: 36)
            catalogStatItem(
                value: "\(authManager.productMasterRecords.filter { $0.isActive }.count)",
                label: "Active",
                color: MatteTheme.Colors.success
            )
            Divider().frame(height: 36)
            catalogStatItem(
                value: "\(authManager.itemCategories.count)",
                label: "Categories",
                color: MatteTheme.Colors.info
            )
            Divider().frame(height: 36)
            catalogStatItem(
                value: "\(authManager.productMasterRecords.filter { $0.authenticitySettings.isNFCEnabled }.count)",
                label: "NFC Enabled",
                color: MatteTheme.Colors.accent
            )
        }
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.large))
    }

    private func catalogStatItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hub Card

    private func catalogHubCard(title: String, subtitle: String, icon: String, badgeText: String, badgeColor: Color, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 38, height: 38)
                    .background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                Text(badgeText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.12))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(MatteTheme.Colors.textTertiary)
            }
        }
        .padding(16)
        .frame(height: 150)
        .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.xlarge))
    }

    // MARK: - Categories Sheet

    private func productsForCategory(_ category: Category) -> [ProductMasterRecord] {
        authManager.productMasterRecords.filter {
            $0.category.localizedCaseInsensitiveCompare(category.name) == .orderedSame
        }
    }

    private var categoriesSheet: some View {
        NavigationStack {
            ZStack {
                MatteTheme.Colors.dashboardBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(authManager.itemCategories) { cat in
                            let catProducts = productsForCategory(cat)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                                    Text(cat.name)
                                        .font(.headline)
                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                    Spacer()
                                    Text("\(catProducts.count) items")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(MatteTheme.Colors.textTertiary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(MatteTheme.Colors.subtleAccent)
                                        .cornerRadius(8)

                                    Menu {
                                        Button {
                                            categoryForNewProduct = cat
                                            showCategoryProductEditor = true
                                        } label: {
                                            Label("Add Product", systemImage: "plus")
                                        }
                                        Button {
                                            editingCategory = cat
                                        } label: {
                                            Label("Edit Category", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            categoryToDelete = cat
                                            showDeleteCategoryConfirmation = true
                                        } label: {
                                            Label("Delete Category", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.title3)
                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                    }
                                }

                                if let desc = cat.description {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                }

                                if catProducts.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("No products in this category yet.")
                                            .font(.caption)
                                            .foregroundColor(MatteTheme.Colors.textTertiary)
                                        Button {
                                            categoryForNewProduct = cat
                                            showCategoryProductEditor = true
                                        } label: {
                                            Label("Add Product to \(cat.name)", systemImage: "plus.circle.fill")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    ForEach(catProducts) { product in
                                        HStack(spacing: 10) {
                                            Image(systemName: "shippingbox")
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(product.name)
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundColor(MatteTheme.Colors.textPrimary)
                                                Text(product.sku)
                                                    .font(.system(size: 10).monospaced())
                                                    .foregroundColor(MatteTheme.Colors.textTertiary)
                                            }
                                            Spacer()
                                            Text("₹\(Int(product.price))")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                        }
                                        .padding(.vertical, 4)
                                        if product.id != catProducts.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .liquidGlassCard()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 96)
                }

                // Floating Add Category Button
                VStack {
                    Spacer()
                    Button {
                        showAddCategory = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.headline.weight(.bold))
                            Text("Add Category")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(MatteTheme.Colors.deepBlack)
                        .cornerRadius(28)
                        .shadow(color: MatteTheme.Colors.deepBlack.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCategories = false }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddCategory) {
                categoryEditorSheet(category: nil)
            }
            .sheet(item: $editingCategory) { category in
                categoryEditorSheet(category: category)
            }
            .sheet(isPresented: $showCategoryProductEditor, onDismiss: {
                categoryForNewProduct = nil
            }) {
                ProductMasterEditorView(
                    preselectedCategory: categoryForNewProduct?.name
                ) { savedProduct in
                    authManager.addProductMasterRecord(savedProduct)
                    categoryForNewProduct = nil
                }
                .environmentObject(authManager)
            }
            .alert("Delete Category", isPresented: $showDeleteCategoryConfirmation, presenting: categoryToDelete) { category in
                Button("Delete", role: .destructive) {
                    authManager.deleteCategory(id: category.id)
                    categoryToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    categoryToDelete = nil
                }
            } message: { category in
                Text("Products in '\(category.name)' will become uncategorized.")
            }
        }
    }

    @ViewBuilder
    private func categoryEditorSheet(category: Category?) -> some View {
        CatalogCategoryEditorSheet(
            category: category,
            onCancel: {
                showAddCategory = false
                editingCategory = nil
            },
            onSave: { name, description in
                if let category {
                    var updated = category
                    updated.name = name
                    updated.description = description
                    authManager.updateCategory(updated)
                    editingCategory = nil
                } else {
                    authManager.addCategory(name: name, description: description)
                    showAddCategory = false
                }
            }
        )
    }

    // MARK: - SKU Management Sheet

    private var skuManagementSheet: some View {
        NavigationStack {
            ZStack {
                MatteTheme.Colors.dashboardBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if authManager.productMasterRecords.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 48))
                                    .foregroundColor(MatteTheme.Colors.textTertiary)
                                Text("No SKUs registered in the master catalog.")
                                    .font(.subheadline)
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(authManager.productMasterRecords) { product in
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(MatteTheme.Colors.textPrimary)
                                        Text(product.sku)
                                            .font(.system(size: 12).monospaced())
                                            .foregroundColor(MatteTheme.Colors.luxuryGold)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        if !product.barcode.isEmpty {
                                            HStack(spacing: 4) {
                                                Image(systemName: "barcode")
                                                    .font(.caption2)
                                                Text(product.barcode)
                                                    .font(.system(size: 10).monospaced())
                                            }
                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                        }

                                        Text(product.isActive ? "Active" : "Inactive")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(product.isActive ? MatteTheme.Colors.success : MatteTheme.Colors.error)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background((product.isActive ? MatteTheme.Colors.success : MatteTheme.Colors.error).opacity(0.12))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(14)
                                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle("SKU Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showSKUManagement = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Authenticity Sheet

    private var authenticitySheet: some View {
        NavigationStack {
            ZStack {
                MatteTheme.Colors.dashboardBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if authManager.productMasterRecords.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.shield")
                                    .font(.system(size: 48))
                                    .foregroundColor(MatteTheme.Colors.textTertiary)
                                Text("No products to verify.")
                                    .font(.subheadline)
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(authManager.productMasterRecords) { product in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(product.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(MatteTheme.Colors.textPrimary)
                                        Spacer()
                                        Text(product.sku)
                                            .font(.caption.monospaced())
                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                    }

                                    HStack(spacing: 16) {
                                        authenticityBadge(
                                            icon: "wave.3.right.circle",
                                            label: product.authenticitySettings.isNFCEnabled ? "NFC Enabled" : "NFC Disabled",
                                            isActive: product.authenticitySettings.isNFCEnabled
                                        )

                                        authenticityBadge(
                                            icon: "checkmark.seal",
                                            label: product.authenticitySettings.requiresCertificate ? "Certificate Active" : "No Certificate",
                                            isActive: product.authenticitySettings.requiresCertificate
                                        )
                                    }

                                    if let notes = product.authenticitySettings.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(MatteTheme.Colors.textTertiary)
                                    }
                                }
                                .padding(14)
                                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle("Authenticity Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showAuthenticity = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func authenticityBadge(icon: String, label: String, isActive: Bool) -> some View {
        Label(label, systemImage: icon)
            .font(.caption)
            .foregroundColor(isActive ? MatteTheme.Colors.success : MatteTheme.Colors.textTertiary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((isActive ? MatteTheme.Colors.success : MatteTheme.Colors.textTertiary).opacity(0.10))
            .cornerRadius(8)
    }
}

// MARK: - Category Editor Sheet (private to MasterCatalog)

private struct CatalogCategoryEditorSheet: View {
    let category: Category?
    let onCancel: () -> Void
    let onSave: (String, String?) -> Void

    @State private var name: String
    @State private var description: String

    init(category: Category?, onCancel: @escaping () -> Void, onSave: @escaping (String, String?) -> Void) {
        self.category = category
        self.onCancel = onCancel
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _description = State(initialValue: category?.description ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(category == nil ? "New Category" : "Edit Category")) {
                    TextField("Category Name (e.g. Purses)", text: $name)
                    TextField("Description (optional)", text: $description)
                }
            }
            .navigationTitle(category == nil ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmedName, trimmedDescription.isEmpty ? nil : trimmedDescription)
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
