import SwiftUI

// MARK: - Inventory Controller Tab View

/// The Inventory Controller sees: Warehouse (stock levels), Stock Movement (transfers/receipts), Variances (reconciliations).
/// Owns and manages the influx and outflux of items in the unified shared storage (HQ/Warehouse).
struct InventoryControllerTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false

    // State for Stock Movement form
    @State private var showRecordMovementSheet = false
    @State private var selectedProductID = UUID()
    @State private var selectedSourceStoreID = SeedData.corporateHeadquartersID
    @State private var selectedDestStoreID = SeedData.mumbaiFlagshipID
    @State private var transferQty = 5
    @State private var isReceipt = true // true = Vendor Receipt (Influx), false = Inter-store Transfer (Outflux)
    @State private var movementError: String?

    // State for Variance form
    @State private var showReportVarianceSheet = false
    @State private var varianceProductID = UUID()
    @State private var expectedQty = 10
    @State private var actualQty = 9
    @State private var varianceReason = ""
    @State private var varianceError: String?

    var body: some View {
        TabView {
            warehouseTab
                .tabItem { Label("Warehouse", systemImage: "shippingbox") }

            movementTab
                .tabItem { Label("Movements", systemImage: "arrow.left.arrow.right") }

            variancesTab
                .tabItem { Label("Variances", systemImage: "exclamationmark.triangle") }
        }
        .tint(MatteTheme.Colors.espresso)
        .onAppear {
            initializeDefaults()
        }
    }

    private func initializeDefaults() {
        if let firstProd = authManager.products.first {
            selectedProductID = firstProd.id
            varianceProductID = firstProd.id
        }
    }

    // MARK: - Warehouse Tab

    private var warehouseTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    welcomeCard

                    infoCard(
                        title: "Unified Shared Storage",
                        subtitle: "Central warehouse system managing the inventory catalog for all global boutique locations.",
                        icon: "shippingbox.fill"
                    )

                    sectionCard(title: "Warehouse Inventory Levels", icon: "square.grid.3x2") {
                        let warehouseRecs = authManager.inventoryRecords.filter { $0.storeID == SeedData.corporateHeadquartersID }
                        if warehouseRecs.isEmpty {
                            Text("No central warehouse records found.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        } else {
                            VStack(spacing: 14) {
                                ForEach(warehouseRecs) { record in
                                    let product = authManager.products.first(where: { $0.id == record.productID })
                                    let pName = product?.name ?? "Unknown Product"
                                    let sku = product?.sku ?? "SKU"
                                    
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(stockColor(record.quantity <= record.reorderThreshold ? .critical : .healthy).opacity(0.15))
                                            .frame(width: 38, height: 38)
                                            .overlay(
                                                Image(systemName: "cube.box")
                                                    .foregroundColor(stockColor(record.quantity <= record.reorderThreshold ? .critical : .healthy))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(MatteTheme.Colors.textPrimary)
                                            Text("\(sku) • Reorder point: \(record.reorderThreshold)")
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Quick Warehouse Qty Adjustments
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
                                    if record.id != warehouseRecs.last?.id {
                                        Divider()
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
            .navigationTitle("Warehouse")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Stock Movement Tab

    private var movementTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    infoCard(
                        title: "Log Movements",
                        subtitle: "Record influxes of new stock from suppliers, or manage outfluxes by transferring items to boutiques.",
                        icon: "arrow.left.arrow.right.circle"
                    )

                    HStack {
                        Spacer()
                        Button(action: { showRecordMovementSheet = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Record Stock Movement")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MatteTheme.Colors.ivoryMatte)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(MatteTheme.Colors.espresso)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 4)

                    sectionCard(title: "Recent Actions Log", icon: "list.bullet.rectangle.portrait") {
                        let filteredLogs = authManager.actionLogs.filter { $0.username == authManager.currentUser?.username }
                        if filteredLogs.isEmpty {
                            Text("No movements recorded by you yet.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(filteredLogs) { log in
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
                                        Text("Store: \(log.storeName)")
                                            .font(.system(size: 10))
                                            .foregroundColor(MatteTheme.Colors.textTertiary)
                                        
                                        if log.id != filteredLogs.last?.id {
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
            .navigationTitle("Movements")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
            .sheet(isPresented: $showRecordMovementSheet) {
                recordMovementSheetView
            }
        }
    }

    // MARK: - Variances Tab

    private var variancesTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    infoCard(
                        title: "Audit & Discrepancies",
                        subtitle: "Compare expected stock with physical cycle counts. All logged variances are reported to Corporate Admin.",
                        icon: "exclamationmark.triangle.fill"
                    )

                    HStack {
                        Spacer()
                        Button(action: { showReportVarianceSheet = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Report Discrepancy")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MatteTheme.Colors.ivoryMatte)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(MatteTheme.Colors.espresso)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 4)

                    sectionCard(title: "Discrepancy Records", icon: "doc.text.magnifyingglass") {
                        if authManager.varianceRecords.isEmpty {
                            Text("No stock discrepancies recorded.")
                                .font(.subheadline)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(authManager.varianceRecords) { record in
                                    let product = authManager.products.first(where: { $0.id == record.productID })
                                    let pName = product?.name ?? "Unknown Product"
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(pName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(MatteTheme.Colors.textPrimary)
                                            Spacer()
                                            BadgeView(
                                                text: record.status.rawValue,
                                                color: record.status == .resolved ? MatteTheme.Colors.success : MatteTheme.Colors.warning
                                            )
                                        }
                                        
                                        HStack {
                                            Text("Expected: \(record.expectedQuantity)")
                                            Spacer()
                                            Text("Actual: \(record.actualQuantity)")
                                            Spacer()
                                            Text("Variance: \(record.variance > 0 ? "+" : "")\(record.variance)")
                                                .fontWeight(.semibold)
                                                .foregroundColor(record.variance < 0 ? MatteTheme.Colors.error : MatteTheme.Colors.success)
                                        }
                                        .font(.caption)
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                        
                                        if let reason = record.reason, !reason.isEmpty {
                                            Text("Note: \(reason)")
                                                .font(.caption2)
                                                .foregroundColor(MatteTheme.Colors.textTertiary)
                                        }
                                        
                                        // Quick resolution buttons for IC
                                        if record.status != .resolved && record.status != .writtenOff {
                                            HStack(spacing: 10) {
                                                Button("Resolve") {
                                                    try? authManager.updateVarianceStatus(id: record.id, status: .resolved)
                                                }
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.success)
                                                
                                                Button("Write Off") {
                                                    try? authManager.updateVarianceStatus(id: record.id, status: .writtenOff)
                                                }
                                                .font(.caption)
                                                .foregroundColor(MatteTheme.Colors.error)
                                            }
                                            .padding(.top, 4)
                                        }

                                        if record.id != authManager.varianceRecords.last?.id {
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
            .navigationTitle("Variances")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
            .sheet(isPresented: $showReportVarianceSheet) {
                reportVarianceSheetView
            }
        }
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

    private enum StockStatus { case healthy, low, critical }

    private func stockColor(_ status: StockStatus) -> Color {
        switch status {
        case .healthy: return MatteTheme.Colors.success
        case .low: return MatteTheme.Colors.warning
        case .critical: return MatteTheme.Colors.error
        }
    }

    // MARK: - Movement Sheet View

    private var recordMovementSheetView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Movement Direction")) {
                    Picker("Type", selection: $isReceipt) {
                        Text("Vendor Receipt (Central Influx)").tag(true)
                        Text("Boutique Transfer (Outflux)").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Product Catalog")) {
                    Picker("Product", selection: $selectedProductID) {
                        ForEach(authManager.products) { product in
                            Text("\(product.name) (\(product.sku))").tag(product.id)
                        }
                    }
                }

                if isReceipt {
                    Section(header: Text("Details")) {
                        Stepper("Quantity to Receive: \(transferQty)", value: $transferQty, in: 1...200)
                    }
                } else {
                    Section(header: Text("Transfer Details")) {
                        Picker("From Store", selection: $selectedSourceStoreID) {
                            ForEach(authManager.stores) { store in
                                Text(store.name).tag(store.id)
                            }
                        }
                        Picker("To Store", selection: $selectedDestStoreID) {
                            ForEach(authManager.stores.filter { $0.id != selectedSourceStoreID }) { store in
                                Text(store.name).tag(store.id)
                            }
                        }
                        Stepper("Quantity to Transfer: \(transferQty)", value: $transferQty, in: 1...100)
                    }
                }

                if let error = movementError {
                    Section {
                        Text(error)
                            .foregroundColor(MatteTheme.Colors.error)
                            .font(.caption)
                    }
                }

                Button("Post Stock Movement") {
                    postMovement()
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(MatteTheme.Colors.primaryGold)
            }
            .navigationTitle("Log Stock Movement")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showRecordMovementSheet = false }
                }
            }
        }
    }

    private func postMovement() {
        movementError = nil
        do {
            if isReceipt {
                // Receipt goes to warehouse
                let record = authManager.inventoryRecords.first(where: { $0.productID == selectedProductID && $0.storeID == SeedData.corporateHeadquartersID })
                let currentVal = record?.quantity ?? 0
                try authManager.updateInventoryQuantity(
                    productID: selectedProductID,
                    storeID: SeedData.corporateHeadquartersID,
                    newQuantity: currentVal + transferQty
                )
            } else {
                // Transfer from Source to Destination
                try authManager.transferStock(
                    productID: selectedProductID,
                    fromStoreID: selectedSourceStoreID,
                    toStoreID: selectedDestStoreID,
                    quantity: transferQty
                )
            }
            showRecordMovementSheet = false
        } catch {
            movementError = error.localizedDescription
        }
    }

    // MARK: - Variance Sheet View

    private var reportVarianceSheetView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Discrepancy Details")) {
                    Picker("Product", selection: $varianceProductID) {
                        ForEach(authManager.products) { product in
                            Text(product.name).tag(product.id)
                        }
                    }
                    Stepper("Expected Stock: \(expectedQty)", value: $expectedQty, in: 0...100)
                    Stepper("Physically Counted: \(actualQty)", value: $actualQty, in: 0...100)
                }

                Section(header: Text("Audit Note")) {
                    TextField("Reason for variance (theft, damage, etc.)", text: $varianceReason)
                }

                if let error = varianceError {
                    Section {
                        Text(error)
                            .foregroundColor(MatteTheme.Colors.error)
                            .font(.caption)
                    }
                }

                Button("Submit Report") {
                    submitVariance()
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(MatteTheme.Colors.primaryGold)
            }
            .navigationTitle("Report Stock Discrepancy")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showReportVarianceSheet = false }
                }
            }
        }
    }

    private func submitVariance() {
        varianceError = nil
        guard !varianceReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            varianceError = "Please describe the reason for the discrepancy."
            return
        }

        do {
            try authManager.addVarianceRecord(
                productID: varianceProductID,
                expected: expectedQty,
                actual: actualQty,
                reason: varianceReason
            )
            showReportVarianceSheet = false
            varianceReason = ""
        } catch {
            varianceError = error.localizedDescription
        }
    }
}

private struct SeedData {
    static let corporateHeadquartersID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let mumbaiFlagshipID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
}
