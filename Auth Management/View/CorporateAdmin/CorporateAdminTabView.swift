import SwiftUI
import Charts

// MARK: - Corporate Admin Tab View (iOS 26 Liquid Glass — 4-Tab Shell)

/// The root tab view for Corporate Admin. Routes to:
/// - Tab 0: DashboardView (Executive Overview)
/// - Tab 1: GovernanceView (Store Managers, Policies, Audit Logs)
/// - Tab 2: MasterCatalogView (Product Catalog Hub)
/// - Tab 3: OperationsView (Campaigns, Reports, Analytics)
struct CorporateAdminTabView: View {
    enum Tab: Int {
        case dashboard
        case boutiques
        case governance
        case catalog
        case operations
    }

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Tab 0: Dashboard
            DashboardView(
                onNavigateToGovernance: { selectedTab = .governance },
                onNavigateToCatalog: { selectedTab = .catalog },
                onNavigateToOperations: { selectedTab = .operations }
            )
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            .tag(Tab.dashboard)

            // MARK: - Tab 1: Boutiques & Inventory Hub
            BoutiqueInventoryView()
                .tabItem {
                    Label("Boutiques", systemImage: "storefront.fill")
                }
                .tag(Tab.boutiques)

            // MARK: - Tab 2: Governance
            GovernanceView()
                .tabItem {
                    Label("Governance", systemImage: "building.columns")
                }
                .tag(Tab.governance)

            // MARK: - Tab 3: Master Catalog
            MasterCatalogView()
                .tabItem {
                    Label("Catalog", systemImage: "shippingbox.fill")
                }
                .tag(Tab.catalog)

            // MARK: - Tab 4: Operations
            OperationsView()
                .tabItem {
                    Label("Operations", systemImage: "chart.bar.xaxis")
                }
                .tag(Tab.operations)
        }
        .tint(MatteTheme.Colors.luxuryGold)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusInventoryOnMap"))) { _ in
            selectedTab = .dashboard
        }
    }
}
