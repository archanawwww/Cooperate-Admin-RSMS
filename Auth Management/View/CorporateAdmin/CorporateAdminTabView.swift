import SwiftUI

// MARK: - Corporate Admin Tab View

/// The Corporate Admin sees: Overview, Company Reports, Approvals, Users.
/// This is the only role that gets Company Reports.
struct CorporateAdminTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false

    var body: some View {
        TabView {
            overviewTab
                .tabItem { Label("Overview", systemImage: "square.grid.2x2") }

            companyReportsTab
                .tabItem { Label("Reports", systemImage: "chart.bar.doc.horizontal") }

            approvalsTab
                .tabItem { Label("Approvals", systemImage: "checkmark.shield") }

            usersTab
                .tabItem { Label("Users", systemImage: "person.2") }
        }
        .tint(MatteTheme.Colors.espresso)
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    welcomeCard
                    metricsGrid
                    storesSummaryCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Company Reports Tab (Admin-Only)

    private var companyReportsTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
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
                    ForEach(UserRole.allCases.filter { $0 != .corporateAdmin }) { role in
                        sectionCard(title: "\(role.rawValue)s", icon: role.icon) {
                            let roleUsers = authManager.users.filter { $0.role == role }
                            if roleUsers.isEmpty {
                                Text("No \(role.rawValue.lowercased())s yet.")
                                    .font(.subheadline)
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                            } else {
                                ForEach(roleUsers) { user in
                                    userRow(user: user, showApprove: false)
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
        }
    }

    // MARK: - Reusable Components

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let user = authManager.currentUser {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome,")
                            .font(.subheadline)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Text(user.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                    }
                    Spacer()
                    Circle()
                        .fill(MatteTheme.Colors.roleColor(for: user.role).opacity(0.14))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: user.role.icon)
                                .font(.title3)
                                .foregroundColor(MatteTheme.Colors.roleColor(for: user.role))
                        )
                }

                HStack(spacing: 10) {
                    BadgeView(text: user.role.rawValue)

                    BadgeView(
                        text: user.storeName,
                        color: MatteTheme.Colors.textSecondary
                    )
                }
            }
        }
        .padding(20)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(title: "Total Users", value: "\(authManager.users.count)", icon: "person.2", color: MatteTheme.Colors.info)
            metricTile(title: "Stores", value: "\(authManager.stores.count)", icon: "building.2", color: MatteTheme.Colors.primaryGold)
            metricTile(title: "Pending", value: "\(authManager.pendingApprovalUsers().count)", icon: "clock.badge.checkmark", color: MatteTheme.Colors.warning)
            metricTile(title: "Tasks", value: "\(authManager.tasksVisibleToCurrentUser().count)", icon: "checklist", color: MatteTheme.Colors.success)
        }
    }

    private var storesSummaryCard: some View {
        sectionCard(title: "Store Network", icon: "building.2") {
            ForEach(authManager.stores, id: \.id) { store in
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(MatteTheme.Colors.primaryGold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                        Text("\(store.region.rawValue), \(store.country.rawValue)")
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                    Spacer()
                    let count = authManager.users.filter { $0.assignedStoreID == store.id }.count
                    BadgeView(text: "\(count)", color: MatteTheme.Colors.textSecondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Shared Helpers

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
}

