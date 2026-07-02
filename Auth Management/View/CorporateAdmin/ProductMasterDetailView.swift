import SwiftUI

struct ProductMasterDetailView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State var product: ProductMasterRecord
    
    @State private var showProductEditor = false
    @State private var show2FADelete = false
    
    // Audit expansion
    @State private var isAuditExpanded = false
    private let auditCollapsedLimit = 3
    
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
                    
                    // Edit / Archive / Delete actions
                    productActionsSection
                    
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
                product = savedProduct
                showProductEditor = false
            }
            .environmentObject(authManager)
        }
        .sheet(isPresented: $show2FADelete) {
            TwoFactorVerificationSheet(
                title: "Confirm Deletion",
                subtitle: "Permanently deletes '\(product.name)' from the catalog",
                onSuccess: {
                    authManager.deleteProductMasterRecord(id: product.id)
                    show2FADelete = false
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Product Actions
    
    private var productActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                productActionButton(
                    title: "Edit",
                    icon: "pencil",
                    background: MatteTheme.Colors.primaryGold
                ) {
                    showProductEditor = true
                }

                productActionButton(
                    title: "Archive",
                    icon: "archivebox",
                    background: MatteTheme.Colors.info
                ) {
                    archiveProduct()
                }
            }

            productActionButton(
                title: "Delete",
                icon: "trash",
                background: MatteTheme.Colors.error
            ) {
                show2FADelete = true
            }
        }
    }

    private func productActionButton(
        title: String,
        icon: String,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.ivoryMatte)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(background)
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func archiveProduct() {
        var updated = product
        updated.isArchived = true
        authManager.updateProductMasterRecord(updated)
        product = updated
        dismiss()
    }
    
    // MARK: - Header Card View (Visual Product Banner)
    
    private var headerCardView: some View {
        VStack(spacing: 12) {
            if let imageURLString = product.imageURL, let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(MatteTheme.Colors.border, lineWidth: 1.5))
                    case .failure, .empty:
                        fallbackMonogramCircle
                    @unknown default:
                        fallbackMonogramCircle
                    }
                }
            } else {
                fallbackMonogramCircle
            }

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
            detailRow(title: "Category", value: product.category.isEmpty ? "Uncategorized" : product.category)
            Divider()
            detailRow(title: "SKU Code", value: product.sku)
            Divider()
            detailRow(title: "Barcode (EAN-13)", value: product.barcode.isEmpty ? "Not Assigned" : product.barcode)
            Divider()
            let pricing = authManager.pricingRules.first { $0.productID == product.id }
            let displayPrice = pricing?.basePrice ?? product.price
            let displayCost = pricing?.costPrice ?? product.costPrice
            let displayTax = pricing?.tax ?? product.tax
            
            detailRow(title: "Corporate Price (Retail)", value: formatPrice(displayPrice))
            Divider()
            detailRow(title: "Cost Price (HQ)", value: formatPrice(displayCost))
            Divider()
            detailRow(title: "Tax Rate", value: "\(Int(displayTax))%")
            
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
    
    // MARK: - Audit History Timeline
    
    private var productAuditLogs: [AuditLog] {
        authManager.productAuditLogs
            .filter { $0.recordID == product.id }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    private var auditHistoryTimeline: some View {
        let logs = productAuditLogs
        let hasMoreLogs = logs.count > auditCollapsedLimit
        let visibleLogs = isAuditExpanded ? logs : Array(logs.prefix(auditCollapsedLimit))

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AUDIT LOG HISTORY")
                    .font(.caption.weight(.bold))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .kerning(1.2)

                Spacer()

                if !logs.isEmpty {
                    Text("\(logs.count) \(logs.count == 1 ? "entry" : "entries")")
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, 4)

            if logs.isEmpty {
                Text("No changes recorded in the audit logs.")
                    .font(.subheadline)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(visibleLogs.enumerated()), id: \.element.id) { index, log in
                        auditLogRow(
                            log: log,
                            isLast: index == visibleLogs.count - 1 && (!hasMoreLogs || isAuditExpanded)
                        )
                    }

                    if hasMoreLogs {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                isAuditExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(isAuditExpanded ? "See Less" : "See More")
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .rotationEffect(.degrees(isAuditExpanded ? 180 : 0))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(MatteTheme.Colors.primaryGold)
                        .accessibilityLabel(isAuditExpanded ? "See Less" : "See More")
                        .accessibilityHint(
                            isAuditExpanded
                                ? "Collapses the audit log history"
                                : "Shows \(logs.count - auditCollapsedLimit) more audit log entries"
                        )
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
    
    private func auditLogRow(log: AuditLog, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(auditActionColor(log.action))
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(MatteTheme.Colors.border)
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(log.action.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(auditActionColor(log.action))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(auditActionColor(log.action).opacity(0.12))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(log.modifiedAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    Text(log.modifiedAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
                
                let modifierName = getModifierName(log.modifiedBy)
                Text("Modified by: @\(modifierName)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                
                let changes = auditChangeDescriptions(for: log)
                ForEach(changes, id: \.self) { change in
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
        if let current = authManager.currentUser, current.id == userID {
            return current.username
        }
        if let user = authManager.users.first(where: { $0.id == userID }) {
            return user.username
        }
        return authManager.currentUser?.username ?? "System"
    }
    
    private func auditChangeDescriptions(for log: AuditLog) -> [String] {
        var changes = parseChanges(prevStr: log.previousValues, newStr: log.newValues)

        if changes.isEmpty {
            switch log.action {
            case .create:
                changes.append("Product created")
            case .update:
                changes.append("Product edited")
            case .delete:
                changes.append("Product deleted")
            }
        }

        return changes
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
            if prev.category != new.category { changes.append("Category: '\(prev.category)' → '\(new.category)'") }
        } else if let new = newRecord {
            changes.append("Product created: \(new.name) (\(new.sku))")
            changes.append("Initial Price: \(formatPrice(new.price))")
        } else if let prev = prevRecord {
            changes.append("Product deleted: \(prev.name) (\(prev.sku))")
        }
        return changes
    }

    // MARK: - Display Helper Properties

    private var categoryIcon: String {
        switch product.category.lowercased() {
        case "purses", "handbags", "leather goods": return "handbag"
        case "watches": return "clock"
        case "fragrances": return "sparkles"
        case "footwear", "sneakers": return "shoe"
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

    private var fallbackMonogramCircle: some View {
        Circle()
            .fill(categoryColor.opacity(0.15))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: categoryIcon)
                    .font(.system(size: 32))
                    .foregroundColor(categoryColor)
            )
    }
}

