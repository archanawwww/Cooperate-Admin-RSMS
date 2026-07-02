import SwiftUI
import Charts

// MARK: - Boutiques & Inventory Hub View
struct BoutiqueInventoryView: View {
    @State private var selectedSegment = 0 // 0 = Boutiques, 1 = Inventory
    @State private var searchText = ""
    @State private var showFilters = false

    // Country Data Models
    struct CountryData: Identifiable {
        let id = UUID()
        let name: String
        let flag: String
        let boutiqueCount: Int
        let boutiques: [BoutiqueDetail]
        let inventories: [InventoryDetail]
    }

    struct BoutiqueDetail: Identifiable {
        let id = UUID()
        let name: String
        let city: String
        let status: String // "Active", "Under Review"
        let manager: String
        let email: String
    }

    struct InventoryDetail: Identifiable {
        let id = UUID()
        let name: String
        let stockLevel: String // "Optimal", "Low Stock", "High Stock"
        let totalItems: Int
        let valuation: String
    }

    // Static sample data matching screenshots and user prompt
    private let countriesData: [CountryData] = [
        CountryData(
            name: "India", flag: "🇮🇳", boutiqueCount: 38,
            boutiques: [
                BoutiqueDetail(name: "Mumbai Colaba Boutique", city: "Mumbai", status: "Active", manager: "Rohan Sharma", email: "rohan.s@luxemaison.com"),
                BoutiqueDetail(name: "Delhi Chanakyapuri Flagship", city: "New Delhi", status: "Active", manager: "Priya Patel", email: "priya.p@luxemaison.com"),
                BoutiqueDetail(name: "Bangalore UB City Boutique", city: "Bangalore", status: "Active", manager: "Amit Roy", email: "amit.r@luxemaison.com"),
                BoutiqueDetail(name: "Chennai Nungambakkam Boutique", city: "Chennai", status: "Active", manager: "Sunita Nair", email: "sunita.n@luxemaison.com"),
                BoutiqueDetail(name: "Hyderabad Jubilee Hills Boutique", city: "Hyderabad", status: "Active", manager: "Vikram Reddy", email: "vikram.r@luxemaison.com"),
                BoutiqueDetail(name: "Kolkata Park Street Boutique", city: "Kolkata", status: "Under Review", manager: "Neha Bose", email: "neha.b@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Mumbai Regional Warehouse", stockLevel: "Optimal", totalItems: 14200, valuation: "₹12.5 Cr"),
                InventoryDetail(name: "Delhi Transit Hub", stockLevel: "Optimal", totalItems: 8500, valuation: "₹8.2 Cr"),
                InventoryDetail(name: "Bangalore Logistics Center", stockLevel: "Low Stock", totalItems: 3200, valuation: "₹3.1 Cr")
            ]
        ),
        CountryData(
            name: "United Arab Emirates", flag: "🇦🇪", boutiqueCount: 24,
            boutiques: [
                BoutiqueDetail(name: "Dubai Mall Flagship", city: "Dubai", status: "Active", manager: "Zayn Malik", email: "zayn.m@luxemaison.com"),
                BoutiqueDetail(name: "Abu Dhabi Galleria Boutique", city: "Abu Dhabi", status: "Active", manager: "Fatima Al-Sayed", email: "fatima.a@luxemaison.com"),
                BoutiqueDetail(name: "Sharjah Corniche Boutique", city: "Sharjah", status: "Active", manager: "Omar Hashmi", email: "omar.h@luxemaison.com"),
                BoutiqueDetail(name: "Ajman City Boutique", city: "Ajman", status: "Under Review", manager: "Sarah Connor", email: "sarah.c@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Dubai Freezone Warehouse", stockLevel: "Optimal", totalItems: 22000, valuation: "₹18.6 Cr"),
                InventoryDetail(name: "Abu Dhabi Distribution Point", stockLevel: "Optimal", totalItems: 9100, valuation: "₹7.4 Cr")
            ]
        ),
        CountryData(
            name: "Saudi Arabia", flag: "🇸🇦", boutiqueCount: 20,
            boutiques: [
                BoutiqueDetail(name: "Riyadh Olaya Flagship", city: "Riyadh", status: "Active", manager: "Youssef Harb", email: "youssef.h@luxemaison.com"),
                BoutiqueDetail(name: "Jeddah Tahlia Boutique", city: "Jeddah", status: "Active", manager: "Yasmin Farooq", email: "yasmin.f@luxemaison.com"),
                BoutiqueDetail(name: "Khobar Mall Boutique", city: "Al Khobar", status: "Under Review", manager: "Fahad Saud", email: "fahad.s@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Riyadh Central Depot", stockLevel: "Optimal", totalItems: 16500, valuation: "₹14.2 Cr")
            ]
        ),
        CountryData(
            name: "United Kingdom", flag: "🇬🇧", boutiqueCount: 16,
            boutiques: [
                BoutiqueDetail(name: "London Bond Street Flagship", city: "London", status: "Active", manager: "Charles Windsor", email: "charles.w@luxemaison.com"),
                BoutiqueDetail(name: "Harrods Exclusive Salon", city: "London", status: "Active", manager: "Diana Spencer", email: "diana.s@luxemaison.com"),
                BoutiqueDetail(name: "Manchester Selfridges Boutique", city: "Manchester", status: "Active", manager: "George Best", email: "george.b@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Heathrow Bonded Warehouse", stockLevel: "Optimal", totalItems: 18400, valuation: "₹16.8 Cr"),
                InventoryDetail(name: "Birmingham Logistics Hub", stockLevel: "Low Stock", totalItems: 2800, valuation: "₹2.2 Cr")
            ]
        ),
        CountryData(
            name: "France", flag: "🇫🇷", boutiqueCount: 12,
            boutiques: [
                BoutiqueDetail(name: "Paris Champs-Élysées Flagship", city: "Paris", status: "Active", manager: "Pierre Dupont", email: "pierre.d@luxemaison.com"),
                BoutiqueDetail(name: "Nice Promenade Boutique", city: "Nice", status: "Active", manager: "Marie Curie", email: "marie.c@luxemaison.com"),
                BoutiqueDetail(name: "Lyon Presqu'île Boutique", city: "Lyon", status: "Under Review", manager: "Jean Reno", email: "jean.r@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Charles de Gaulle Cargo Hub", stockLevel: "Optimal", totalItems: 19500, valuation: "₹17.4 Cr")
            ]
        ),
        CountryData(
            name: "Singapore", flag: "🇸🇬", boutiqueCount: 8,
            boutiques: [
                BoutiqueDetail(name: "Marina Bay Sands Flagship", city: "Singapore", status: "Active", manager: "Lee Hsien", email: "lee.h@luxemaison.com"),
                BoutiqueDetail(name: "Orchard Road Boutique", city: "Singapore", status: "Active", manager: "Jane Tan", email: "jane.t@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Changi Airport Depot", stockLevel: "Optimal", totalItems: 8200, valuation: "₹7.9 Cr")
            ]
        ),
        CountryData(
            name: "United States", flag: "🇺🇸", boutiqueCount: 5,
            boutiques: [
                BoutiqueDetail(name: "Beverly Hills Flagship", city: "Los Angeles", status: "Active", manager: "Michael Jordan", email: "michael.j@luxemaison.com"),
                BoutiqueDetail(name: "NY Fifth Avenue Boutique", city: "New York", status: "Active", manager: "Sarah Parker", email: "sarah.p@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "JFK Airport Logistics Center", stockLevel: "Optimal", totalItems: 15400, valuation: "₹13.5 Cr")
            ]
        ),
        CountryData(
            name: "Australia", flag: "🇦🇺", boutiqueCount: 5,
            boutiques: [
                BoutiqueDetail(name: "Sydney Castlereagh Flagship", city: "Sydney", status: "Active", manager: "Kylie Minogue", email: "kylie.m@luxemaison.com"),
                BoutiqueDetail(name: "Melbourne Collins St Boutique", city: "Melbourne", status: "Active", manager: "Hugh Jackman", email: "hugh.j@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Sydney Mascot Warehouse", stockLevel: "Optimal", totalItems: 6700, valuation: "₹5.8 Cr")
            ]
        ),
        CountryData(
            name: "Germany", flag: "🇩🇪", boutiqueCount: 6,
            boutiques: [
                BoutiqueDetail(name: "Berlin Friedrichstraße Boutique", city: "Berlin", status: "Active", manager: "Hans Müller", email: "hans.m@luxemaison.com"),
                BoutiqueDetail(name: "Munich Maximilianstraße Flagship", city: "Munich", status: "Active", manager: "Klaus Schmidt", email: "klaus.s@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Frankfurt Cargo City Warehouse", stockLevel: "Optimal", totalItems: 11000, valuation: "₹9.2 Cr")
            ]
        ),
        CountryData(
            name: "Japan", flag: "🇯🇵", boutiqueCount: 7,
            boutiques: [
                BoutiqueDetail(name: "Ginza Flagship Salon", city: "Tokyo", status: "Active", manager: "Ken Watanabe", email: "ken.w@luxemaison.com"),
                BoutiqueDetail(name: "Osaka Shinsaibashi Boutique", city: "Osaka", status: "Active", manager: "Yoko Ono", email: "yoko.o@luxemaison.com")
            ],
            inventories: [
                InventoryDetail(name: "Narita Airport Distribution Center", stockLevel: "Optimal", totalItems: 12500, valuation: "₹10.8 Cr")
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Custom Luxury Segmented Control
                    customSegmentedControl

                    // Dynamic overview metric cards
                    overviewSection

                    // Top/Main Countries Section
                    countriesSection
                }
                .padding(.horizontal, MatteTheme.Spacing.horizontalMargin)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Executive Hub")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Custom Luxury Segmented Control
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedSegment = 0
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 14))
                    Text("Boutiques")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    selectedSegment == 0 ?
                    LinearGradient(
                        colors: [Color(red: 175/255, green: 135/255, blue: 75/255), Color(red: 200/255, green: 165/255, blue: 100/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                )
                .foregroundColor(selectedSegment == 0 ? .white : MatteTheme.Colors.textSecondary)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedSegment = 1
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 14))
                    Text("Inventory")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    selectedSegment == 1 ?
                    LinearGradient(
                        colors: [Color(red: 175/255, green: 135/255, blue: 75/255), Color(red: 200/255, green: 165/255, blue: 100/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                )
                .foregroundColor(selectedSegment == 1 ? .white : MatteTheme.Colors.textSecondary)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    // MARK: - Overview Cards Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Overview")
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundColor(MatteTheme.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                if selectedSegment == 0 {
                    // Boutiques Metrics
                    overviewCard(title: "Total Boutiques", value: "128", sub: "Across 14 Countries")
                    overviewCard(title: "Active Boutiques", value: "112", sub: "87.5% Active")
                } else {
                    // Inventory Metrics
                    overviewCard(title: "Total Valuation", value: "₹45.2 Cr", sub: "Avg Asset Value")
                    overviewCard(title: "Active Warehouses", value: "10", sub: "100% Operational")
                }
            }
        }
    }

    private func overviewCard(title: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(MatteTheme.Colors.textPrimary)
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MatteTheme.Colors.textPrimary)
            
            Text(sub)
                .font(.system(size: 11))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Countries List Section
    private var countriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Top Countries")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
                Spacer()
                NavigationLink(destination: AllCountriesListView(selectedSegment: selectedSegment, countriesData: countriesData)) {
                    Text("View All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 175/255, green: 135/255, blue: 75/255))
                }
            }

            VStack(spacing: 10) {
                // Show first 5 countries
                ForEach(countriesData.prefix(5)) { country in
                    NavigationLink(destination: CountryDetailView(selectedSegment: selectedSegment, country: country)) {
                        HStack(spacing: 14) {
                            Text(country.flag)
                                .font(.system(size: 24))
                            
                            Text(country.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MatteTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text(selectedSegment == 0 ? "\(country.boutiqueCount) Boutiques" : "\(country.inventories.count) Warehouses")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(MatteTheme.Colors.textTertiary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .glassEffect(.regular, in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - View All Countries Screen
struct AllCountriesListView: View {
    let selectedSegment: Int
    let countriesData: [BoutiqueInventoryView.CountryData]
    @State private var searchText = ""

    var filteredCountries: [BoutiqueInventoryView.CountryData] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return countriesData
        }
        return countriesData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                    TextField(selectedSegment == 0 ? "Search country or boutiques..." : "Search country or warehouse...", text: $searchText)
                        .font(.system(size: 15))
                }
                .padding(10)
                .background(Color(red: 245/255, green: 242/255, blue: 236/255))
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Select a country to view its \(selectedSegment == 0 ? "boutiques" : "inventory")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(spacing: 10) {
                        ForEach(filteredCountries) { country in
                            NavigationLink(destination: CountryDetailView(selectedSegment: selectedSegment, country: country)) {
                                HStack(spacing: 14) {
                                    Text(country.flag)
                                        .font(.system(size: 26))
                                    
                                    Text(country.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(selectedSegment == 0 ? "\(country.boutiqueCount) Boutiques" : "\(country.inventories.count) Warehouses")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(MatteTheme.Colors.textTertiary)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .background(MatteTheme.Colors.dashboardBackground)
        }
        .navigationTitle(selectedSegment == 0 ? "Boutiques" : "Inventory")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Country Detail Detail list of boutiques or inventory
struct CountryDetailView: View {
    let selectedSegment: Int
    let country: BoutiqueInventoryView.CountryData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if selectedSegment == 0 {
                    Text("Select a boutique to view details")
                        .font(.system(size: 13, weight: .medium, design: .serif).italic())
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                        .padding(.top, 4)

                    // Group boutiques by city
                    let grouped = Dictionary(grouping: country.boutiques, by: { $0.city })
                    let cities = Array(grouped.keys).sorted()
                    let imageNames = ["login", "dxb 💫", " -4"]

                    VStack(spacing: 16) {
                        ForEach(Array(cities.enumerated()), id: \.element) { index, city in
                            let boutiquesInCity = grouped[city] ?? []
                            let imgName = imageNames[index % imageNames.count]
                            
                            NavigationLink(destination: BoutiqueCityListView(cityName: city, boutiques: boutiquesInCity)) {
                                ZStack(alignment: .bottomLeading) {
                                    // Background Store Image
                                    Image(imgName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                    
                                    // Dark luxury gradient overlay
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.65), Color.black.opacity(0.2)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                    
                                    // LUXE MAISON logo at top center
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Text("LUXE MAISON")
                                                .font(.system(size: 11, weight: .bold, design: .serif))
                                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                                                .tracking(2.0)
                                            Spacer()
                                        }
                                        .padding(.top, 16)
                                        Spacer()
                                    }
                                    
                                    // Bottom Content overlay
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(city)
                                                .font(.system(size: 24, weight: .medium, design: .serif))
                                                .foregroundColor(.white)
                                            
                                            let codePrefix = city.replacingOccurrences(of: "New ", with: "").prefix(3).uppercased()
                                            Text("Store Code: LM-\(codePrefix)-001")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        .padding(.leading, 20)
                                        .padding(.bottom, 20)
                                        
                                        Spacer()
                                        
                                        // Circular white arrow button
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                        .padding(.trailing, 20)
                                        .padding(.bottom, 20)
                                    }
                                }
                                .frame(height: 200)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Bottom status bar matching mockup
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 18))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Boutiques")
                                    .font(.system(size: 9))
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                                Text("\(country.boutiqueCount)")
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                                    .foregroundColor(MatteTheme.Colors.textPrimary)
                            }
                        }
                        
                        Spacer()
                        
                        Divider()
                            .frame(height: 24)
                            .background(MatteTheme.Colors.border)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(MatteTheme.Colors.success)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Active Boutiques")
                                    .font(.system(size: 9))
                                    .foregroundColor(MatteTheme.Colors.textSecondary)
                                Text("\(Int(Double(country.boutiqueCount) * 0.9))")
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                                    .foregroundColor(MatteTheme.Colors.textPrimary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: .rect(cornerRadius: 14))
                    .padding(.top, 10)
                } else {
                    // Header Banner (Only show for Inventory warehouses)
                    HStack(spacing: 16) {
                        Text(country.flag)
                            .font(.system(size: 48))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(country.name)
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .foregroundColor(MatteTheme.Colors.textPrimary)
                            
                            Text("\(country.inventories.count) Distribution Warehouses")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))

                    Text("Asset Inventory")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(MatteTheme.Colors.textPrimary)

                    // Inventory Detail List
                    ForEach(country.inventories) { item in
                        Button(action: {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FocusInventoryOnMap"),
                                object: nil,
                                userInfo: [
                                    "country": country.name,
                                    "name": item.name
                                ]
                            )
                        }) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                    Spacer()
                                    Text(item.stockLevel)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(item.stockLevel == "Optimal" ? MatteTheme.Colors.success : MatteTheme.Colors.warning)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(item.stockLevel == "Optimal" ? MatteTheme.Colors.successLight : MatteTheme.Colors.warningLight)
                                        .cornerRadius(6)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Image(systemName: "shippingbox.fill")
                                        .foregroundColor(MatteTheme.Colors.luxuryGold)
                                    Text("\(item.totalItems) units")
                                        .font(.system(size: 12))
                                        .foregroundColor(MatteTheme.Colors.textSecondary)
                                    Spacer()
                                    Image(systemName: "indianrupeesign.circle.fill")
                                        .foregroundColor(MatteTheme.Colors.success)
                                    Text(item.valuation)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(MatteTheme.Colors.textPrimary)
                                }
                            }
                            .padding(16)
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(MatteTheme.Colors.dashboardBackground)
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(selectedSegment == 0)
        .toolbar {
            if selectedSegment == 0 {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { /* search action */ }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Boutique City List View (Boutiques in a specific city)
struct BoutiqueCityListView: View {
    let cityName: String
    let boutiques: [BoutiqueInventoryView.BoutiqueDetail]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var showCalendarPicker = false
    
    // Sparkline dummy data points
    private let revenuePoints: [Double] = [32.0, 34.5, 33.0, 38.2, 36.8, 41.5, 40.0, 48.7]
    private let orderPoints: [Double] = [710, 750, 730, 780, 765, 810, 800, 842]
    private let customerPoints: [Double] = [540, 565, 550, 582, 570, 605, 595, 632]
    private let conversionPoints: [Double] = [62.5, 64.0, 63.2, 65.8, 64.5, 66.7, 65.5, 68.4]
    
    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthStr = formatter.string(from: selectedDate)
        
        let calendar = Calendar.current
        if let range = calendar.range(of: .day, in: .month, for: selectedDate) {
            return "1 – \(range.count) \(monthStr)"
        }
        return "1 – 31 \(monthStr)"
    }
    
    var body: some View {
        let boutique = boutiques.first ?? BoutiqueInventoryView.BoutiqueDetail(name: "\(cityName) Boutique", city: cityName, status: "Active", manager: "Sarah Williams", email: "sarah@luxemaison.com")
        let codePrefix = cityName.replacingOccurrences(of: "New ", with: "").prefix(3).uppercased()
        
        ScrollView {
            VStack(spacing: 20) {
                // Top Insights Banner Card
                ZStack(alignment: .bottomLeading) {
                    // Background Image of the store
                    Image(" -4")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                    
                    // Dark gradient overlay
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.black.opacity(0.3)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    
                    // Text layout inside the card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Boutique Insights")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Monthly Insights")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                            Text(formattedDateRange)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
                .frame(height: 180)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
                
                // 2x2 Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    metricMiniCard(
                        icon: "indianrupeesign.circle.fill",
                        title: "Total Revenue",
                        value: "₹48.7L",
                        trend: "↑ 12.6% vs Apr 2025",
                        points: revenuePoints,
                        accentColor: MatteTheme.Colors.luxuryGold
                    )
                    
                    metricMiniCard(
                        icon: "bag.circle.fill",
                        title: "Total Orders",
                        value: "842",
                        trend: "↑ 8.3% vs Apr 2025",
                        points: orderPoints,
                        accentColor: MatteTheme.Colors.info
                    )
                    
                    metricMiniCard(
                        icon: "person.2.circle.fill",
                        title: "Total Customers",
                        value: "632",
                        trend: "↑ 10.1% vs Apr 2025",
                        points: customerPoints,
                        accentColor: MatteTheme.Colors.accent
                    )
                    
                    metricMiniCard(
                        icon: "percent",
                        title: "Conversion Rate",
                        value: "68.4%",
                        trend: "↑ 5.7% vs Apr 2025",
                        points: conversionPoints,
                        accentColor: MatteTheme.Colors.success
                    )
                }
                
                // Active Staff & Boutique Manager row card
                HStack(spacing: 14) {
                    // Active Staff
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(MatteTheme.Colors.info)
                            Text("Active Staff")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        }
                        
                        Text("18")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                        
                        Text("Average Active Staff")
                            .font(.system(size: 9))
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                        
                        Text("↑ 2 vs Apr 2025")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MatteTheme.Colors.success)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .glassEffect(.regular, in: .rect(cornerRadius: 14))
                    
                    // Manager Overview Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .font(.system(size: 14))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                            Text("Boutique Manager")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        }
                        
                        Text(boutique.manager.components(separatedBy: " ").first ?? "Sarah")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Text("Senior Manager")
                            .font(.system(size: 9))
                            .foregroundColor(MatteTheme.Colors.textTertiary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(MatteTheme.Colors.success)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(MatteTheme.Colors.success)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .glassEffect(.regular, in: .rect(cornerRadius: 14))
                }
                
                // Profile Detail card
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(MatteTheme.Colors.luxuryGold.opacity(0.12))
                                .frame(width: 64, height: 64)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 54))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(boutique.manager)
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(MatteTheme.Colors.textPrimary)
                            
                            Text("Senior Boutique Manager")
                                .font(.system(size: 12))
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                            
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(MatteTheme.Colors.success)
                                        .frame(width: 6, height: 6)
                                    Text("Active")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(MatteTheme.Colors.success)
                                }
                                
                                Text("Joined Jan 2023")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(MatteTheme.Colors.textTertiary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { /* Profile detail sheet */ }) {
                            HStack(spacing: 2) {
                                Text("View Profile")
                                    .font(.system(size: 11, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(MatteTheme.Colors.luxuryGold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(MatteTheme.Colors.subtleAccent)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                
                // Bottom quick reports grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        actionPill(icon: "doc.text.fill", title: "Generate Report", desc: "Create detailed performance report")
                        actionPill(icon: "arrow.down.doc.fill", title: "Export Report", desc: "Export data in PDF / Excel")
                        actionPill(icon: "phone.circle.fill", title: "Contact Manager", desc: "Call or message boutique manager")
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
        .background(MatteTheme.Colors.dashboardBackground)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("\(cityName) Boutique")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                    Text("Store Code: LM-\(codePrefix)-001")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCalendarPicker = true }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showCalendarPicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Select Month")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                        .padding(.top, 24)
                    
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .tint(MatteTheme.Colors.luxuryGold)
                        .labelsHidden()
                        .padding()
                    
                    Button(action: { showCalendarPicker = false }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(MatteTheme.Colors.luxuryGold)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .background(MatteTheme.Colors.dashboardBackground)
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private func metricMiniCard(icon: String, title: String, value: String, trend: String, points: [Double], accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MatteTheme.Colors.textSecondary)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(MatteTheme.Colors.textPrimary)
            
            Text(trend)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MatteTheme.Colors.success)
            
            // Sparkline graph
            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { index, pt in
                    LineMark(
                        x: .value("Day", index),
                        y: .value("Value", pt)
                    )
                    .foregroundStyle(accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Day", index),
                        y: .value("Value", pt)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor.opacity(0.15), accentColor.opacity(0.0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 35)
            .padding(.top, 4)
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
      }
      
      private func actionPill(icon: String, title: String, desc: String) -> some View {
          HStack(spacing: 12) {
              ZStack {
                  Circle()
                      .fill(MatteTheme.Colors.luxuryGold.opacity(0.12))
                      .frame(width: 40, height: 40)
                  Image(systemName: icon)
                      .font(.system(size: 16))
                      .foregroundColor(MatteTheme.Colors.luxuryGold)
              }
              
              VStack(alignment: .leading, spacing: 2) {
                  Text(title)
                      .font(.system(size: 13, weight: .bold))
                      .foregroundColor(MatteTheme.Colors.textPrimary)
                  Text(desc)
                      .font(.system(size: 10))
                      .foregroundColor(MatteTheme.Colors.textSecondary)
              }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .glassEffect(.regular, in: .rect(cornerRadius: 12))
      }
}
