import SwiftUI

struct ProductMasterManagementView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    @State private var productToEdit: ProductMasterRecord? = nil
    @State private var preselectedCategory: String? = nil
    @State private var showProductEditor = false
    @State private var showProductDetails: ProductMasterRecord? = nil
    @State private var isRefreshing = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var categoryFilters: [String] {
        let fromProducts = Set(authManager.productMasterRecords.map(\.category).filter { !$0.isEmpty })
        let fromLocal = Set(authManager.itemCategories.map(\.name))
        return Array(fromProducts.union(fromLocal)).sorted()
    }

    var body: some View {
        ZStack {
            MatteTheme.Colors.dashboardBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    searchBar
                        .padding(.horizontal, 16)

                    categoryFilterScrollView

                    if isRefreshing && authManager.productMasterRecords.isEmpty {
                        ProgressView("Loading products...")
                            .padding(.top, 40)
                    } else if filteredProducts.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredProducts) { product in
                                ProductGlassCard(product: product) {
                                    showProductDetails = product
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: filteredProducts)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 16)
            }

            floatingAddButton
        }
        .navigationTitle("Product Master")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await refreshProducts()
        }
        .task {
            await refreshProducts()
            await authManager.fetchPricingRules()
        }
        .navigationDestination(item: $showProductDetails) { product in
            ProductMasterDetailView(product: product)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showProductEditor, onDismiss: {
            productToEdit = nil
            preselectedCategory = nil
        }) {
            ProductMasterEditorView(
                product: productToEdit,
                preselectedCategory: preselectedCategory
            ) { savedProduct in
                if productToEdit != nil {
                    authManager.updateProductMasterRecord(savedProduct)
                } else {
                    authManager.addProductMasterRecord(savedProduct)
                }
                selectedCategory = savedProduct.category
                productToEdit = nil
                preselectedCategory = nil
            }
            .environmentObject(authManager)
        }
    }

    private func refreshProducts() async {
        isRefreshing = true
        await authManager.fetchProductMasterRecords()
        isRefreshing = false
    }

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

    private var categoryFilterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterPill(title: "All", isSelected: selectedCategory == nil) {
                    withAnimation { selectedCategory = nil }
                }

                ForEach(categoryFilters, id: \.self) { category in
                    filterPill(title: category, isSelected: selectedCategory == category) {
                        withAnimation { selectedCategory = category }
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

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    productToEdit = nil
                    preselectedCategory = selectedCategory
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

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 50))
                .foregroundColor(MatteTheme.Colors.textTertiary)
                .padding(.top, 40)
            Text("No Products Found")
                .font(.headline)
                .foregroundColor(MatteTheme.Colors.textPrimary)
            Text("No products in the database match your search or filters.")
                .font(.caption)
                .foregroundColor(MatteTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var filteredProducts: [ProductMasterRecord] {
        authManager.productMasterRecords.filter { product in
            if product.isArchived { return false }

            if let selectedCategory,
               product.category.localizedCaseInsensitiveCompare(selectedCategory) != .orderedSame {
                return false
            }

            if !searchText.isEmpty {
                let term = searchText.lowercased()
                return product.name.lowercased().contains(term)
                    || product.sku.lowercased().contains(term)
                    || product.brand.lowercased().contains(term)
                    || product.description?.lowercased().contains(term) == true
            }

            return true
        }
    }
}

struct ProductGlassCard: View {
    let product: ProductMasterRecord
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                if let imageURLString = product.imageURL, let imageURL = URL(string: imageURLString) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(12)
                        case .failure, .empty:
                            fallbackMonogramBox
                        @unknown default:
                            fallbackMonogramBox
                        }
                    }
                } else {
                    fallbackMonogramBox
                }
            }
            .frame(height: 120)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
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
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
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

    private var fallbackMonogramBox: some View {
        ZStack {
            LinearGradient(
                colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(12)

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
        }
    }

    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: product.price)) ?? "₹\(Int(product.price))"
    }

    private var categoryIcon: String {
        switch product.category.lowercased() {
        case "purses", "handbags", "leather goods": return "handbag"
        case "watches": return "clock"
        case "fragrances": return "sparkles"
        case "footwear", "sneakers": return "shoe"
        case "jewelry": return "sparkle"
        case "accessories": return "sunglasses"
        case "ready-to-wear": return "tshirt"
        default: return "shippingbox"
        }
    }

    private var categoryColor: Color {
        switch product.category.lowercased() {
        case "purses", "handbags", "leather goods": return MatteTheme.Colors.primaryGold
        case "watches": return MatteTheme.Colors.info
        case "fragrances": return MatteTheme.Colors.warning
        case "footwear", "sneakers": return MatteTheme.Colors.success
        default: return MatteTheme.Colors.textSecondary
        }
    }
}
