import SwiftUI

// MARK: - Pricing Rules View (Sprint 1)

/// Displays and manages product master record pricing and tax rules.
/// Allows dynamic editing of prices with tax computations.
struct PricingRulesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var editingProduct: ProductMasterRecord? = nil
    @State private var editPrice: String = ""
    @State private var editCost: String = ""
    @State private var editTax: String = ""
    @State private var showEditor = false
    
    // 2FA
    @State private var show2FA = false
    @State private var pendingAction: (() -> Void)?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(authManager.productMasterRecords) { product in
                    productPriceCard(for: product)
                }
                
                if authManager.productMasterRecords.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "indianrupeesign.circle")
                            .font(.system(size: 48))
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                        Text("No products registered in master catalog.")
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
        .navigationTitle("Pricing Rules")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showEditor) {
            priceEditorSheet
        }
        .sheet(isPresented: $show2FA) {
            TwoFactorVerificationSheet(
                title: "Verify to Modify Pricing",
                subtitle: "2FA required to update catalog pricing rules",
                onSuccess: {
                    pendingAction?()
                    pendingAction = nil
                }
            )
        }
        .task {
            await authManager.fetchProductMasterRecords()
            await authManager.fetchPricingRules()
        }
    }
    
    // MARK: - Product Price Card
    
    private func productPriceCard(for product: ProductMasterRecord) -> some View {
        // Find the matching pricing rule for this product
        let pricing = authManager.pricingRules.first { $0.productID == product.id }
        
        // Use pricing values if available, otherwise fall back to product values
        let costPrice = pricing?.costPrice ?? product.costPrice
        let basePrice = pricing?.basePrice ?? product.price
        let taxRate = pricing?.tax ?? product.tax
        
        // Calculations
        let taxRatePercent = taxRate / 100.0
        let preTax = basePrice / (1.0 + taxRatePercent)
        let taxAmount = basePrice - preTax
        let margin = basePrice > 0 ? ((basePrice - costPrice) / basePrice) * 100.0 : 0.0
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(MatteTheme.Colors.primaryGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                    Text(product.sku)
                        .font(.caption.monospaced())
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                }
                Spacer()
                BadgeView(
                    text: product.brand,
                    color: MatteTheme.Colors.primaryGold
                )
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cost Price")
                        .font(.system(size: 10))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("₹\(Int(costPrice))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
                
                Divider().frame(height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pre-Tax")
                        .font(.system(size: 10))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("₹\(Int(preTax))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
                
                Divider().frame(height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tax (\(Int(taxRate))%)")
                        .font(.system(size: 10))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("₹\(Int(taxAmount))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
                
                Divider().frame(height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Final Price")
                        .font(.system(size: 10))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text("₹\(Int(basePrice))")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(MatteTheme.Colors.espresso)
                }
            }
            
            HStack {
                Text("Estimated Margin:")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                Text(String(format: "%.1f%%", margin))
                    .font(.caption.weight(.bold))
                    .foregroundColor(margin > 20 ? MatteTheme.Colors.success : MatteTheme.Colors.primaryGold)
                
                Spacer()
                
                Button {
                    require2FA {
                        editingProduct = product
                        editPrice = String(format: "%.0f", basePrice)
                        editCost = String(format: "%.0f", costPrice)
                        editTax = String(format: "%.0f", taxRate)
                        showEditor = true
                    }
                } label: {
                    Text("Edit Rules")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.primaryGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(MatteTheme.Colors.primaryGold.opacity(0.12))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
    
    // MARK: - Price Editor Sheet
    
    private var priceEditorSheet: some View {
        NavigationStack {
            Form {
                if let product = editingProduct {
                    Section(header: Text("Product")) {
                        Text(product.name)
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .fontWeight(.medium)
                        Text(product.sku)
                            .font(.caption.monospaced())
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                }
                
                Section(header: Text("Pricing Details (INR)")) {
                    HStack {
                        Text("Cost Price")
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Spacer()
                        TextField("Cost", text: $editCost)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Final Retail Price")
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Spacer()
                        TextField("Price", text: $editPrice)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Regional Tax Assignment")) {
                    HStack {
                        Text("Tax Rate (%)")
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Spacer()
                        TextField("Tax", text: $editTax)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Modify Pricing Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showEditor = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePricingChanges()
                        showEditor = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func savePricingChanges() {
        guard var product = editingProduct else { return }
        
        let priceVal = Double(editPrice) ?? 0
        let costVal = Double(editCost) ?? 0
        let taxVal = Double(editTax) ?? 18
        
        // Update product record
        product.price = priceVal
        product.costPrice = costVal
        product.tax = taxVal
        product.updatedAt = Date()
        
        // Update both Product and Pricing tables in Supabase
        Task {
            do {
                // First update the product
                authManager.updateProductMasterRecord(product)
                
                // Then update or create pricing
                if let existingPricing = authManager.pricingRules.first(where: { $0.productID == product.id }) {
                    let updatedPricing = SupabasePricing(
                        id: existingPricing.id,
                        productID: product.id,
                        costPrice: costVal,
                        basePrice: priceVal,
                        tax: taxVal,
                        isActive: true,
                        createdAt: existingPricing.createdAt,
                        updatedAt: Date()
                    )
                    try await SupabaseAuthService.shared.updatePricing(pricing: updatedPricing)
                } else {
                    let newPricing = SupabasePricing(
                        id: UUID(),
                        productID: product.id,
                        costPrice: costVal,
                        basePrice: priceVal,
                        tax: taxVal,
                        isActive: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try await SupabaseAuthService.shared.createPricing(pricing: newPricing)
                }
                
                // Refresh data
                await authManager.fetchProductMasterRecords()
                await authManager.fetchPricingRules()
            } catch {
                print("Failed to save pricing changes: \(error)")
            }
        }
    }
    
    private func require2FA(action: @escaping () -> Void) {
        pendingAction = action
        show2FA = true
    }
}
