import SwiftUI
import Charts
import UserNotifications
import MapKit

// MARK: - Dashboard View (Executive Overview)

/// Tab 0 — The executive dashboard for Corporate Admin.
/// Displays KPIs, charts, quick actions, audit logs, alerts, and notifications.
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    // Navigation callbacks
    var onNavigateToGovernance: (() -> Void)?
    var onNavigateToCatalog: (() -> Void)?
    var onNavigateToOperations: (() -> Void)?

    // Reminders state
    private struct DashboardReminder: Identifiable, Codable {
        let id: UUID
        let title: String
        let date: Date
        var isPinned: Bool?
    }

    @State private var reminders: [DashboardReminder] = {
        if let data = UserDefaults.standard.data(forKey: "dashboard_reminders"),
           let decoded = try? JSONDecoder().decode([DashboardReminder].self, from: data) {
            return decoded
        }
        return []
    }()
    
    @State private var newReminderTitle = ""
    @State private var newReminderDate = Date()
    @State private var showAddForm = false
    @State private var isNotesExpanded = false

    // Country & Map state
    @State private var selectedCountry: String = "India"
    @State private var showCountryPicker = false

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 22.5937, longitude: 78.9629),
            span: MKCoordinateSpan(latitudeDelta: 26.0, longitudeDelta: 26.0)
        )
    )

    // MARK: - Country Boutique Data

    private struct CountryInfo {
        let name: String
        let flag: String
        let center: CLLocationCoordinate2D
        let span: MKCoordinateSpan
        let boutiques: [BoutiquePin]
    }

    private struct BoutiquePin: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
        let type: PinType
    }

    private enum PinType {
        case warehouse
        case boutique
        case flagship

        var color: Color {
            switch self {
            case .warehouse: return .blue
            case .boutique: return .green
            case .flagship: return .red
            }
        }

        var icon: String {
            switch self {
            case .warehouse: return "shippingbox.fill"
            case .boutique: return "bag.fill"
            case .flagship: return "star.fill"
            }
        }
    }

    private let countries: [String] = [
        "India", "USA", "China", "Germany", "France",
        "UK", "Japan", "UAE", "Italy", "Australia"
    ]

    private let countryFlags: [String: String] = [
        "India": "🇮🇳", "USA": "🇺🇸", "China": "🇨🇳", "Germany": "🇩🇪",
        "France": "🇫🇷", "UK": "🇬🇧", "Japan": "🇯🇵", "UAE": "🇦🇪",
        "Italy": "🇮🇹", "Australia": "🇦🇺"
    ]

    private func countryInfo(for country: String) -> CountryInfo {
        switch country {
        case "India":
            return CountryInfo(name: "India", flag: "🇮🇳",
                center: CLLocationCoordinate2D(latitude: 22.5937, longitude: 78.9629),
                span: MKCoordinateSpan(latitudeDelta: 22, longitudeDelta: 22),
                boutiques: [
                    BoutiquePin(name: "Mumbai Warehouse", coordinate: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777), type: .warehouse),
                    BoutiquePin(name: "Delhi Boutique", coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090), type: .boutique),
                    BoutiquePin(name: "Bangalore Boutique", coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946), type: .boutique),
                    BoutiquePin(name: "Chennai Boutique", coordinate: CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707), type: .boutique),
                    BoutiquePin(name: "Hyderabad Boutique", coordinate: CLLocationCoordinate2D(latitude: 17.3850, longitude: 78.4867), type: .boutique),
                    BoutiquePin(name: "Kolkata Boutique", coordinate: CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639), type: .boutique),
                    BoutiquePin(name: "Jaipur Flagship", coordinate: CLLocationCoordinate2D(latitude: 26.9124, longitude: 75.7873), type: .flagship),
                ])
        case "USA":
            return CountryInfo(name: "USA", flag: "🇺🇸",
                center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40),
                boutiques: [
                    BoutiquePin(name: "NY Warehouse", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), type: .warehouse),
                    BoutiquePin(name: "Los Angeles Boutique", coordinate: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), type: .boutique),
                    BoutiquePin(name: "Chicago Boutique", coordinate: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298), type: .boutique),
                    BoutiquePin(name: "Miami Boutique", coordinate: CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918), type: .boutique),
                    BoutiquePin(name: "San Francisco Boutique", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), type: .boutique),
                    BoutiquePin(name: "Houston Boutique", coordinate: CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698), type: .boutique),
                    BoutiquePin(name: "Beverly Hills Flagship", coordinate: CLLocationCoordinate2D(latitude: 34.0736, longitude: -118.4004), type: .flagship),
                ])
        case "China":
            return CountryInfo(name: "China", flag: "🇨🇳",
                center: CLLocationCoordinate2D(latitude: 35.8617, longitude: 104.1954),
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30),
                boutiques: [
                    BoutiquePin(name: "Shanghai Warehouse", coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737), type: .warehouse),
                    BoutiquePin(name: "Beijing Boutique", coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), type: .boutique),
                    BoutiquePin(name: "Shenzhen Boutique", coordinate: CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579), type: .boutique),
                    BoutiquePin(name: "Guangzhou Boutique", coordinate: CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644), type: .boutique),
                    BoutiquePin(name: "Chengdu Boutique", coordinate: CLLocationCoordinate2D(latitude: 30.5728, longitude: 104.0668), type: .boutique),
                    BoutiquePin(name: "Hangzhou Boutique", coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551), type: .boutique),
                ])
        case "Germany":
            return CountryInfo(name: "Germany", flag: "🇩🇪",
                center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
                span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8),
                boutiques: [
                    BoutiquePin(name: "Berlin Warehouse", coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), type: .warehouse),
                    BoutiquePin(name: "Munich Boutique", coordinate: CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820), type: .boutique),
                    BoutiquePin(name: "Frankfurt Boutique", coordinate: CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821), type: .boutique),
                    BoutiquePin(name: "Hamburg Boutique", coordinate: CLLocationCoordinate2D(latitude: 53.5511, longitude: 9.9937), type: .boutique),
                    BoutiquePin(name: "Düsseldorf Boutique", coordinate: CLLocationCoordinate2D(latitude: 51.2277, longitude: 6.7735), type: .boutique),
                    BoutiquePin(name: "Stuttgart Boutique", coordinate: CLLocationCoordinate2D(latitude: 48.7758, longitude: 9.1829), type: .boutique),
                ])
        case "France":
            return CountryInfo(name: "France", flag: "🇫🇷",
                center: CLLocationCoordinate2D(latitude: 46.6034, longitude: 1.8883),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10),
                boutiques: [
                    BoutiquePin(name: "Paris Warehouse", coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), type: .warehouse),
                    BoutiquePin(name: "Lyon Boutique", coordinate: CLLocationCoordinate2D(latitude: 45.7640, longitude: 4.8357), type: .boutique),
                    BoutiquePin(name: "Nice Boutique", coordinate: CLLocationCoordinate2D(latitude: 43.7102, longitude: 7.2620), type: .boutique),
                    BoutiquePin(name: "Marseille Boutique", coordinate: CLLocationCoordinate2D(latitude: 43.2965, longitude: 5.3698), type: .boutique),
                    BoutiquePin(name: "Bordeaux Boutique", coordinate: CLLocationCoordinate2D(latitude: 44.8378, longitude: -0.5792), type: .boutique),
                    BoutiquePin(name: "Toulouse Boutique", coordinate: CLLocationCoordinate2D(latitude: 43.6047, longitude: 1.4442), type: .boutique),
                    BoutiquePin(name: "Champs-Élysées Flagship", coordinate: CLLocationCoordinate2D(latitude: 48.8698, longitude: 2.3076), type: .flagship),
                ])
        case "UK":
            return CountryInfo(name: "UK", flag: "🇬🇧",
                center: CLLocationCoordinate2D(latitude: 54.0, longitude: -2.0),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10),
                boutiques: [
                    BoutiquePin(name: "London Warehouse", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), type: .warehouse),
                    BoutiquePin(name: "Manchester Boutique", coordinate: CLLocationCoordinate2D(latitude: 53.4808, longitude: -2.2426), type: .boutique),
                    BoutiquePin(name: "Birmingham Boutique", coordinate: CLLocationCoordinate2D(latitude: 52.4862, longitude: -1.8904), type: .boutique),
                    BoutiquePin(name: "Edinburgh Boutique", coordinate: CLLocationCoordinate2D(latitude: 55.9533, longitude: -3.1883), type: .boutique),
                    BoutiquePin(name: "Liverpool Boutique", coordinate: CLLocationCoordinate2D(latitude: 53.4084, longitude: -2.9916), type: .boutique),
                    BoutiquePin(name: "Bristol Boutique", coordinate: CLLocationCoordinate2D(latitude: 51.4545, longitude: -2.5879), type: .boutique),
                    BoutiquePin(name: "Harrods Flagship", coordinate: CLLocationCoordinate2D(latitude: 51.4994, longitude: -0.1633), type: .flagship),
                ])
        case "Japan":
            return CountryInfo(name: "Japan", flag: "🇯🇵",
                center: CLLocationCoordinate2D(latitude: 36.2048, longitude: 138.2529),
                span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12),
                boutiques: [
                    BoutiquePin(name: "Tokyo Warehouse", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), type: .warehouse),
                    BoutiquePin(name: "Osaka Boutique", coordinate: CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023), type: .boutique),
                    BoutiquePin(name: "Kyoto Boutique", coordinate: CLLocationCoordinate2D(latitude: 35.0116, longitude: 135.7681), type: .boutique),
                    BoutiquePin(name: "Nagoya Boutique", coordinate: CLLocationCoordinate2D(latitude: 35.1815, longitude: 136.9066), type: .boutique),
                    BoutiquePin(name: "Yokohama Boutique", coordinate: CLLocationCoordinate2D(latitude: 35.4437, longitude: 139.6380), type: .boutique),
                    BoutiquePin(name: "Fukuoka Boutique", coordinate: CLLocationCoordinate2D(latitude: 33.5904, longitude: 130.4017), type: .boutique),
                    BoutiquePin(name: "Ginza Flagship", coordinate: CLLocationCoordinate2D(latitude: 35.6717, longitude: 139.7650), type: .flagship),
                ])
        case "UAE":
            return CountryInfo(name: "UAE", flag: "🇦🇪",
                center: CLLocationCoordinate2D(latitude: 24.0, longitude: 54.0),
                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5),
                boutiques: [
                    BoutiquePin(name: "Dubai Warehouse", coordinate: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708), type: .warehouse),
                    BoutiquePin(name: "Abu Dhabi Boutique", coordinate: CLLocationCoordinate2D(latitude: 24.4539, longitude: 54.3773), type: .boutique),
                    BoutiquePin(name: "Sharjah Boutique", coordinate: CLLocationCoordinate2D(latitude: 25.3463, longitude: 55.4209), type: .boutique),
                    BoutiquePin(name: "Ajman Boutique", coordinate: CLLocationCoordinate2D(latitude: 25.4052, longitude: 55.5136), type: .boutique),
                    BoutiquePin(name: "Ras Al Khaimah Boutique", coordinate: CLLocationCoordinate2D(latitude: 25.7895, longitude: 55.9432), type: .boutique),
                    BoutiquePin(name: "Fujairah Boutique", coordinate: CLLocationCoordinate2D(latitude: 25.1288, longitude: 56.3265), type: .boutique),
                    BoutiquePin(name: "Dubai Mall Flagship", coordinate: CLLocationCoordinate2D(latitude: 25.1972, longitude: 55.2796), type: .flagship),
                ])
        case "Italy":
            return CountryInfo(name: "Italy", flag: "🇮🇹",
                center: CLLocationCoordinate2D(latitude: 42.5, longitude: 12.5),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10),
                boutiques: [
                    BoutiquePin(name: "Milan Warehouse", coordinate: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900), type: .warehouse),
                    BoutiquePin(name: "Rome Boutique", coordinate: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), type: .boutique),
                    BoutiquePin(name: "Florence Boutique", coordinate: CLLocationCoordinate2D(latitude: 43.7696, longitude: 11.2558), type: .boutique),
                    BoutiquePin(name: "Venice Boutique", coordinate: CLLocationCoordinate2D(latitude: 45.4408, longitude: 12.3155), type: .boutique),
                    BoutiquePin(name: "Naples Boutique", coordinate: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681), type: .boutique),
                    BoutiquePin(name: "Turin Boutique", coordinate: CLLocationCoordinate2D(latitude: 45.0703, longitude: 7.6869), type: .boutique),
                    BoutiquePin(name: "Via Montenapoleone Flagship", coordinate: CLLocationCoordinate2D(latitude: 45.4685, longitude: 9.1955), type: .flagship),
                ])
        case "Australia":
            return CountryInfo(name: "Australia", flag: "🇦🇺",
                center: CLLocationCoordinate2D(latitude: -25.2744, longitude: 133.7751),
                span: MKCoordinateSpan(latitudeDelta: 35, longitudeDelta: 35),
                boutiques: [
                    BoutiquePin(name: "Sydney Warehouse", coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), type: .warehouse),
                    BoutiquePin(name: "Melbourne Boutique", coordinate: CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631), type: .boutique),
                    BoutiquePin(name: "Brisbane Boutique", coordinate: CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251), type: .boutique),
                    BoutiquePin(name: "Perth Boutique", coordinate: CLLocationCoordinate2D(latitude: -31.9505, longitude: 115.8605), type: .boutique),
                    BoutiquePin(name: "Adelaide Boutique", coordinate: CLLocationCoordinate2D(latitude: -34.9285, longitude: 138.6007), type: .boutique),
                    BoutiquePin(name: "Gold Coast Boutique", coordinate: CLLocationCoordinate2D(latitude: -28.0167, longitude: 153.4000), type: .boutique),
                ])
        default:
            return countryInfo(for: "India")
        }
    }

    // MARK: - Revenue Chart Data

    private struct RevenueData: Identifiable {
        let id = UUID()
        let month: String
        let actual: Double
        let target: Double
    }

    private let revenueData = [
        RevenueData(month: "Jan", actual: 14.2, target: 15.0),
        RevenueData(month: "Feb", actual: 16.0, target: 15.5),
        RevenueData(month: "Mar", actual: 18.5, target: 17.0),
        RevenueData(month: "Apr", actual: 20.1, target: 19.5),
        RevenueData(month: "May", actual: 22.5, target: 21.0),
        RevenueData(month: "Jun", actual: 24.5, target: 22.0),
        RevenueData(month: "Jul", actual: 23.0, target: 24.0),
        RevenueData(month: "Aug", actual: 25.5, target: 25.0),
        RevenueData(month: "Sep", actual: 28.0, target: 26.5),
        RevenueData(month: "Oct", actual: 26.5, target: 28.0),
        RevenueData(month: "Nov", actual: 29.0, target: 28.5),
        RevenueData(month: "Dec", actual: 32.5, target: 30.0)
    ]



    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MatteTheme.Colors.dashboardBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        welcomeHeader
                        kpiGrid
                        salesPerformanceChart
                        inventoryHealthCard
                        boutiquesMapCard
                        notesAndRemindersCard
                    }
                    .padding(.horizontal, MatteTheme.Spacing.horizontalMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                
                // Blurred top status bar overlay
                Color.clear
                    .frame(height: 60)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .top)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Gold bar + greeting
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MatteTheme.Colors.luxuryGold)
                        .frame(width: 3, height: 16)
                    Text(greetingText.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                }
                
                Text(adminName)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                
                Text("Welcome back! Ready to elevate your business today?")
                    .font(.system(size: 13))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Profile Button
            NavigationLink(destination: ProfileSheetView()) {
                ZStack {
                    Circle()
                        .fill(MatteTheme.Colors.luxuryGold)
                        .frame(width: 44, height: 44)
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .shadow(color: MatteTheme.Colors.luxuryGold.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .sheet(isPresented: $showCountryPicker) {
            countryPickerSheet
        }
    }



    // MARK: - KPI Grid

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            kpiCard(
                icon: "indianrupeesign",
                title: "Revenue",
                value: "₹24.5 Cr",
                trend: "↑ 12.4% MoM",
                trendColor: MatteTheme.Colors.success,
                accentColor: MatteTheme.Colors.luxuryGold
            )

            kpiCard(
                icon: "bag.fill",
                title: "Sales",
                value: "312",
                trend: "↑ 8.2% MoM",
                trendColor: MatteTheme.Colors.success,
                accentColor: MatteTheme.Colors.info
            )

            let info = countryInfo(for: selectedCountry)
            kpiCard(
                icon: "building.2.fill",
                title: "Active Boutiques",
                value: "\(info.boutiques.count)",
                trend: "● In \(selectedCountry)",
                trendColor: MatteTheme.Colors.success,
                accentColor: MatteTheme.Colors.accent
            )

            kpiCard(
                icon: "shippingbox.fill",
                title: "Products",
                value: "\(authManager.productMasterRecords.count)",
                trend: "\(authManager.productMasterRecords.filter { $0.isActive }.count) active",
                trendColor: MatteTheme.Colors.primaryGold,
                accentColor: MatteTheme.Colors.success
            )
        }
    }

    private func kpiCard(icon: String, title: String, value: String, trend: String, trendColor: Color, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)
                    .frame(width: 34, height: 34)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Circle())
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(MatteTheme.Typography.kpiValue)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(MatteTheme.Typography.caption)
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }

            Text(trend)
                .font(MatteTheme.Typography.metricLabel)
                .foregroundColor(trendColor)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.large))
    }

    // MARK: - Sales Performance Chart

    private var salesPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                    Text("Sales Performance")
                        .font(MatteTheme.Typography.sectionHeader)
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
                Spacer()
                Button(action: { onNavigateToOperations?() }) {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₹32.5 Crore")
                        .font(MatteTheme.Typography.kpiValue)
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                    Text("↑ ₹2.5 Cr above target")
                        .font(.caption.weight(.medium))
                        .foregroundColor(MatteTheme.Colors.success)
                }

                Chart {
                    // Target Sale Area (Info-Purple-Error)
                    ForEach(revenueData) { data in
                        AreaMark(
                            x: .value("Month", data.month),
                            y: .value("Target Sale", data.target)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    MatteTheme.Colors.info.opacity(0.5),
                                    Color.purple.opacity(0.3),
                                    MatteTheme.Colors.error.opacity(0.12)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    // Target Sale Line (Blue/Info)
                    ForEach(revenueData) { data in
                        LineMark(
                            x: .value("Month", data.month),
                            y: .value("Target Sale", data.target)
                        )
                        .foregroundStyle(MatteTheme.Colors.info)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                    }

                    // Actual Sale Area (Success-Warning-Error)
                    ForEach(revenueData) { data in
                        AreaMark(
                            x: .value("Month", data.month),
                            y: .value("Actual Sale", data.actual)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    MatteTheme.Colors.success.opacity(0.55),
                                    MatteTheme.Colors.warning.opacity(0.35),
                                    MatteTheme.Colors.error.opacity(0.15)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    // Actual Sale Line (Gold/luxuryGold)
                    ForEach(revenueData) { data in
                        LineMark(
                            x: .value("Month", data.month),
                            y: .value("Actual Sale", data.actual)
                        )
                        .foregroundStyle(MatteTheme.Colors.luxuryGold)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                    }

                    // Thin vertical peak lines matching image 4
                    RuleMark(
                        x: .value("Month", "Jun")
                    )
                    .foregroundStyle(Color.gray.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    
                    RuleMark(
                        x: .value("Month", "Dec")
                    )
                    .foregroundStyle(Color.gray.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                    // Peak circle markers matching image 4
                    PointMark(
                        x: .value("Month", "Jun"),
                        y: .value("Target Sale", 25.0)
                    )
                    .symbol {
                        Circle()
                            .stroke(MatteTheme.Colors.info, lineWidth: 2)
                            .background(Circle().fill(Color.white))
                            .frame(width: 8, height: 8)
                    }

                    PointMark(
                        x: .value("Month", "Dec"),
                        y: .value("Actual Sale", 32.5)
                    )
                    .symbol {
                        Circle()
                            .stroke(MatteTheme.Colors.luxuryGold, lineWidth: 2)
                            .background(Circle().fill(Color.white))
                            .frame(width: 8, height: 8)
                    }
                    .annotation(position: .top, spacing: 6) {
                        Text("32.5 Cr")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue)) Cr")
                                    .font(.system(size: 9))
                                    .foregroundColor(MatteTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(MatteTheme.Colors.textTertiary)
                    }
                }
                .frame(height: 180)

                // Legends
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(MatteTheme.Colors.luxuryGold)
                            .frame(width: 8, height: 8)
                        Text("Actual Sale")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(MatteTheme.Colors.info)
                            .frame(width: 8, height: 8)
                        Text("Target Sale")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, -4)
            }
            .padding(MatteTheme.Spacing.cardPadding)
            .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.xlarge))
        }
    }

    // MARK: - Inventory Health Card

    private var inventoryHealthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(MatteTheme.Colors.success)
                Text("Inventory Health")
                    .font(MatteTheme.Typography.sectionHeader)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Spacer()
                Button(action: { onNavigateToOperations?() }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                inventoryMetric(label: "Stock Health", value: "87%", color: MatteTheme.Colors.success)
                inventoryMetric(label: "Transfers", value: "5", color: MatteTheme.Colors.warning)
                inventoryMetric(label: "Variances", value: "2", color: MatteTheme.Colors.error)
            }
            }
            .padding(MatteTheme.Spacing.cardPadding)
            .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.large))
        }
    }

    private func inventoryMetric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Notes & Reminders Card

    private var notesAndRemindersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                Text("Notes & Reminders")
                    .font(MatteTheme.Typography.sectionHeader)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 16) {
                // Clean Quick Note Input Widget
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        TextField("Write a quick note...", text: $newReminderTitle)
                            .font(MatteTheme.Typography.body)
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                        
                        if !newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                addReminder()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(MatteTheme.Colors.dashboardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MatteTheme.Colors.borderLight, lineWidth: 1)
                    )

                    // Optional Reminder Date/Time Trigger
                    HStack {
                        Button {
                            withAnimation {
                                showAddForm.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showAddForm ? "bell.fill" : "bell")
                                Text(showAddForm ? "Set: \(formattedReminderDateTime)" : "Add Reminder")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(showAddForm ? MatteTheme.Colors.luxuryGold : MatteTheme.Colors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(showAddForm ? MatteTheme.Colors.luxuryGold.opacity(0.12) : MatteTheme.Colors.subtleAccent)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    if showAddForm {
                        DatePicker("", selection: $newReminderDate, in: Date()...)
                            .datePickerStyle(.graphical)
                            .tint(MatteTheme.Colors.luxuryGold)
                            .labelsHidden()
                            .padding(.top, 4)
                    }
                }
                .padding(.bottom, 6)

                // Notes List (Apple Notes Design)
                if reminders.isEmpty {
                    VStack(spacing: 6) {
                        Text("No active notes.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    let pinned = visibleReminders.filter { $0.isPinned ?? false }
                    let unpinned = visibleReminders.filter { !($0.isPinned ?? false) }
                    
                    VStack(alignment: .leading, spacing: 14) {
                        if !pinned.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PINNED")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                                    .tracking(1.0)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    ForEach(pinned) { reminder in
                                        reminderRow(reminder)
                                        if reminder.id != pinned.last?.id {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                            }
                        }
                        
                        if !unpinned.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                if !pinned.isEmpty {
                                    Text("NOTES")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                        .tracking(1.0)
                                        .padding(.horizontal, 4)
                                        .padding(.top, 4)
                                }
                                
                                VStack(spacing: 0) {
                                    ForEach(unpinned) { reminder in
                                        reminderRow(reminder)
                                        if reminder.id != unpinned.last?.id {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                            }
                        }

                        // View More / View Less Toggle Button
                        if sortedReminders.count > 5 {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isNotesExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(isNotesExpanded ? "View Less" : "View More (\(sortedReminders.count))")
                                    Image(systemName: isNotesExpanded ? "chevron.up" : "chevron.down")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(MatteTheme.Spacing.cardPadding)
            .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.large))
        }
    }

    private var formattedReminderDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: newReminderDate)
    }

    private func addReminder() {
        let trimmed = newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newReminder = DashboardReminder(id: UUID(), title: trimmed, date: newReminderDate)
        reminders.append(newReminder)
        saveReminders()
        scheduleNotification(for: newReminder)
        
        newReminderTitle = ""
        newReminderDate = Date()
        withAnimation {
            showAddForm = false
        }
    }
    
    private func deleteReminder(_ reminder: DashboardReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
            reminders.remove(at: index)
            saveReminders()
        }
    }
    
    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: "dashboard_reminders")
        }
    }
    
    private func scheduleNotification(for reminder: DashboardReminder) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Luxe Maison Reminder"
            content.body = reminder.title
            content.sound = .default
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }

    // MARK: - Country Picker Sheet

    private var countryPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(countries, id: \.self) { country in
                    Button {
                        selectedCountry = country
                        let info = countryInfo(for: country)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            cameraPosition = .region(
                                MKCoordinateRegion(center: info.center, span: info.span)
                            )
                        }
                        showCountryPicker = false
                    } label: {
                        HStack(spacing: 14) {
                            Text(countryFlags[country] ?? "🌍")
                                .font(.system(size: 28))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(country)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(MatteTheme.Colors.textPrimary)
                                let info = countryInfo(for: country)
                                Text("\(info.boutiques.filter { $0.type != .warehouse }.count) Boutiques · 1 Warehouse")
                                    .font(.system(size: 12))
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if selectedCountry == country {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showCountryPicker = false
                    }
                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Boutiques Map Card

    private var boutiquesMapCard: some View {
        let info = countryInfo(for: selectedCountry)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                Text("Boutique Locations")
                    .font(MatteTheme.Typography.sectionHeader)
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 14) {
                // Country selector pill
            Button {
                showCountryPicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(countryFlags[selectedCountry] ?? "🌍")
                        .font(.system(size: 16))
                    Text(selectedCountry)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                    Spacer()
                    Text("\(info.boutiques.count) locations")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MatteTheme.Colors.luxuryGold.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(MatteTheme.Colors.dashboardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MatteTheme.Colors.borderLight, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Legend
            HStack(spacing: 14) {
                legendItem(color: .blue, text: "Warehouse")
                legendItem(color: .green, text: "Boutique")
                legendItem(color: .red, text: "Flagship")
                Spacer()
            }
            .padding(.bottom, 2)

            ZStack(alignment: .bottomTrailing) {
                Map(position: $cameraPosition) {
                    ForEach(info.boutiques) { pin in
                        Annotation(pin.name, coordinate: pin.coordinate) {
                            let cityName = pin.name.replacingOccurrences(of: " Boutique", with: "").replacingOccurrences(of: " Warehouse", with: "")
                            let boutiqueDetail = BoutiqueInventoryView.BoutiqueDetail(
                                name: pin.name,
                                city: cityName,
                                status: "Active",
                                manager: "Sarah Williams",
                                email: "manager@luxemaison.com"
                            )
                            
                            NavigationLink(destination: BoutiqueCityListView(cityName: cityName, boutiques: [boutiqueDetail])) {
                                VStack(spacing: 2) {
                                    Image(systemName: pin.type.icon)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(pin.type.color)
                                        .clipShape(Circle())
                                        .shadow(color: pin.type.color.opacity(0.4), radius: 4, y: 2)
                                    
                                    Text(pin.name)
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.95))
                                        .cornerRadius(4)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 260)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MatteTheme.Colors.borderLight, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }

                // Compact Apple-style Zoom and Recenter Controls
                VStack(spacing: 4) {
                    Button(action: { zoomIn() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)

                    Button(action: { zoomOut() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { resetToCountry(selectedCountry) }) {
                        Image(systemName: "scope")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
            }
            }
            .padding(MatteTheme.Spacing.cardPadding)
            .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.large))
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusInventoryOnMap"))) { notification in
                if let userInfo = notification.userInfo,
                   let countryName = userInfo["country"] as? String,
                   let inventoryName = userInfo["name"] as? String {
                    self.selectedCountry = countryName
                    let info = countryInfo(for: countryName)
                    if let pin = info.boutiques.first(where: { $0.name.localizedCaseInsensitiveContains(inventoryName) || inventoryName.localizedCaseInsensitiveContains($0.name) }) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: pin.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    private func zoomIn() {
        if let region = cameraPosition.region {
            let newSpan = MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta * 0.5,
                longitudeDelta: region.span.longitudeDelta * 0.5
            )
            withAnimation(.easeOut(duration: 0.3)) {
                cameraPosition = .region(MKCoordinateRegion(center: region.center, span: newSpan))
            }
        } else {
            let info = countryInfo(for: selectedCountry)
            let newSpan = MKCoordinateSpan(
                latitudeDelta: info.span.latitudeDelta * 0.5,
                longitudeDelta: info.span.longitudeDelta * 0.5
            )
            withAnimation(.easeOut(duration: 0.3)) {
                cameraPosition = .region(MKCoordinateRegion(center: info.center, span: newSpan))
            }
        }
    }

    private func zoomOut() {
        if let region = cameraPosition.region {
            let newSpan = MKCoordinateSpan(
                latitudeDelta: min(region.span.latitudeDelta * 2.0, 150.0),
                longitudeDelta: min(region.span.longitudeDelta * 2.0, 150.0)
            )
            withAnimation(.easeOut(duration: 0.3)) {
                cameraPosition = .region(MKCoordinateRegion(center: region.center, span: newSpan))
            }
        } else {
            let info = countryInfo(for: selectedCountry)
            let newSpan = MKCoordinateSpan(
                latitudeDelta: min(info.span.latitudeDelta * 2.0, 150.0),
                longitudeDelta: min(info.span.longitudeDelta * 2.0, 150.0)
            )
            withAnimation(.easeOut(duration: 0.3)) {
                cameraPosition = .region(MKCoordinateRegion(center: info.center, span: newSpan))
            }
        }
    }

    private func resetToCountry(_ country: String) {
        let info = countryInfo(for: country)
        withAnimation(.easeOut(duration: 0.3)) {
            cameraPosition = .region(MKCoordinateRegion(center: info.center, span: info.span))
        }
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
    }

    // MARK: - Helpers

    private var adminName: String {
        if let user = authManager.currentUser {
            let name = user.displayName
            return name.isEmpty ? user.username : name
        }
        return "Corporate Admin"
    }



    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    private var sortedReminders: [DashboardReminder] {
        reminders.sorted { r1, r2 in
            let p1 = r1.isPinned ?? false
            let p2 = r2.isPinned ?? false
            if p1 != p2 {
                return p1 && !p2
            }
            return r1.date > r2.date
        }
    }

    private var visibleReminders: [DashboardReminder] {
        let sorted = sortedReminders
        if isNotesExpanded || sorted.count <= 5 {
            return sorted
        } else {
            return Array(sorted.prefix(5))
        }
    }

    private func parseReminder(_ reminder: DashboardReminder) -> (title: String, desc: String) {
        let lines = reminder.title.components(separatedBy: .newlines)
        if let firstLine = lines.first, !firstLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let title = firstLine
            var desc = lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if desc.isEmpty {
                desc = "No additional text"
            }
            return (title, desc)
        }
        return (reminder.title, "No additional text")
    }

    private func formatNoteDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            return formatter.string(from: date)
        }
    }

    private func togglePin(_ reminder: DashboardReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isPinned = !(reminders[index].isPinned ?? false)
            saveReminders()
        }
    }

    private func reminderRow(_ reminder: DashboardReminder) -> some View {
        let (title, desc) = parseReminder(reminder)
        return SwipeToDeleteRow(onDelete: {
            deleteReminder(reminder)
        }) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if reminder.isPinned == true {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                        }
                        
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                    }
                    
                    HStack(spacing: 6) {
                        Text(formatNoteDate(reminder.date))
                            .font(.system(size: 13))
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if reminder.date > Date() {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 11))
                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .contextMenu {
            Button {
                togglePin(reminder)
            } label: {
                Label(reminder.isPinned == true ? "Unpin" : "Pin", systemImage: reminder.isPinned == true ? "pin.slash.fill" : "pin.fill")
            }
            Button(role: .destructive) {
                deleteReminder(reminder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Custom Swipe To Delete Row View Helper
struct SwipeToDeleteRow<Content: View>: View {
    var onDelete: () -> Void
    var content: () -> Content

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = -400
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onDelete()
                    offset = 0
                }
            } label: {
                ZStack {
                    Rectangle()
                        .fill(Color.red)
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(width: 70)
            }
            .opacity(offset == 0 ? 0 : 1)

            content()
                .glassEffect(.regular)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.width < 0 {
                                offset = gesture.translation.width
                            } else if gesture.translation.width > 0 && offset < 0 {
                                offset = min(0, -70 + gesture.translation.width)
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if gesture.translation.width < -60 || gesture.predictedEndTranslation.width < -60 {
                                    offset = -70
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
