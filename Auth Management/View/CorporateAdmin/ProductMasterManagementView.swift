import SwiftUI

struct ProductMasterManagementView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    // Search and filter state
    @State private var searchText = ""
    @State private var selectedCategoryID: UUID? = nil // nil means "All"
    
    // Sheets and Modals
    @State private var productToEdit: ProductMasterRecord? = nil
    @State private var showProductEditor = false
    @State private var productToDelete: ProductMasterRecord? = nil
    @State private var show2FADelete = false
    @State private var showProductDetails: ProductMasterRecord? = nil
    
    // iOS 26 Layout Grid
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MatteTheme.Colors.dashboardBackground
                    .ignoresSafeArea()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Search Bar
                        searchBar
                            .padding(.horizontal, 16)
                        
                        // Category Filters
                        categoryFilterScrollView
                        
                        // Product Grid
                        if filteredProducts.isEmpty {
                            emptyStateView
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredProducts) { product in
                                    ProductGlassCard(product: product, onSelect: {
                                        showProductDetails = product
                                    }, onEdit: {
                                        productToEdit = product
                                        showProductEditor = true
                                    }, onDelete: {
                                        productToDelete = product
                                        show2FADelete = true
                                    }, onDuplicate: {
                                        duplicateProduct(product)
                                    }, onArchive: {
                                        archiveProduct(product)
                                    })
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: filteredProducts)
                        }
                        
                        Spacer(minLength: 80) // Space for floating button
                    }
                    .padding(.top, 16)
                }
                
                // Floating Add Button
                floatingAddButton
            }
            .navigationTitle("Product Master")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Reports")
                        }
                        .foregroundColor(MatteTheme.Colors.espresso)
                    }
                }
            }
            // Navigation link logic to show details page
            .navigationDestination(item: $showProductDetails) { product in
                ProductMasterDetailView(product: product)
                    .environmentObject(authManager)
            }
            // Sheets for editor and 2FA
            .sheet(isPresented: $showProductEditor) {
                ProductMasterEditorView(product: productToEdit) { savedProduct in
                    if productToEdit != nil {
                        authManager.updateProductMasterRecord(savedProduct)
                    } else {
                        authManager.addProductMasterRecord(savedProduct)
                    }
                    showProductEditor = false
                }
                .environmentObject(authManager)
            }
            .sheet(isPresented: $show2FADelete) {
                if let product = productToDelete {
                    TwoFactorVerificationSheet(
                        title: "Confirm Deletion",
                        subtitle: "Deletes '\(product.name)' master catalog SKU",
                        onSuccess: {
                            authManager.deleteProductMasterRecord(id: product.id)
                            show2FADelete = false
                            productToDelete = nil
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MatteTheme.Colors.textSecondary)
            
            TextField("Search name, SKU, brand...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(MatteTheme.Colors.textPrimary)
                .font(.subheadline)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .background(MatteTheme.Colors.fogGlass)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MatteTheme.Colors.border.opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - Category Filters
    
    private var categoryFilterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" filter pill
                filterPill(title: "All", isSelected: selectedCategoryID == nil) {
                    withAnimation { selectedCategoryID = nil }
                }
                
                ForEach(authManager.itemCategories) { category in
                    filterPill(title: category.name, isSelected: selectedCategoryID == category.id) {
                        withAnimation { selectedCategoryID = category.id }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? MatteTheme.Colors.espresso : MatteTheme.Colors.fogGlass)
                .foregroundColor(isSelected ? MatteTheme.Colors.ivoryMatte : MatteTheme.Colors.textSecondary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : MatteTheme.Colors.border.opacity(0.8), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Floating Add Button
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    productToEdit = nil
                    showProductEditor = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.ivoryMatte)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [MatteTheme.Colors.primaryGold, MatteTheme.Colors.primaryGold.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: MatteTheme.Colors.primaryGold.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 50))
                .foregroundColor(MatteTheme.Colors.textTertiary)
                .padding(.top, 40)
            Text("No Products Found")
                .font(.headline)
                .foregroundColor(MatteTheme.Colors.textPrimary)
            Text("Try modifying your search text or category selection.")
                .font(.caption)
                .foregroundColor(MatteTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Filter Logic
    
    private var filteredProducts: [ProductMasterRecord] {
        authManager.productMasterRecords.filter { product in
            // Category check
            if let catID = selectedCategoryID, product.categoryID != catID {
                return false
            }
            // Skip archived ones
            if product.isArchived {
                return false
            }
            // Search text check
            if !searchText.isEmpty {
                let term = searchText.lowercased()
                let nameMatch = product.name.lowercased().contains(term)
                let skuMatch = product.sku.lowercased().contains(term)
                let brandMatch = product.brand.lowercased().contains(term)
                let descMatch = product.description?.lowercased().contains(term) ?? false
                return nameMatch || skuMatch || brandMatch || descMatch
            }
            
            return true
        }
    }
    
    // MARK: - Actions
    
    private func duplicateProduct(_ product: ProductMasterRecord) {
        let copy = ProductMasterRecord(
            name: "\(product.name) (Copy)",
            description: product.description,
            categoryID: product.categoryID,
            sku: "\(product.sku)-COPY",
            authenticitySettings: product.authenticitySettings,
            brand: product.brand,
            price: product.price,
            costPrice: product.costPrice,
            tax: product.tax,
            barcode: product.barcode + "9",
            isActive: product.isActive,
            isArchived: false
        )
        authManager.addProductMasterRecord(copy)
    }
    
    private func archiveProduct(_ product: ProductMasterRecord) {
        var updated = product
        updated.isArchived = true
        authManager.updateProductMasterRecord(updated)
    }
}

// MARK: - Product Glass Card

struct ProductGlassCard: View {
    let product: ProductMasterRecord
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onArchive: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Image Box with Glass Monogram
            ZStack {
                // Monogram background gradient
                LinearGradient(
                    colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(12)
                
                // Visual indicators/SF Symbols
                VStack {
                    Image(systemName: categoryIcon)
                        .font(.title)
                        .foregroundColor(categoryColor)
                        .shadow(color: categoryColor.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Text(product.brand.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MatteTheme.Colors.textPrimary.opacity(0.7))
                        .kerning(1.2)
                        .padding(.top, 4)
                }
                
                // Overflow Menu button (•••) top right
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button(action: onSelect) {
                                Label("View Details", systemImage: "info.circle")
                            }
                            Button(action: onEdit) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(action: onDuplicate) {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            Button(action: onArchive) {
                                Label("Archive", systemImage: "archivebox")
                            }
                            Divider()
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                .padding(8)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(height: 120)
            
            // Product info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Status Badge
                    BadgeView(
                        text: product.isActive ? "Active" : "Inactive",
                        color: product.isActive ? MatteTheme.Colors.success : MatteTheme.Colors.textTertiary
                    )
                    Spacer()
                    Text(product.sku)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
                
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(formattedPrice)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(MatteTheme.Colors.primaryGold)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
        .background(MatteTheme.Colors.fogGlass)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(MatteTheme.Colors.border.opacity(0.8), lineWidth: 1)
        )
        .onTapGesture(perform: onSelect)
    }
    
    // MARK: - Display Helper Properties
    
    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: product.price)) ?? "₹\(Int(product.price))"
    }
    
    private var categoryIcon: String {
        switch product.sku.prefix(2) {
        case "HB": return "handbag"
        case "WT": return "clock"
        case "FR": return "sparkles"
        case "FW": return "shoe"
        default: return "shippingbox"
        }
    }
    
    private var categoryColor: Color {
        switch product.sku.prefix(2) {
        case "HB": return MatteTheme.Colors.primaryGold
        case "WT": return MatteTheme.Colors.info
        case "FR": return MatteTheme.Colors.warning
        case "FW": return MatteTheme.Colors.success
        default: return MatteTheme.Colors.textSecondary
        }
    }
}
