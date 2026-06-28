import SwiftUI

struct ProductMasterDetailView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State var product: ProductMasterRecord
    
    // Editor State
    @State private var showProductEditor = false
    
    // Delete 2FA State
    @State private var show2FADelete = false
    
    var body: some View {
        ZStack {
            MatteTheme.Colors.dashboardBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Card
                    headerCardView
                    
                    // Detailed Information List
                    detailsCardView
                    
                    // Actions Card
                    actionsCardView
                    
                    // Audit Logs Timeline
                    auditHistoryTimeline
                }
                .padding(16)
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProductEditor) {
            ProductMasterEditorView(product: product) { savedProduct in
                authManager.updateProductMasterRecord(savedProduct)
                self.product = savedProduct // update local state
                showProductEditor = false
            }
            .environmentObject(authManager)
        }
        .sheet(isPresented: $show2FADelete) {
            TwoFactorVerificationSheet(
                title: "Confirm Deletion",
                subtitle: "Permanently delete '\(product.name)'?",
                onSuccess: {
                    authManager.deleteProductMasterRecord(id: product.id)
                    show2FADelete = false
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Header Card View (Visual Product Banner)
    
    private var headerCardView: some View {
        VStack(spacing: 12) {
            // Glass circle image placeholder
            Circle()
                .fill(categoryColor.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 32))
                        .foregroundColor(categoryColor)
                )
            
            Text(product.brand.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(MatteTheme.Colors.textSecondary)
                .kerning(1.5)
            
            Text(product.name)
                .font(.title2.weight(.bold))
                .foregroundColor(MatteTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8) {
                BadgeView(
                    text: product.isActive ? "Active" : "Inactive",
                    color: product.isActive ? MatteTheme.Colors.success : MatteTheme.Colors.textTertiary
                )
                
                BadgeView(
                    text: product.sku,
                    color: MatteTheme.Colors.primaryGold.opacity(0.18)
                )
                .foregroundColor(MatteTheme.Colors.primaryGold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial)
        .background(MatteTheme.Colors.fogGlass)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(MatteTheme.Colors.border.opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - Details List View
    
    private var detailsCardView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PRODUCT IDENTITY & FINANCIALS")
                .font(.caption.weight(.bold))
                .foregroundColor(MatteTheme.Colors.textSecondary)
                .kerning(1.2)
                .padding(.bottom, 4)
            
            detailRow(title: "Brand", value: product.brand)
            Divider()
            detailRow(title: "Category", value: categoryName)
            Divider()
            detailRow(title: "SKU Code", value: product.sku)
            Divider()
            detailRow(title: "Barcode (EAN-13)", value: product.barcode.isEmpty ? "Not Assigned" : product.barcode)
            Divider()
            detailRow(title: "Corporate Price (Retail)", value: formatPrice(product.price))
            Divider()
            detailRow(title: "Cost Price (HQ)", value: formatPrice(product.costPrice))
            Divider()
            detailRow(title: "Tax Rate", value: "\(Int(product.tax))%")
            
            if let desc = product.description, !desc.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .background(MatteTheme.Colors.fogGlass)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(MatteTheme.Colors.border.opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - Actions Card
    
    private var actionsCardView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Edit Button
                actionButton(title: "Edit", icon: "pencil", color: MatteTheme.Colors.primaryGold) {
                    showProductEditor = true
                }
                
                // Duplicate Button
                actionButton(title: "Duplicate", icon: "doc.on.doc", color: MatteTheme.Colors.espresso) {
                    duplicateProduct()
                }
            }
            
            HStack(spacing: 12) {
                // Archive Button
                actionButton(title: product.isArchived ? "Unarchive" : "Archive", icon: product.isArchived ? "archivebox.fill" : "archivebox", color: MatteTheme.Colors.info) {
                    archiveProduct()
                }
                
                // Delete Button (Destructive)
                actionButton(title: "Delete", icon: "trash", color: MatteTheme.Colors.error) {
                    show2FADelete = true
                }
            }
        }
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(MatteTheme.Colors.ivoryMatte)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Audit History Timeline
    
    private var auditHistoryTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AUDIT LOG HISTORY")
                .font(.caption.weight(.bold))
                .foregroundColor(MatteTheme.Colors.textSecondary)
                .kerning(1.2)
                .padding(.horizontal, 4)
            
            let logs = authManager.productAuditLogs.filter { $0.recordID == product.id }
            
            if logs.isEmpty {
                Text("No changes recorded in the audit logs.")
                    .font(.subheadline)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 16) {
                    ForEach(logs) { log in
                        HStack(alignment: .top, spacing: 14) {
                            // Timeline node
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(auditActionColor(log.action))
                                    .frame(width: 12, height: 12)
                                
                                if log.id != logs.last?.id {
                                    Rectangle()
                                        .fill(MatteTheme.Colors.border)
                                        .frame(width: 2, height: 60)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    // Action Badge
                                    Text(log.action.rawValue)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(auditActionColor(log.action))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(auditActionColor(log.action).opacity(0.12))
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    // Timestamp
                                    Text(log.modifiedAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(MatteTheme.Colors.textTertiary)
                                    Text(log.modifiedAt, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(MatteTheme.Colors.textTertiary)
                                }
                                
                                // User
                                let modifierName = getModifierName(log.modifiedBy)
                                Text("Modified by: @\(modifierName)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(MatteTheme.Colors.textPrimary)
                                
                                // Specific changes
                                ForEach(parseChanges(prevStr: log.previousValues, newStr: log.newValues), id: \.self) { change in
                                    Text("• \(change)")
                                        .font(.system(size: 11))
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                }
                            }
                            .padding(14)
                            .background(MatteTheme.Colors.surface.opacity(0.6))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(MatteTheme.Colors.border.opacity(0.6), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .background(MatteTheme.Colors.fogGlass)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(MatteTheme.Colors.border.opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - Row Helpers
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(MatteTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.textPrimary)
        }
    }
    
    private func formatPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }
    
    private func auditActionColor(_ action: AuditAction) -> Color {
        switch action {
        case .create: return MatteTheme.Colors.success
        case .update: return MatteTheme.Colors.primaryGold
        case .delete: return MatteTheme.Colors.error
        }
    }
    
    private func getModifierName(_ userID: UUID) -> String {
        if let user = authManager.users.first(where: { $0.id == userID }) {
            return user.username
        }
        return "admin"
    }
    
    private func parseChanges(prevStr: String?, newStr: String?) -> [String] {
        let decoder = JSONDecoder()
        var changes: [String] = []
        
        let prevRecord = prevStr.flatMap { try? decoder.decode(ProductMasterRecord.self, from: $0.data(using: .utf8)!) }
        let newRecord = newStr.flatMap { try? decoder.decode(ProductMasterRecord.self, from: $0.data(using: .utf8)!) }
        
        if let prev = prevRecord, let new = newRecord {
            if prev.name != new.name { changes.append("Name: '\(prev.name)' → '\(new.name)'") }
            if prev.sku != new.sku { changes.append("SKU: '\(prev.sku)' → '\(new.sku)'") }
            if prev.brand != new.brand { changes.append("Brand: '\(prev.brand)' → '\(new.brand)'") }
            if prev.price != new.price { changes.append("Price: \(formatPrice(prev.price)) → \(formatPrice(new.price))") }
            if prev.costPrice != new.costPrice { changes.append("Cost: \(formatPrice(prev.costPrice)) → \(formatPrice(new.costPrice))") }
            if prev.tax != new.tax { changes.append("Tax: \(Int(prev.tax))% → \(Int(new.tax))%") }
            if prev.barcode != new.barcode { changes.append("Barcode: '\(prev.barcode)' → '\(new.barcode)'") }
            if prev.isActive != new.isActive { changes.append("Status: \(prev.isActive ? "Active" : "Inactive") → \(new.isActive ? "Active" : "Inactive")") }
            if prev.isArchived != new.isArchived { changes.append("Archived: \(prev.isArchived) → \(new.isArchived)") }
            if prev.description != new.description { changes.append("Description modified") }
        } else if let new = newRecord {
            changes.append("Product created: \(new.name) (\(new.sku))")
            changes.append("Initial Price: \(formatPrice(new.price))")
        } else if let prev = prevRecord {
            changes.append("Product deleted: \(prev.name) (\(prev.sku))")
        }
        return changes
    }
    
    // MARK: - Display Helper Properties
    
    private var categoryName: String {
        if let catID = product.categoryID, let cat = authManager.itemCategories.first(where: { $0.id == catID }) {
            return cat.name
        }
        return "Uncategorized"
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
    
    // MARK: - Action Helpers
    
    private func duplicateProduct() {
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
        dismiss()
    }
    
    private func archiveProduct() {
        var updated = product
        updated.isArchived.toggle()
        authManager.updateProductMasterRecord(updated)
        self.product = updated
    }
}

