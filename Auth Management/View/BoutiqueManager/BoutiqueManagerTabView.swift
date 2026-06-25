import SwiftUI

// MARK: - Boutique Manager Tab View

/// Boutique Manager sees: Store, Local Inventory, Team, Sales Reports.
/// No Company Reports tab. Only their own store data.
struct BoutiqueManagerTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false
    @State private var selectedInventoryTab = 0 // 0 = My Boutique, 1 = Global Network (Read-Only)

    var body: some View {
        TabView {
            storeTab
                .tabItem { Label("Store", systemImage: "building.2") }

            localInventoryTab
                .tabItem { Label("Inventory", systemImage: "shippingbox") }

            teamTab
                .tabItem { Label("Team", systemImage: "person.2") }

            salesReportsTab
                .tabItem { Label("Sales", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(MatteTheme.Colors.espresso)
    }

    // MARK: - Store Tab

    private var storeTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    storeOverviewCard
                    teamSummaryCard
                    recentActivityCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("My Store")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Local Inventory Tab

    private var localInventoryTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Inventory Scope", selection: $selectedInventoryTab) {
                    Text("My Boutique").tag(0)
                    Text("Global Network (Read-Only)").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(MatteTheme.Colors.surface)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if selectedInventoryTab == 0 {
                            // My Boutique (Read/Write)
                            infoCard(
                                title: "Local Store Inventory",
                                subtitle: "You have full read & write permissions for stock in your assigned store: \(authManager.currentUser?.storeName ?? "My Store").",
                                icon: "shippingbox.fill"
                            )
                            
                            sectionCard(title: "Stock Levels", icon: "chart.bar") {
                                let localStoreID = authManager.currentUser?.assignedStoreID
                                let localRecords = authManager.inventoryRecords.filter { $0.storeID == localStoreID }
                                
                                if localRecords.isEmpty {
                                    Text("No inventory records found.")
                                        .font(.subheadline)
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                } else {
                                    VStack(spacing: 14) {
                                        ForEach(localRecords) { record in
                                            let product = authManager.products.first(where: { $0.id == record.productID })
                                            let pName = product?.name ?? "Unknown Product"
                                            let sku = product?.sku ?? "SKU"
                                            
                                            HStack(spacing: 12) {
                                                Circle()
                                                    .fill(stockColor(record.quantity <= record.reorderThreshold ? .critical : .healthy).opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                    .overlay(
                                                        Image(systemName: "cube.box")
                                                            .font(.caption)
                                                            .foregroundColor(stockColor(record.quantity <= record.reorderThreshold ? .critical : .healthy))
                                                    )
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(pName)
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                                        .lineLimit(1)
                                                    Text("\(sku) • Reorder point: \(record.reorderThreshold)")
                                                        .font(.caption)
                                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                // Read/Write access Stepper
                                                HStack(spacing: 10) {
                                                    Button(action: {
                                                        if record.quantity > 0 {
                                                            try? authManager.updateInventoryQuantity(productID: record.productID, storeID: record.storeID, newQuantity: record.quantity - 1)
                                                        }
                                                    }) {
                                                        Image(systemName: "minus.circle.fill")
                                                            .font(.title3)
                                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                                    }
                                                    
                                                    Text("\(record.quantity)")
                                                        .font(.headline)
                                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                                        .frame(minWidth: 26)
                                                        
                                                    Button(action: {
                                                        try? authManager.updateInventoryQuantity(productID: record.productID, storeID: record.storeID, newQuantity: record.quantity + 1)
                                                    }) {
                                                        Image(systemName: "plus.circle.fill")
                                                            .font(.title3)
                                                            .foregroundColor(MatteTheme.Colors.espresso)
                                                    }
                                                }
                                            }
                                            if record.id != localRecords.last?.id {
                                                Divider()
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // Global Network (Read-Only)
                            infoCard(
                                title: "Company-Wide Network Stock",
                                subtitle: "View-only access to inventory at other boutique locations and central warehouse storage.",
                                icon: "globe"
                            )
                            
                            let localStoreID = authManager.currentUser?.assignedStoreID
                            let otherRecords = authManager.inventoryRecords.filter { $0.storeID != localStoreID }
                            
                            if otherRecords.isEmpty {
                                Text("No other store records available.")
                                    .font(.subheadline)
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                            } else {
                                ForEach(authManager.stores.filter { $0.id != localStoreID }) { store in
                                    sectionCard(title: store.name, icon: "building.2") {
                                        let storeRecs = otherRecords.filter { $0.storeID == store.id }
                                        if storeRecs.isEmpty {
                                            Text("No stock information available.")
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                        } else {
                                            VStack(alignment: .leading, spacing: 10) {
                                                ForEach(storeRecs) { record in
                                                    let product = authManager.products.first(where: { $0.id == record.productID })
                                                    HStack {
                                                        Text(product?.name ?? "Unknown")
                                                            .font(.subheadline)
                                                            .foregroundColor(MatteTheme.Colors.textPrimary)
                                                        Spacer()
                                                        Text("\(record.quantity) units")
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                                    }
                                                    if record.id != storeRecs.last?.id {
                                                        Divider()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 96)
                }
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Team Tab

    private var teamTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    infoCard(
                        title: "Your Team",
                        subtitle: "Manage Sales Associates assigned to your store. Other managers' teams are not visible.",
                        icon: "person.2"
                    )

                    let associates = authManager.salesAssociatesUnderCurrentManager()
                    sectionCard(title: "Sales Associates (\(associates.count))", icon: "person.badge.plus") {
                        if associates.isEmpty {
                            Text("No Sales Associates created yet. Use the profile button to create one.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        } else {
                            ForEach(associates) { user in
                                teamMemberRow(user: user)
                            }
                        }
                    }

                    let pending = authManager.pendingApprovalUsers()
                    if !pending.isEmpty {
                        sectionCard(title: "Pending Approval", icon: "clock.badge.checkmark") {
                            ForEach(pending) { user in
                                HStack(spacing: 12) {
                                    roleCircle(for: user.role, size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.displayName.isEmpty ? user.username : user.displayName)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(MatteTheme.Colors.textPrimary)
                                        Text(user.role.rawValue)
                                            .font(.caption)
                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Button("Approve") {
                                        try? authManager.approveUser(id: user.id)
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(MatteTheme.Colors.ivoryMatte)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(MatteTheme.Colors.espresso)
                                    .cornerRadius(10)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Team")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Sales Reports Tab

    private var salesReportsTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    infoCard(
                        title: "Store Sales",
                        subtitle: "View sales performance for your store only. Company-wide reports are admin-only.",
                        icon: "chart.line.uptrend.xyaxis"
                    )

                    sectionCard(title: "Today's Summary", icon: "calendar") {
                        reportRow(label: "Transactions", value: "14")
                        reportRow(label: "Revenue", value: "₹3,45,000")
                        reportRow(label: "Avg. Value", value: "₹24,643")
                        reportRow(label: "Returns", value: "1")
                    }

                    sectionCard(title: "This Week", icon: "chart.bar") {
                        reportRow(label: "Total Sales", value: "₹18,60,000")
                        reportRow(label: "Top Category", value: "Handbags")
                        reportRow(label: "Best Associate", value: authManager.salesAssociatesUnderCurrentManager().first?.displayName ?? "—")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Sales Reports")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Reusable Components

    private var storeOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let user = authManager.currentUser {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.storeName)
                            .font(.title2.weight(.bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                        Text("\(user.region.rawValue), \(user.country.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                    Spacer()
                    roleCircle(for: user.role, size: 50)
                }
                HStack(spacing: 10) {
                    BadgeView(user.role.rawValue)
                    BadgeView(user.displayName)
                }
            }
        }
        .padding(20)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }

    private var teamSummaryCard: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(title: "Associates", value: "\(authManager.salesAssociatesUnderCurrentManager().count)", icon: "person.2", color: MatteTheme.Colors.success)
            metricTile(title: "Pending", value: "\(authManager.pendingApprovalUsers().count)", icon: "clock", color: MatteTheme.Colors.warning)
        }
    }

    private var recentActivityCard: some View {
        sectionCard(title: "Recent Activity", icon: "clock.arrow.circlepath") {
            Text("Store activity feed coming soon.")
                .font(.subheadline)
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
    }

    private func teamMemberRow(user: ManagedUser) -> some View {
        HStack(spacing: 12) {
            roleCircle(for: user.role, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName.isEmpty ? user.username : user.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
            Spacer()
            BadgeView(
                user.isActive ? "Active" : "Inactive"
            )
        }
        .padding(.vertical, 4)
    }

    private enum StockStatus { case healthy, low, critical }

    private func stockRow(product: String, qty: Int, threshold: Int, status: StockStatus) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(stockColor(status).opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "cube.box")
                        .font(.caption)
                        .foregroundColor(stockColor(status))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(product)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text("Qty: \(qty) / Reorder: \(threshold)")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
            Spacer()
            BadgeView(
                status == .healthy ? "OK" : (status == .low ? "Low" : "Critical")
            )
        }
        .padding(.vertical, 3)
    }

    private func stockColor(_ status: StockStatus) -> Color {
        switch status {
        case .healthy: return MatteTheme.Colors.success
        case .low: return MatteTheme.Colors.warning
        case .critical: return MatteTheme.Colors.error
        }
    }

    // MARK: - Shared Helpers

    private func roleCircle(for role: UserRole, size: CGFloat) -> some View {
        Circle()
            .fill(MatteTheme.Colors.roleColor(for: role).opacity(0.14))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: role.icon)
                    .font(size > 40 ? .title3 : .caption)
                    .foregroundColor(MatteTheme.Colors.roleColor(for: role))
            )
    }

    private func metricTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }

    private func infoCard(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(MatteTheme.Colors.primaryGold)
                Text(title)
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(MatteTheme.Colors.primaryGold)
                Text(title)
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Spacer()
            }
            content()
        }
        .padding(20)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }

    private func reportRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(MatteTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.textPrimary)
        }
    }
}
