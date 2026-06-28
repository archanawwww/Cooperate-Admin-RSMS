import SwiftUI
import Charts

// MARK: - Corporate Admin Tab View

struct CorporateAdminTabView: View {
    enum Tab {
        case dashboard, reports, approvals, users, items
    }

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false
    @State private var selectedTab: Tab = .dashboard

    // State variables for Create User Card
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var newDisplayName = ""
    @State private var newStoreName = ""
    @State private var newRole: UserRole = .boutiqueManager
    @State private var newCountry: Country = .india
    @State private var newRegion: Region = .mumbai
    @State private var statusMessage: String?

    // State for editing a user
    @State private var editingUser: ManagedUser? = nil

    // State for policies management
    @State private var editingPolicy: CompanyPolicy? = nil
    @State private var isAddingPolicy = false
    @State private var policyToDelete: CompanyPolicy? = nil
    @State private var showDeleteConfirmation = false

    private var creatableRoles: [UserRole] {
        [.boutiqueManager, .inventoryController]
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            overviewTab
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
                .tag(Tab.dashboard)

            companyReportsTab
                .tabItem { Label("Reports", systemImage: "chart.bar.doc.horizontal") }
                .tag(Tab.reports)

            approvalsTab
                .tabItem { Label("Approvals", systemImage: "checkmark.shield") }
                .tag(Tab.approvals)

            usersTab
                .tabItem { Label("Users", systemImage: "person.2") }
                .tag(Tab.users)

            CorporateAdminItemsView()
                .tabItem { Label("Items", systemImage: "shippingbox.fill") }
                .tag(Tab.items)
        }
        .tint(MatteTheme.Colors.espresso)
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                headerSection
                topMetricsRow
                revenueTrendChart
                actionsRequiredSection
                topPerformingStoresSection
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Company Reports Tab (Admin-Only)

    private var companyReportsTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Premium Product Master Entry Card
                    NavigationLink(destination: ProductMasterManagementView().environmentObject(authManager)) {
                        sectionCard(title: "Product Master Records", icon: "shippingbox") {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Global Catalog Management")
                                        .font(.subheadline)
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading) {
                                            Text("\(authManager.productMasterRecords.count)")
                                                .font(.title2.weight(.bold))
                                                .foregroundColor(MatteTheme.Colors.textPrimary)
                                            Text("Total SKUs")
                                                .font(.system(size: 10))
                                                .foregroundColor(MatteTheme.Colors.textTertiary)
                                        }
                                        
                                        Divider().frame(height: 28)
                                        
                                        VStack(alignment: .leading) {
                                            Text("\(authManager.productMasterRecords.filter { $0.isActive }.count)")
                                                .font(.title2.weight(.bold))
                                                .foregroundColor(MatteTheme.Colors.success)
                                            Text("Active Catalog")
                                                .font(.system(size: 10))
                                                .foregroundColor(MatteTheme.Colors.textTertiary)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(MatteTheme.Colors.primaryGold)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    reportCard(
                        title: "Sales Metrics",
                        icon: "indianrupeesign.circle",
                        items: [
                            ("Total Revenue", "₹48,50,000"),
                            ("Transactions", "312"),
                            ("Avg. Value", "₹15,545"),
                            ("Top Category", "Handbags")
                        ]
                    )

                    reportCard(
                        title: "Inventory Health",
                        icon: "shippingbox",
                        items: [
                            ("Total SKUs", "1,240"),
                            ("Stock Health", "87%"),
                            ("Pending Transfers", "5"),
                            ("Open Variances", "2")
                        ]
                    )

                    sectionCard(title: "Inventory Controller Reports", icon: "doc.text.magnifyingglass") {
                        if authManager.actionLogs.isEmpty {
                            Text("No inventory controller actions reported yet.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(authManager.actionLogs) { log in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(log.actionType)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(MatteTheme.Colors.textPrimary)
                                            Spacer()
                                            Text(log.date, style: .time)
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.textTertiary)
                                        }
                                        Text(log.details)
                                            .font(.caption)
                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                        Text("By @\(log.username) at \(log.storeName)")
                                            .font(.system(size: 10))
                                            .foregroundColor(MatteTheme.Colors.textTertiary)

                                        if log.id != authManager.actionLogs.last?.id {
                                            Divider().padding(.top, 6)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    sectionCard(title: "Company Policies", icon: "doc.text") {
                        VStack(alignment: .leading, spacing: 14) {
                            if authManager.companyPolicies.isEmpty {
                                Text("No company policies have been created yet.")
                                    .font(.subheadline)
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(authManager.companyPolicies) { policy in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(policy.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(MatteTheme.Colors.textPrimary)
                                            Spacer()
                                            
                                            HStack(spacing: 16) {
                                                Button(action: {
                                                    editingPolicy = policy
                                                }) {
                                                    Image(systemName: "pencil")
                                                        .font(.subheadline)
                                                        .foregroundColor(MatteTheme.Colors.primaryGold)
                                                }
                                                .buttonStyle(.plain)
                                                
                                                Button(action: {
                                                    policyToDelete = policy
                                                    showDeleteConfirmation = true
                                                }) {
                                                    Image(systemName: "trash")
                                                        .font(.subheadline)
                                                        .foregroundColor(MatteTheme.Colors.error)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        
                                        Text(policy.content)
                                            .font(.caption)
                                            .foregroundColor(MatteTheme.Colors.textSecondary)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        HStack {
                                            Text("Last updated: \(policy.lastUpdated, style: .date) \(policy.lastUpdated, style: .time)")
                                                .font(.system(size: 10))
                                                .foregroundColor(MatteTheme.Colors.textTertiary)
                                            Spacer()
                                        }
                                        .padding(.top, 2)
                                        
                                        if policy.id != authManager.companyPolicies.last?.id {
                                            Divider().padding(.top, 8)
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                isAddingPolicy = true
                            }) {
                                Label("Add Policy", systemImage: "plus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(MatteTheme.Colors.ivoryMatte)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(MatteTheme.Colors.espresso)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                    }

                    reportCard(
                        title: "Compliance",
                        icon: "checkmark.seal",
                        items: [
                            ("Reports Submitted", "28"),
                            ("Approved", "24"),
                            ("Rejected", "2"),
                            ("Score", "92%")
                        ]
                    )

                    reportCard(
                        title: "Campaigns",
                        icon: "megaphone",
                        items: [
                            ("Active", "3"),
                            ("Total Reach", "4,500"),
                            ("Conversion", "12%"),
                            ("Promo Revenue", "₹6,20,000")
                        ]
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Company Reports")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
            .sheet(isPresented: $isAddingPolicy) {
                PolicyEditorSheet(policy: nil)
                    .environmentObject(authManager)
            }
            .sheet(item: $editingPolicy) { policy in
                PolicyEditorSheet(policy: policy)
                    .environmentObject(authManager)
            }
            .alert("Delete Policy", isPresented: $showDeleteConfirmation, presenting: policyToDelete) { policy in
                Button("Delete", role: .destructive) {
                    authManager.deleteCompanyPolicy(id: policy.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: { policy in
                Text("Are you sure you want to permanently delete the policy '\(policy.title)'?")
            }
        }
    }

    // MARK: - Approvals Tab

    private var approvalsTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    let pending = authManager.pendingApprovalUsers()
                    sectionCard(title: "Pending Approvals", icon: "clock.badge.checkmark") {
                        if pending.isEmpty {
                            Text("No accounts are waiting for approval.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(pending) { user in
                                userRow(user: user, showApprove: true)
                            }
                        }
                    }

                    sectionCard(title: "Recently Approved", icon: "checkmark.circle") {
                        let approved = authManager.users.filter { $0.isApprovedByAdmin && $0.role != .corporateAdmin }
                            .sorted { $0.updatedAt > $1.updatedAt }
                            .prefix(5)

                        if approved.isEmpty {
                            Text("No recently approved users.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        } else {
                            ForEach(Array(approved)) { user in
                                userRow(user: user, showApprove: false)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Approvals")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Users Tab

    private var usersTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    createUserCard
                        .padding(.bottom, 8)

                    ForEach(UserRole.allCases.filter { $0 != .corporateAdmin }) { role in
                        sectionCard(title: "\(role.rawValue)s", icon: role.icon) {
                            let roleUsers = authManager.users.filter { $0.role == role }
                            if roleUsers.isEmpty {
                                Text("No \(role.rawValue.lowercased())s yet.")
                                    .font(.subheadline)
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                            } else {
                                ForEach(roleUsers) { user in
                                    Button(action: { editingUser = user }) {
                                        userRow(user: user, showApprove: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
            .sheet(item: $editingUser) { user in
                EditUserSheet(user: user)
                    .environmentObject(authManager)
            }
        }
    }

    // MARK: - Dashboard Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dashboard")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(MatteTheme.Colors.textPrimary)
            Text("Business Performance Overview")
                .font(.caption)
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var topMetricsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Revenue Tile
            dashboardTile(
                icon: "indianrupeesign",
                title: "Revenue",
                value: "₹24.5 Cr",
                subtext: "↑ 12.4% MoM",
                subtextColor: MatteTheme.Colors.success
            )

            // Boutiques Tile
            dashboardTile(
                icon: "square.grid.2x2",
                title: "Boutiques",
                value: "\(authManager.stores.count)",
                subtext: "● All active",
                subtextColor: MatteTheme.Colors.success
            )

            // Business Health Tile
            dashboardTile(
                icon: "heart",
                title: "Business Health",
                value: "87/100",
                subtext: "Excellent ✓",
                subtextColor: MatteTheme.Colors.primaryGold
            )

            // Employees Tile
            dashboardTile(
                icon: "person.2",
                title: "Employees",
                value: "\(authManager.users.count)",
                subtext: "● Active",
                subtextColor: MatteTheme.Colors.success
            )
        }
    }

    private func dashboardTile(icon: String, title: String, value: String, subtext: String, subtextColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(MatteTheme.Colors.primaryGold)
                    .frame(width: 32, height: 32)
                    .background(MatteTheme.Colors.primaryGold.opacity(0.1))
                    .clipShape(Circle())
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(MatteTheme.Colors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }

            Text(subtext)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(subtextColor)
        }
        .padding(14)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
    }

    struct RevenueData: Identifiable {
        let id = UUID()
        let month: String
        let revenue: Double
    }

    let mockRevenueData = [
        RevenueData(month: "Feb", revenue: 16),
        RevenueData(month: "Mar", revenue: 18),
        RevenueData(month: "Apr", revenue: 20),
        RevenueData(month: "May", revenue: 22.5),
        RevenueData(month: "Jun", revenue: 24.5)
    ]

    private var revenueTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("REVENUE TREND")
                    .font(.caption.weight(.bold))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .kerning(1.2)
                Spacer()
                Button(action: { selectedTab = .reports }) {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MatteTheme.Colors.dashboardBackground)
                    .cornerRadius(12)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("₹24.5 Crore")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Text("↑ ₹2.5 Cr above June target")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.success)
            }

            Chart(mockRevenueData) { data in
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Revenue", data.revenue)
                )
                .foregroundStyle(MatteTheme.Colors.primaryGold)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", data.month),
                    y: .value("Revenue", data.revenue)
                )
                .foregroundStyle(MatteTheme.Colors.espresso)

                AreaMark(
                    x: .value("Month", data.month),
                    y: .value("Revenue", data.revenue)
                )
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [MatteTheme.Colors.primaryGold.opacity(0.3), MatteTheme.Colors.primaryGold.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [12, 16, 20, 24, 28]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue) Cr")
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
    }

    private var actionsRequiredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIONS REQUIRED")
                    .font(.caption.weight(.bold))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .kerning(1.2)
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MatteTheme.Colors.dashboardBackground)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                actionRow(
                    icon: "person.2",
                    title: "Assign managers",
                    subtitle: assignManagersSubtitle,
                    count: "\(unassignedBoutiqueCount)",
                    countColor: assignManagersCountColor
                ) {
                    selectedTab = .users
                }
                Divider().padding(.leading, 50)
                actionRow(icon: "shippingbox", title: "Review products", subtitle: "7 pending approval", count: "7", countColor: MatteTheme.Colors.primaryGold) {
                    selectedTab = .items
                }
                Divider().padding(.leading, 50)
                actionRow(icon: "checkmark.shield", title: "Compliance reviews", subtitle: "2 audits pending", count: "2", countColor: MatteTheme.Colors.info) {
                    selectedTab = .reports
                }
                Divider().padding(.leading, 50)
                actionRow(icon: "chart.bar.doc.horizontal", title: "Business reports", subtitle: "Monthly summary ready", count: "New", countColor: MatteTheme.Colors.success) {
                    selectedTab = .reports
                }
            }
            .background(MatteTheme.Colors.surface)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
        }
    }

    private func actionRow(icon: String, title: String, subtitle: String, count: String, countColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(MatteTheme.Colors.espresso)
                    .frame(width: 40, height: 40)
                    .background(MatteTheme.Colors.primaryGold.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                }
                Spacer()

                Text(count)
                    .font(.caption.weight(.bold))
                    .foregroundColor(countColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(countColor.opacity(0.15))
                    .cornerRadius(8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textTertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private var topPerformingStoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOP PERFORMING STORES")
                    .font(.caption.weight(.bold))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .kerning(1.2)
                Spacer()
                Button(action: { selectedTab = .reports }) {
                    Text("View All")
                        .font(.caption.weight(.medium))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(MatteTheme.Colors.dashboardBackground)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Mock data for UI layout
                storeRow(name: "Paris Flagship", revenue: "₹4.8 Cr", growth: "↑ 22%") { selectedTab = .reports }
                Divider().padding(.leading, 50)
                storeRow(name: "Dubai Mall", revenue: "₹3.6 Cr", growth: "↑ 18%") { selectedTab = .reports }
                Divider().padding(.leading, 50)
                storeRow(name: "Singapore Marina Bay", revenue: "₹3.1 Cr", growth: "↑ 15%") { selectedTab = .reports }
            }
            .background(MatteTheme.Colors.surface)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
        }
    }

    private func storeRow(name: String, revenue: String, growth: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "building.2.fill")
                    .foregroundColor(MatteTheme.Colors.espresso)
                    .frame(width: 40, height: 40)
                    .background(MatteTheme.Colors.primaryGold.opacity(0.15))
                    .cornerRadius(10)

                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)

                Spacer()

                Text(revenue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textPrimary)

                Text(growth)
                    .font(.caption.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.success)
                    .frame(width: 45, alignment: .trailing)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
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

    private func reportCard(title: String, icon: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(MatteTheme.Colors.primaryGold)
                Text(title)
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }
            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.subheadline)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                    Spacer()
                    Text(item.1)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
            }
        }
        .padding(20)
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

    private func userRow(user: ManagedUser, showApprove: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(MatteTheme.Colors.roleColor(for: user.role).opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: user.role.icon)
                        .font(.subheadline)
                        .foregroundColor(MatteTheme.Colors.roleColor(for: user.role))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName.isEmpty ? user.username : user.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text("\(user.role.rawValue) — \(user.storeLocation.region.rawValue)")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if showApprove {
                Button("Approve") {
                    try? authManager.approveUser(id: user.id)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.ivoryMatte)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(MatteTheme.Colors.espresso)
                .cornerRadius(10)
            } else {
                BadgeView(
                    text: user.isApprovedByAdmin ? "Active" : "Pending",
                    color: user.isApprovedByAdmin ? MatteTheme.Colors.success : MatteTheme.Colors.warning
                )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers & Computed Properties

    private var unassignedBoutiqueCount: Int {
        let boutiques = authManager.stores.filter { $0.id != authManager.corporateHeadquartersID }
        let assignedStoreIDs = Set(authManager.users.filter { $0.role == .boutiqueManager && $0.isActive && $0.isApprovedByAdmin }.compactMap { $0.assignedStoreID })
        return boutiques.filter { !assignedStoreIDs.contains($0.id) }.count
    }

    private var assignManagersSubtitle: String {
        let count = unassignedBoutiqueCount
        if count == 0 {
            return "All boutiques assigned"
        } else if count == 1 {
            return "1 boutique unassigned"
        } else {
            return "\(count) boutiques unassigned"
        }
    }

    private var assignManagersCountColor: Color {
        unassignedBoutiqueCount > 0 ? MatteTheme.Colors.error : MatteTheme.Colors.success
    }

    private func createUser() {
        do {
            let storeLocation: StoreLocation
            let name = newStoreName.trimmingCharacters(in: .whitespacesAndNewlines)
            storeLocation = StoreLocation(
                name: name.isEmpty ? "\(newRegion.rawValue) Boutique" : name,
                country: newCountry,
                region: newRegion
            )

            let request = NewUserRequest(
                username: newUsername,
                password: newPassword,
                displayName: newDisplayName,
                role: newRole,
                storeLocation: storeLocation
            )

            try authManager.createUser(request)

            // Also register in MockLoginBackend
            MockLoginBackend.shared.addCredentials(
                username: newUsername,
                password: newPassword,
                role: newRole.rawValue
            )

            newUsername = ""
            newPassword = ""
            newDisplayName = ""
            newStoreName = ""
            statusMessage = "Account created successfully."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private var createUserCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(MatteTheme.Colors.primaryGold)
                Text("Create User")
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }

            TextField("Display name", text: $newDisplayName)
                .matteFieldStyle()
            TextField("Username", text: $newUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .matteFieldStyle()
            SecureField("Password", text: $newPassword)
                .matteFieldStyle()

            TextField("Store name", text: $newStoreName)
                .matteFieldStyle()

            Picker("Role", selection: $newRole) {
                ForEach(creatableRoles) { role in
                    Text(role.rawValue).tag(role)
                }
            }
            .pickerStyle(.menu)
            .tint(MatteTheme.Colors.primaryGold)

            HStack {
                Picker("Country", selection: $newCountry) {
                    ForEach(Country.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .pickerStyle(.menu)

                Picker("Region", selection: $newRegion) {
                    ForEach(Region.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.menu)
            }
            .tint(MatteTheme.Colors.primaryGold)

            Button(action: createUser) {
                Label("Create Account", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.ivoryMatte)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MatteTheme.Colors.espresso)
                    .cornerRadius(14)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
        }
        .padding(20)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }
}
