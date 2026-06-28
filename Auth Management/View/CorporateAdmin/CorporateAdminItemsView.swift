import SwiftUI

// MARK: - Corporate Admin Items View

/// The Items tab for Corporate Admin.
/// 2FA is required to **view** categories, SKU & authenticity settings,
/// and again for every create / edit / delete action.
struct CorporateAdminItemsView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    // Session-level 2FA gate for viewing
    @State private var is2FAVerified = false

    // Product editor state
    @State private var showProductEditor = false
    @State private var productToEdit: ProductMasterRecord?

    // Per-action 2FA
    @State private var show2FAAction = false
    @State private var pendingAction: (() -> Void)?

    // Category creator
    @State private var showCategoryCreator = false
    @State private var newCategoryName = ""
    @State private var newCategoryDescription = ""

    var body: some View {
        Group {
            if is2FAVerified {
                itemsContent
            } else {
                twoFAGate
            }
        }
    }

    // MARK: - 2FA Gate (blocks viewing)

    private var twoFAGate: some View {
        NavigationStack {
            TwoFactorAuthView {
                withAnimation { is2FAVerified = true }
            }
            .navigationTitle("Master Items")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Main Items Content

    private var itemsContent: some View {
        NavigationStack {
            List {
                // Categories with their products
                ForEach(authManager.itemCategories) { category in
                    Section {
                        categoryHeader(category)

                        let products = authManager.productMasterRecords
                            .filter { $0.categoryID == category.id }

                        if products.isEmpty {
                            Text("No products registered.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(products) { product in
                                NavigationLink(destination: ProductDetailView(product: product, category: category, onEdit: {
                                    require2FA {
                                        productToEdit = product
                                        showProductEditor = true
                                    }
                                }, onDelete: {
                                    require2FA {
                                        authManager.deleteProductMasterRecord(id: product.id)
                                    }
                                })) {
                                    productRow(product)
                                }
                            }
                        }
                    }
                }

                // Uncategorized
                let uncategorized = authManager.productMasterRecords.filter { $0.categoryID == nil }
                if !uncategorized.isEmpty {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "questionmark.folder.fill")
                                .foregroundColor(MatteTheme.Colors.textTertiary)
                            Text("Uncategorized")
                                .font(.headline)
                        }
                        ForEach(uncategorized) { product in
                            NavigationLink(destination: ProductDetailView(product: product, category: nil, onEdit: {
                                require2FA {
                                    productToEdit = product
                                    showProductEditor = true
                                }
                            }, onDelete: {
                                require2FA {
                                    authManager.deleteProductMasterRecord(id: product.id)
                                }
                            })) {
                                productRow(product)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Master Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            require2FA {
                                productToEdit = nil
                                showProductEditor = true
                            }
                        } label: {
                            Label("New Product", systemImage: "shippingbox")
                        }
                        Button {
                            require2FA {
                                newCategoryName = ""
                                newCategoryDescription = ""
                                showCategoryCreator = true
                            }
                        } label: {
                            Label("New Category", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showProductEditor) {
                ProductEditorView(
                    productToEdit: productToEdit,
                    categories: authManager.itemCategories,
                    onSave: { newProduct in
                        if productToEdit != nil {
                            authManager.updateProductMasterRecord(newProduct)
                        } else {
                            authManager.addProductMasterRecord(newProduct)
                        }
                        showProductEditor = false
                    },
                    onCancel: { showProductEditor = false }
                )
            }
            .sheet(isPresented: $show2FAAction) {
                TwoFactorAuthView {
                    show2FAAction = false
                    pendingAction?()
                    pendingAction = nil
                }
            }
            .sheet(isPresented: $showCategoryCreator) {
                NavigationStack {
                    Form {
                        Section(header: Text("Category Details")) {
                            TextField("Category Name", text: $newCategoryName)
                            TextField("Description (optional)", text: $newCategoryDescription)
                        }
                    }
                    .navigationTitle("New Category")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showCategoryCreator = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                let desc = newCategoryDescription.isEmpty ? nil : newCategoryDescription
                                authManager.addCategory(name: newCategoryName, description: desc)
                                showCategoryCreator = false
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Header

    private func categoryHeader(_ category: Category) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconForCategory(category.name))
                .font(.title3)
                .foregroundColor(MatteTheme.Colors.primaryGold)
                .frame(width: 36, height: 36)
                .background(MatteTheme.Colors.primaryGold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                if let desc = category.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                }
            }
            Spacer()
            let count = authManager.productMasterRecords.filter { $0.categoryID == category.id }.count
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundColor(MatteTheme.Colors.primaryGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MatteTheme.Colors.primaryGold.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    // MARK: - Product Row (list cell)

    private func productRow(_ product: ProductMasterRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: "barcode")
                    .font(.caption2)
                Text(product.sku)
                    .font(.caption.monospaced())
            }
            .foregroundColor(MatteTheme.Colors.textSecondary)

            HStack(spacing: 12) {
                if product.authenticitySettings.isNFCEnabled {
                    Label("NFC", systemImage: "wave.3.right.circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(MatteTheme.Colors.primaryGold)
                }
                if product.authenticitySettings.requiresCertificate {
                    Label("Certificate", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(MatteTheme.Colors.success)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func require2FA(action: @escaping () -> Void) {
        pendingAction = action
        show2FAAction = true
    }

    private func iconForCategory(_ name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("handbag"):  return "bag.fill"
        case let n where n.contains("watch"):    return "clock.fill"
        case let n where n.contains("fragrance"), let n where n.contains("perfume"): return "drop.fill"
        case let n where n.contains("footwear"), let n where n.contains("shoe"):     return "shoe.fill"
        default: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Product Detail View (SKU & Authenticity deep-dive)

struct ProductDetailView: View {
    let product: ProductMasterRecord
    let category: Category?
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        List {
            // Product Info
            Section(header: Text("Product Information")) {
                detailRow(icon: "tag.fill", label: "Name", value: product.name)
                if let desc = product.description {
                    detailRow(icon: "text.alignleft", label: "Description", value: desc)
                }
                if let cat = category {
                    detailRow(icon: "folder.fill", label: "Category", value: cat.name)
                }
            }

            // SKU
            Section(header: Text("SKU Details")) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                        .foregroundColor(MatteTheme.Colors.primaryGold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stock Keeping Unit")
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Text(product.sku)
                            .font(.title3.weight(.semibold).monospaced())
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                    }
                }
                .padding(.vertical, 4)

                detailRow(icon: "calendar", label: "Registered", value: product.createdAt.formatted(date: .abbreviated, time: .shortened))
                detailRow(icon: "arrow.triangle.2.circlepath", label: "Last Updated", value: product.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            // Authenticity Settings
            Section(header: Text("Authenticity Settings")) {
                HStack {
                    Image(systemName: "wave.3.right.circle.fill")
                        .foregroundColor(product.authenticitySettings.isNFCEnabled ? MatteTheme.Colors.primaryGold : MatteTheme.Colors.textTertiary)
                    Text("NFC Authentication")
                        .font(.subheadline)
                    Spacer()
                    Text(product.authenticitySettings.isNFCEnabled ? "Enabled" : "Disabled")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(product.authenticitySettings.isNFCEnabled ? MatteTheme.Colors.success : MatteTheme.Colors.textTertiary)
                }

                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(product.authenticitySettings.requiresCertificate ? MatteTheme.Colors.success : MatteTheme.Colors.textTertiary)
                    Text("Certificate Required")
                        .font(.subheadline)
                    Spacer()
                    Text(product.authenticitySettings.requiresCertificate ? "Yes" : "No")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(product.authenticitySettings.requiresCertificate ? MatteTheme.Colors.success : MatteTheme.Colors.textTertiary)
                }

                if let notes = product.authenticitySettings.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                    }
                    .padding(.vertical, 2)
                }
            }

            // Actions
            Section {
                Button {
                    onEdit()
                } label: {
                    Label("Edit Product", systemImage: "pencil.circle.fill")
                        .foregroundColor(MatteTheme.Colors.espresso)
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Product", systemImage: "trash.circle.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(MatteTheme.Colors.primaryGold)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }
        }
        .padding(.vertical, 2)
    }
}
