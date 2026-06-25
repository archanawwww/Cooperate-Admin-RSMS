import SwiftUI

// MARK: - Sales Associate Tab View

/// The Sales Associate sees: Floor (Appointments/Events), Cart & Sales (Transactions), Customers (directory).
/// Do NOT show any inventory management views to the Sales Associate.
struct SalesAssociateTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false

    // State for Cart
    @State private var selectedProductForCart = UUID()
    @State private var cartQuantity = 1
    @State private var currentCartItems: [CartItem] = []
    @State private var selectedCustomerForSale = ""
    @State private var checkoutStatusMessage: String?

    var body: some View {
        TabView {
            floorTab
                .tabItem { Label("Floor", systemImage: "figure.walk") }

            cartTab
                .tabItem { Label("Cart & Sales", systemImage: "cart") }

            customersTab
                .tabItem { Label("Customers", systemImage: "person.3") }
        }
        .tint(MatteTheme.Colors.espresso)
        .onAppear {
            initializeDefaults()
        }
    }

    private func initializeDefaults() {
        if let firstProd = authManager.products.first {
            selectedProductForCart = firstProd.id
        }
    }

    // MARK: - Floor Tab

    private var floorTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    welcomeCard

                    infoCard(
                        title: "Boutique Floor Ops",
                        subtitle: "Your active client list, scheduled VIP appointments, and tasks for today at: \(authManager.currentUser?.storeName ?? "Boutique").",
                        icon: "door.left.hand.open"
                    )

                    sectionCard(title: "VIP Appointments", icon: "calendar") {
                        VStack(alignment: .leading, spacing: 12) {
                            appointmentRow(client: "Aditi Rao", time: "3:30 PM", notes: "Prefers leather goods, Birkin focus.")
                            Divider()
                            appointmentRow(client: "Cyrus Poonawalla", time: "5:00 PM", notes: "Looking at diamond cufflinks.")
                        }
                    }

                    sectionCard(title: "Assigned Floor Tasks", icon: "checklist") {
                        let myTasks = authManager.tasksVisibleToCurrentUser()
                        if myTasks.isEmpty {
                            Text("No pending floor tasks assigned to you.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(myTasks) { task in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(task.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(MatteTheme.Colors.textPrimary)
                                            Spacer()
                                            BadgeView(text: task.priority.rawValue, color: priorityColor(task.priority))
                                        }
                                        if !task.notes.isEmpty {
                                            Text(task.notes)
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                        }
                                        
                                        if task.status != .completed {
                                            Button("Mark Completed") {
                                                try? authManager.updateTaskStatus(id: task.id, status: .completed)
                                            }
                                            .font(.caption)
                                            .foregroundColor(MatteTheme.Colors.success)
                                            .padding(.top, 4)
                                        } else {
                                            Text("Completed")
                                                .font(.caption2)
                                                .foregroundColor(MatteTheme.Colors.textTertiary)
                                        }
                                        
                                        if task.id != myTasks.last?.id {
                                            Divider().padding(.top, 6)
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
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Floor Ops")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Cart & Sales Tab

    private var cartTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    infoCard(
                        title: "Boutique Checkout",
                        subtitle: "Create shopping carts and process customer transactions securely.",
                        icon: "creditcard"
                    )

                    sectionCard(title: "Add Item to Cart", icon: "cart.badge.plus") {
                        VStack(spacing: 12) {
                            Picker("Product", selection: $selectedProductForCart) {
                                ForEach(authManager.products) { product in
                                    Text("\(product.name) - \(product.formattedPrice)").tag(product.id)
                                }
                            }
                            
                            Stepper("Quantity: \(cartQuantity)", value: $cartQuantity, in: 1...10)
                            
                            Button(action: addToCart) {
                                Text("Add to Cart")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(MatteTheme.Colors.ivoryMatte)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(MatteTheme.Colors.espresso)
                                    .cornerRadius(10)
                            }
                        }
                    }

                    sectionCard(title: "Shopping Cart", icon: "cart.fill") {
                        if currentCartItems.isEmpty {
                            Text("Your cart is empty.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 10)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(currentCartItems) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.product.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(MatteTheme.Colors.textPrimary)
                                            Text("\(item.quantity) x \(item.product.formattedPrice)")
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                        }
                                        Spacer()
                                        
                                        Button(action: { removeFromCart(item: item) }) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.error)
                                        }
                                    }
                                    Divider()
                                }
                                
                                HStack {
                                    Text("Total Price")
                                        .font(.headline)
                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", cartTotal()))")
                                        .font(.headline)
                                        .foregroundColor(MatteTheme.Colors.primaryGold)
                                }
                                .padding(.vertical, 6)

                                TextField("Customer Name", text: $selectedCustomerForSale)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.vertical, 4)

                                Button(action: checkout) {
                                    Text("Complete Transaction")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(MatteTheme.Colors.ivoryMatte)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(MatteTheme.Colors.espresso)
                                        .cornerRadius(12)
                                }
                                .disabled(selectedCustomerForSale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }

                    if let status = checkoutStatusMessage {
                        sectionCard(title: "Status", icon: "bell") {
                            Text(status)
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.primaryGold)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Customers Tab

    private var customersTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    infoCard(
                        title: "Client Book",
                        subtitle: "View preferences and purchase histories for active high-net-worth clients.",
                        icon: "person.text.rectangle"
                    )

                    sectionCard(title: "Registered HNW Clients", icon: "person.crop.rectangle.stack") {
                        VStack(alignment: .leading, spacing: 14) {
                            customerRow(name: "Amit Patel", tier: "VVIP", preference: "Watches, Gold", history: "Purchased GMT Master in May 2026")
                            Divider()
                            customerRow(name: "Sarah Fernandes", tier: "VIP", preference: "Leather bags, scarves", history: "Purchased Silk Evening Clutch in June 2026")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Clients")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Cart Helpers

    private struct CartItem: Identifiable {
        let id = UUID()
        let product: Product
        var quantity: Int
    }

    private func addToCart() {
        guard let product = authManager.products.first(where: { $0.id == selectedProductForCart }) else { return }
        
        if let index = currentCartItems.firstIndex(where: { $0.product.id == product.id }) {
            currentCartItems[index].quantity += cartQuantity
        } else {
            currentCartItems.append(CartItem(product: product, quantity: cartQuantity))
        }
        cartQuantity = 1
    }

    private func removeFromCart(item: CartItem) {
        currentCartItems.removeAll { $0.id == item.id }
    }

    private func cartTotal() -> Double {
        currentCartItems.reduce(0.0) { $0 + ($1.product.basePrice * Double($1.quantity)) }
    }

    private func checkout() {
        checkoutStatusMessage = nil
        let localStoreID = authManager.currentUser?.assignedStoreID ?? SeedData.mumbaiFlagshipID

        // Verify stock levels first and deduct from inventory
        var missingStock = false
        for item in currentCartItems {
            if let recordIndex = authManager.inventoryRecords.firstIndex(where: { $0.productID == item.product.id && $0.storeID == localStoreID }) {
                if authManager.inventoryRecords[recordIndex].quantity < item.quantity {
                    missingStock = true
                }
            } else {
                missingStock = true
            }
        }

        if missingStock {
            checkoutStatusMessage = "Transaction Failed: Insufficient stock available at this boutique."
            return
        }

        // Deduct stock
        for item in currentCartItems {
            if let recordIndex = authManager.inventoryRecords.firstIndex(where: { $0.productID == item.product.id && $0.storeID == localStoreID }) {
                let currentVal = authManager.inventoryRecords[recordIndex].quantity
                try? authManager.updateInventoryQuantity(
                    productID: item.product.id,
                    storeID: localStoreID,
                    newQuantity: currentVal - item.quantity
                )
            }
        }

        checkoutStatusMessage = "Transaction Completed Successfully for \(selectedCustomerForSale)! Total: €\(String(format: "%.2f", cartTotal()))"
        currentCartItems = []
        selectedCustomerForSale = ""
    }

    // MARK: - Reusable Components & Subviews

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
                    BadgeView(text: user.role.rawValue, color: MatteTheme.Colors.roleColor(for: user.role))
                    BadgeView(text: user.storeName, color: MatteTheme.Colors.textSecondary)
                }
            }
        }
        .padding(20)
        .background(MatteTheme.Colors.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(MatteTheme.Colors.border, lineWidth: 1))
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

    private func appointmentRow(client: String, time: String, notes: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(client)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Text(notes)
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
            Spacer()
            Text(time)
                .font(.caption.weight(.semibold))
                .foregroundColor(MatteTheme.Colors.primaryGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MatteTheme.Colors.primaryGold.opacity(0.12))
                .cornerRadius(6)
        }
    }

    private func customerRow(name: String, tier: String, preference: String, history: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                    BadgeView(text: tier, color: tier == "VVIP" ? MatteTheme.Colors.primaryGold : MatteTheme.Colors.success)
                }
                Text("Preferences: \(preference)")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
                Text("History: \(history)")
                    .font(.caption2)
                    .foregroundColor(MatteTheme.Colors.textTertiary)
            }
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return MatteTheme.Colors.error
        case .medium: return MatteTheme.Colors.warning
        case .low: return MatteTheme.Colors.success
        }
    }
}

private struct SeedData {
    static let mumbaiFlagshipID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
}
