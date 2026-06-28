import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var taskTitle = ""
    @State private var taskNotes = ""
    @State private var selectedPriority: TaskPriority = .medium
    @State private var selectedAssigneeID = UUID()
    @State private var actionMessage: String?

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Greeting header as navigation title is set outside
                // Top insights grid
                if let user = authManager.currentUser {
                    insightsGrid(user)
                }
            }
            .padding(.top, 8)

            VStack(spacing: 18) {
                if let user = authManager.currentUser {
                    userSummaryCard(user)
                    taskActionsCard
                    recentTasksCard
                    signOutButton
                }
            }
            .padding(.vertical, 24)
        }
        .safeAreaPadding(.horizontal, 16)
        .navigationTitle("Good morning, Corporate Admin")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: selectDefaultAssignee)
        .onChange(of: authManager.users) { _, _ in
            selectDefaultAssignee()
        }
    }

    private func userSummaryCard(_ user: AuthenticatedUser) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(user.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                    Label(user.storeName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                }
                Spacer()
                Circle()
                    .fill(MatteTheme.Colors.roleColor(for: user.role).opacity(0.14))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: user.role.icon)
                            .font(.title2)
                            .foregroundColor(MatteTheme.Colors.roleColor(for: user.role))
                    )
            }

            Divider().background(MatteTheme.Colors.border)

            HStack(spacing: 10) {
                BadgeView(user.role.rawValue)
                BadgeView(user.region.rawValue)
            }
        }
        .padding(24)
        .liquidGlassCard()
    }

    private var taskActionsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Text(actionCardTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(MatteTheme.Colors.textPrimary)

                Spacer()

                BadgeView("\(authManager.tasksVisibleToCurrentUser().count)")
            }

            ForEach(actionRows, id: \.title) { action in
                AdminActionRow(action: action)
            }

            if canAssignTasks {
                Divider()
                    .background(MatteTheme.Colors.border)

                taskAssignmentForm
            }
        }
        .padding(22)
        .liquidGlassCard()
    }

    private var taskAssignmentForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Assign Task")
                .font(.headline)
                .foregroundColor(MatteTheme.Colors.textPrimary)

            if eligibleAssignees.isEmpty {
                Text(emptyAssigneeMessage)
                    .font(.subheadline)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(MatteTheme.Colors.secondaryBackground)
                    .cornerRadius(12)
            } else {
                TextField("Task title", text: $taskTitle)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(MatteTheme.Colors.surface.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MatteTheme.Colors.border, lineWidth: 1)
                    )

                TextField("Notes", text: $taskNotes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(MatteTheme.Colors.surface.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MatteTheme.Colors.border, lineWidth: 1)
                    )

                Picker("Assign To", selection: $selectedAssigneeID) {
                    ForEach(eligibleAssignees) { user in
                        Text("\(user.displayName) - \(user.role.rawValue)").tag(user.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(MatteTheme.Colors.primaryGold)

                Picker("Priority", selection: $selectedPriority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.segmented)

                Button(action: assignTask) {
                    Label("Assign Task", systemImage: "paperplane.fill")
                        .font(.headline)
                        .foregroundColor(MatteTheme.Colors.ivoryMatte)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(MatteTheme.Colors.espresso)
                        .cornerRadius(14)
                }
            }

            if let actionMessage {
                Text(actionMessage)
                    .font(.footnote)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
        }
    }

    private var recentTasksCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Recent Tasks")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(MatteTheme.Colors.textPrimary)

            let visibleTasks = authManager.tasksVisibleToCurrentUser()
            if visibleTasks.isEmpty {
                Text("No assigned tasks yet.")
                    .font(.subheadline)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(visibleTasks.prefix(5)) { task in
                    TaskRowView(
                        task: task,
                        assigneeName: displayName(for: task.assignedToUserID)
                    )
                }
            }
        }
        .padding(22)
        .liquidGlassCard()
    }

    private var signOutButton: some View {
        Button(action: {
            withAnimation {
                authManager.logout()
            }
        }) {
            Text("Sign Out")
                .font(.headline)
                .foregroundColor(MatteTheme.Colors.ivoryMatte)
                .padding()
                .frame(maxWidth: .infinity)
                .background(MatteTheme.Colors.espresso)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(MatteTheme.Colors.primaryGold.opacity(0.22), lineWidth: 1)
                )
        }
        .padding(.bottom, 12)
    }

    private var eligibleAssignees: [ManagedUser] {
        authManager.eligibleTaskAssignees()
    }

    private var canAssignTasks: Bool {
        guard let role = authManager.currentUser?.role else {
            return false
        }

        return role == .corporateAdmin || role == .boutiqueManager
    }

    private var actionCardTitle: String {
        authManager.currentUser?.role == .boutiqueManager ? "Manager Actions" : "Admin Actions"
    }

    private var emptyAssigneeMessage: String {
        authManager.currentUser?.role == .boutiqueManager
        ? "No approved sales associates are available for this store."
        : "Create and approve boutique managers or inventory controllers before assigning work."
    }

    private var actionRows: [DashboardActionItem] {
        guard let role = authManager.currentUser?.role else {
            return []
        }

        switch role {
        case .corporateAdmin:
            return [
                DashboardActionItem(title: "Assign Managers", subtitle: "Create work for boutiques and inventory", badge: "\(eligibleAssignees.count)", symbolName: "person.2"),
                DashboardActionItem(title: "Approve Users", subtitle: "\(pendingUsersCount) waiting for admin confirmation", badge: "\(pendingUsersCount)", symbolName: "checkmark.shield"),
                DashboardActionItem(title: "Store Coverage", subtitle: "Review users by country and region", badge: "\(authManager.users.count)", symbolName: "building.2")
            ]
        case .boutiqueManager:
            return [
                DashboardActionItem(title: "Assign Associates", subtitle: "Delegate store floor tasks", badge: "\(eligibleAssignees.count)", symbolName: "person.badge.plus"),
                DashboardActionItem(title: "Open Store Tasks", subtitle: "\(authManager.tasksVisibleToCurrentUser().count) visible assignments", badge: "\(authManager.tasksVisibleToCurrentUser().count)", symbolName: "list.bullet.clipboard")
            ]
        case .inventoryController, .salesAssociate:
            return [
                DashboardActionItem(title: "My Tasks", subtitle: "Work assigned to your role", badge: "\(authManager.tasksVisibleToCurrentUser().count)", symbolName: "checklist")
            ]
        }
    }

    private var pendingUsersCount: Int {
        authManager.users.filter { !$0.isApprovedByAdmin }.count
    }

    private func selectDefaultAssignee() {
        guard let first = eligibleAssignees.first else {
            return
        }

        if eligibleAssignees.contains(where: { $0.id == selectedAssigneeID }) == false {
            selectedAssigneeID = first.id
        }
    }

    private func assignTask() {
        do {
            try authManager.assignTask(
                title: taskTitle,
                notes: taskNotes,
                priority: selectedPriority,
                assigneeID: selectedAssigneeID
            )
            taskTitle = ""
            taskNotes = ""
            selectedPriority = .medium
            actionMessage = "Task assigned."
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    private func displayName(for userID: UUID) -> String {
        authManager.users.first(where: { $0.id == userID })?.displayName ?? "Unassigned"
    }

    private func insightsGrid(_ user: AuthenticatedUser) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        let employeeCount = authManager.users.count
        let activeStoreCount = authManager.stores.count
        let revenueString = "₹18,60,000" // Replace with real computation when available
        let businessHealthString = "Strong" // Placeholder metric label

        return LazyVGrid(columns: columns, spacing: 12) {
            insightTile(title: "Revenue", value: revenueString, symbol: "chart.line.uptrend.xyaxis")
            insightTile(title: "Business Health", value: businessHealthString, symbol: "heart.text.square")
            insightTile(title: "Employees", value: "\(employeeCount)", symbol: "person.3")
            insightTile(title: "Active Stores", value: "\(activeStoreCount)", symbol: "building.2")
        }
    }

    private func insightTile(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbol).foregroundColor(MatteTheme.Colors.primaryGold)
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(MatteTheme.Colors.textPrimary)
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
}

private struct DashboardActionItem: Hashable {
    let title: String
    let subtitle: String
    let badge: String
    let symbolName: String
}

private struct AdminActionRow: View {
    let action: DashboardActionItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: action.symbolName)
                .font(.headline)
                .foregroundColor(MatteTheme.Colors.primaryGold)
                .frame(width: 48, height: 48)
                .background(MatteTheme.Colors.primaryGold.opacity(0.12))
                .cornerRadius(15)

            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(action.subtitle)
                    .font(.subheadline)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(action.badge)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(action.badge == "New" ? MatteTheme.Colors.ivoryMatte : MatteTheme.Colors.primaryGold)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(action.badge == "New" ? MatteTheme.Colors.primaryGold : MatteTheme.Colors.secondaryBackground)
                .cornerRadius(14)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.textTertiary)
        }
        .padding(.vertical, 8)
    }
}

private struct TaskRowView: View {
    let task: WorkTask
    let assigneeName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(priorityColor.opacity(0.16))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "checklist")
                        .foregroundColor(priorityColor)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(MatteTheme.Colors.textPrimary)

                Text("\(assigneeName) - \(task.storeLocation.region.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(MatteTheme.Colors.textSecondary)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.footnote)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                BadgeView(task.priority.rawValue)
                Text(task.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return MatteTheme.Colors.error
        case .medium:
            return MatteTheme.Colors.warning
        case .low:
            return MatteTheme.Colors.success
        }
    }
}
