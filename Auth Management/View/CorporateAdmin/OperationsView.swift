import SwiftUI
import Charts

// MARK: - Operations View (Tab 3)

/// Tab 3 — Promotions & Campaigns, Planograms, Sales Reports,
/// Inventory Health, Unified Business Reports, Campaign Analytics.
struct OperationsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showProfile = false
    @State private var selectedMonth: String? = "Mar"

    // Section expansion
    @State private var expandedSection: OpsSection? = .promotions

    enum OpsSection: String, CaseIterable {
        case promotions = "Promotions & Campaigns"
        case planograms = "Planograms & Merchandising"
        case salesReports = "Sales Reports"
        case inventoryHealth = "Inventory Health"
        case businessReports = "Unified Business Reports"
        case campaignAnalytics = "Campaign Analytics"
    }

    // MARK: - Mock Promotion Data

    private struct MockPromotion: Identifiable {
        let id = UUID()
        let title: String
        let status: String
        let statusColor: Color
        let discount: String
        let dateRange: String
        let reach: String
    }

    private let mockPromotions: [MockPromotion] = [
        .init(title: "Monsoon Luxury Sale", status: "Active", statusColor: MatteTheme.Colors.success, discount: "15% Off", dateRange: "Jun 15 – Jul 31", reach: "2,400"),
        .init(title: "Diwali Celebration", status: "Draft", statusColor: MatteTheme.Colors.warning, discount: "20% Off", dateRange: "Oct 15 – Nov 15", reach: "—"),
        .init(title: "Summer Clearance", status: "Expired", statusColor: MatteTheme.Colors.textTertiary, discount: "₹5,000 Flat", dateRange: "Apr 1 – May 31", reach: "1,850"),
        .init(title: "Heritage Collection Launch", status: "Active", statusColor: MatteTheme.Colors.success, discount: "10% Off", dateRange: "Jun 1 – Aug 31", reach: "3,200")
    ]

    // MARK: - Mock Planogram Data

    private struct MockPlanogram: Identifiable {
        let id = UUID()
        let title: String
        let version: String
        let store: String
        let status: String
        let statusColor: Color
    }

    private let mockPlanograms: [MockPlanogram] = [
        .init(title: "Monsoon Window Display V2", version: "2.0", store: "Mumbai Flagship", status: "Published", statusColor: MatteTheme.Colors.success),
        .init(title: "Heritage Wall Layout", version: "1.0", store: "Delhi Boutique", status: "Pending", statusColor: MatteTheme.Colors.warning),
        .init(title: "Accessories Island Refresh", version: "3.1", store: "Bangalore Store", status: "Compliant", statusColor: MatteTheme.Colors.info),
        .init(title: "Watch Showcase Redesign", version: "1.0", store: "Chennai Mall", status: "Draft", statusColor: MatteTheme.Colors.textTertiary)
    ]

    // MARK: - Revenue Chart Data

    private struct MonthlyRevenue: Identifiable {
        let id = UUID()
        let month: String
        let revenue: Double
        let target: Double
    }

    private let monthlyRevenue = [
        MonthlyRevenue(month: "Jan", revenue: 14.2, target: 15.0),
        MonthlyRevenue(month: "Feb", revenue: 20.8, target: 20.0),
        MonthlyRevenue(month: "Mar", revenue: 19.0, target: 22.0),
        MonthlyRevenue(month: "Apr", revenue: 20.1, target: 19.5),
        MonthlyRevenue(month: "May", revenue: 22.5, target: 21.0),
        MonthlyRevenue(month: "Jun", revenue: 24.5, target: 22.0)
    ]

    // MARK: - Category Sales Data

    private struct CategorySale: Identifiable {
        let id = UUID()
        let category: String
        let revenue: Double
        let color: Color
    }

    private let categorySales = [
        CategorySale(category: "Handbags", revenue: 8.5, color: MatteTheme.Colors.luxuryGold),
        CategorySale(category: "Watches", revenue: 6.2, color: MatteTheme.Colors.info),
        CategorySale(category: "Accessories", revenue: 4.8, color: MatteTheme.Colors.success),
        CategorySale(category: "Shoes", revenue: 3.2, color: MatteTheme.Colors.accent),
        CategorySale(category: "Apparel", revenue: 1.8, color: MatteTheme.Colors.warning)
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MatteTheme.Spacing.sectionSpacing) {
                    operationsHeader

                    // Promotions & Campaigns
                    operationsSectionCard(
                        section: .promotions,
                        icon: "megaphone.fill",
                        iconColor: MatteTheme.Colors.luxuryGold,
                        badge: "\(mockPromotions.filter { $0.status == "Active" }.count) Active"
                    ) {
                        promotionsContent
                    }

                    // Planograms & Merchandising
                    operationsSectionCard(
                        section: .planograms,
                        icon: "rectangle.split.3x3",
                        iconColor: MatteTheme.Colors.info,
                        badge: "\(mockPlanograms.count) Total"
                    ) {
                        planogramsContent
                    }

                    // Sales Reports
                    operationsSectionCard(
                        section: .salesReports,
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: MatteTheme.Colors.success,
                        badge: "Q2 2026"
                    ) {
                        salesReportsContent
                    }

                    // Inventory Health (Read Only)
                    operationsSectionCard(
                        section: .inventoryHealth,
                        icon: "heart.text.square.fill",
                        iconColor: MatteTheme.Colors.success,
                        badge: "Read Only"
                    ) {
                        inventoryHealthContent
                    }

                    // Unified Business Reports
                    operationsSectionCard(
                        section: .businessReports,
                        icon: "doc.text.magnifyingglass",
                        iconColor: MatteTheme.Colors.accent,
                        badge: "Comprehensive"
                    ) {
                        businessReportsContent
                    }

                    // Campaign Effectiveness Analytics
                    operationsSectionCard(
                        section: .campaignAnalytics,
                        icon: "chart.bar.xaxis",
                        iconColor: MatteTheme.Colors.luxuryGold,
                        badge: "Analytics"
                    ) {
                        campaignAnalyticsContent
                    }
                }
                .padding(.horizontal, MatteTheme.Spacing.horizontalMargin)
                .padding(.top, MatteTheme.Spacing.lg)
                .padding(.bottom, 100)
            }
            .background(MatteTheme.Colors.dashboardBackground.ignoresSafeArea())
            .navigationTitle("Operations")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(showProfile: $showProfile)
        }
    }

    // MARK: - Header

    private var operationsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Operations")
                .font(MatteTheme.Typography.largeTitle)
                .foregroundColor(MatteTheme.Colors.textPrimary)
            Text("Campaigns, reports & business analytics")
                .font(MatteTheme.Typography.caption)
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    // MARK: - Section Card Builder

    @ViewBuilder
    private func operationsSectionCard<Content: View>(
        section: OpsSection,
        icon: String,
        iconColor: Color,
        badge: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedSection = expandedSection == section ? nil : section
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                        .frame(width: 38, height: 38)
                        .background(iconColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.rawValue)
                            .font(MatteTheme.Typography.headline)
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                    }

                    Spacer()

                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(iconColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(iconColor.opacity(0.12))
                        .cornerRadius(8)

                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textTertiary)
                }
                .padding(MatteTheme.Spacing.cardPadding)
            }
            .buttonStyle(.plain)

            if expandedSection == section {
                Divider()
                    .padding(.horizontal, MatteTheme.Spacing.cardPadding)

                content()
                    .padding(MatteTheme.Spacing.cardPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: MatteTheme.CornerRadius.large))
    }

    // MARK: - Promotions & Campaigns Content

    @ViewBuilder
    private var promotionsContent: some View {
        VStack(spacing: 14) {
            // Summary Stats
            HStack(spacing: 0) {
                promoStat(value: "4", label: "Total", color: MatteTheme.Colors.textPrimary)
                Divider().frame(height: 32)
                promoStat(value: "2", label: "Active", color: MatteTheme.Colors.success)
                Divider().frame(height: 32)
                promoStat(value: "1", label: "Draft", color: MatteTheme.Colors.warning)
                Divider().frame(height: 32)
                promoStat(value: "1", label: "Expired", color: MatteTheme.Colors.textTertiary)
            }
            .padding(.vertical, 10)
            .background(MatteTheme.Colors.dashboardBackground)
            .cornerRadius(12)

            // Promotion Cards
            ForEach(mockPromotions) { promo in
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(promo.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)

                        HStack(spacing: 8) {
                            Text(promo.discount)
                                .font(.caption.weight(.bold))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)

                            Text("•")
                                .foregroundColor(MatteTheme.Colors.textTertiary)

                            Text(promo.dateRange)
                                .font(.caption)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        }

                        if promo.reach != "—" {
                            Text("Reach: \(promo.reach) customers")
                                .font(.system(size: 10))
                                .foregroundColor(MatteTheme.Colors.textTertiary)
                        }
                    }

                    Spacer()

                    Text(promo.status)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(promo.statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(promo.statusColor.opacity(0.12))
                        .cornerRadius(8)
                }
                .padding(.vertical, 6)

                if promo.id != mockPromotions.last?.id {
                    Divider()
                }
            }
        }
    }

    private func promoStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Planograms Content

    @ViewBuilder
    private var planogramsContent: some View {
        VStack(spacing: 12) {
            ForEach(mockPlanograms) { planogram in
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(planogram.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)

                        HStack(spacing: 8) {
                            Text("v\(planogram.version)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)

                            Text("•")
                                .foregroundColor(MatteTheme.Colors.textTertiary)

                            Text(planogram.store)
                                .font(.caption)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    Text(planogram.status)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(planogram.statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(planogram.statusColor.opacity(0.12))
                        .cornerRadius(8)
                }
                .padding(.vertical, 6)

                if planogram.id != mockPlanograms.last?.id {
                    Divider()
                }
            }
        }
    }

    // MARK: - Sales Reports Content

    @ViewBuilder
    private var salesReportsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Key Metrics Row
            HStack(spacing: 0) {
                reportMetric(value: "₹48.5L", label: "Total Revenue", color: MatteTheme.Colors.luxuryGold)
                Divider().frame(height: 36)
                reportMetric(value: "312", label: "Transactions", color: MatteTheme.Colors.info)
                Divider().frame(height: 36)
                reportMetric(value: "₹15,545", label: "Avg. Value", color: MatteTheme.Colors.success)
            }
            .padding(.vertical, 12)
            .background(MatteTheme.Colors.dashboardBackground)
            .cornerRadius(12)

            // Revenue Chart
            VStack(alignment: .leading, spacing: 14) {
                // Header (VStack)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REVENUE TREND")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MatteTheme.Colors.luxuryGold.opacity(0.8))
                            .kerning(1)
                        
                        Text("₹24.5 Crore")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("↑ ₹2.5 Cr above June target")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MatteTheme.Colors.success)
                    }
                    
                    Spacer()
                    
                    // ON TRACK badge
                    Text("ON TRACK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MatteTheme.Colors.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            Capsule()
                                .stroke(MatteTheme.Colors.success.opacity(0.6), lineWidth: 1)
                        )
                }
                .padding(.bottom, 6)

                // Chart Container with Overlay selection tooltip
                ZStack(alignment: .topLeading) {
                    Chart {
                        // 1. Target line (dashed, blue)
                        ForEach(monthlyRevenue) { data in
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Target", data.target)
                            )
                            .foregroundStyle(MatteTheme.Colors.info)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .interpolationMethod(.catmullRom)
                        }

                        // 2. Actual line (solid, gold)
                        ForEach(monthlyRevenue) { data in
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Actual", data.revenue)
                            )
                            .foregroundStyle(MatteTheme.Colors.luxuryGold)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .interpolationMethod(.catmullRom)
                        }

                        // 3. Target points (circles)
                        ForEach(monthlyRevenue) { data in
                            PointMark(
                                x: .value("Month", data.month),
                                y: .value("Target", data.target)
                            )
                            .symbol {
                                Circle()
                                    .stroke(MatteTheme.Colors.info, lineWidth: 2)
                                    .background(Circle().fill(Color.white))
                                    .frame(width: 8, height: 8)
                            }
                        }

                        // 4. Actual points (circles)
                        ForEach(monthlyRevenue) { data in
                            PointMark(
                                x: .value("Month", data.month),
                                y: .value("Actual", data.revenue)
                            )
                            .symbol {
                                Circle()
                                    .stroke(MatteTheme.Colors.luxuryGold, lineWidth: 2)
                                    .background(Circle().fill(Color.white))
                                    .frame(width: 8, height: 8)
                            }
                        }

                        // 5. Vertical Selection Line
                        if let selectedMonth {
                            RuleMark(
                                x: .value("Month", selectedMonth)
                            )
                            .foregroundStyle(Color.white.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .annotation(position: .trailing, alignment: .center, spacing: 8) {
                                if let data = monthlyRevenue.first(where: { $0.month == selectedMonth }) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(data.month)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 4) {
                                            Text(": ₹\(Int(data.target)) Cr")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(MatteTheme.Colors.success)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Text(": ₹\(String(format: "%.1f", data.revenue)) Cr")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 9/255, green: 26/255, blue: 21/255))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                                }
                            }
                            
                            // Target & Actual points highlights on selected month
                            if let data = monthlyRevenue.first(where: { $0.month == selectedMonth }) {
                                PointMark(
                                    x: .value("Month", selectedMonth),
                                    y: .value("Target", data.target)
                                )
                                .symbol {
                                    Circle()
                                        .fill(MatteTheme.Colors.success)
                                        .frame(width: 10, height: 10)
                                }

                                PointMark(
                                    x: .value("Month", selectedMonth),
                                    y: .value("Actual", data.revenue)
                                )
                                .symbol {
                                    Circle()
                                        .stroke(MatteTheme.Colors.luxuryGold, lineWidth: 2)
                                        .background(Circle().fill(Color.white))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                    }
                    .chartXSelection(value: $selectedMonth)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [2]))
                                .foregroundStyle(Color.white.opacity(0.15))
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text("₹\(Int(val)) Cr")
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let monthName = value.as(String.self) {
                                    Text(monthName)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color.white.opacity(0.7))
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                }

                // Legend row below the chart
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(MatteTheme.Colors.luxuryGold)
                            .frame(width: 16, height: 3)
                        Text("Actual")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(MatteTheme.Colors.info)
                                    .frame(width: 4, height: 2)
                            }
                        }
                        Text("Target")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(red: 14/255, green: 35/255, blue: 29/255))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)

            // Top Categories
            VStack(alignment: .leading, spacing: 8) {
                Text("TOP CATEGORIES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MatteTheme.Colors.textTertiary)
                    .kerning(1)

                ForEach(categorySales) { cat in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(cat.color)
                            .frame(width: 8, height: 8)

                        Text(cat.category)
                            .font(.subheadline)
                            .foregroundColor(MatteTheme.Colors.textPrimary)

                        Spacer()

                        Text("₹\(String(format: "%.1f", cat.revenue)) Cr")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private func reportMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Inventory Health Content (Read Only)

    @ViewBuilder
    private var inventoryHealthContent: some View {
        VStack(spacing: 14) {
            // Health Metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                healthMetric(icon: "heart.fill", label: "Stock Health", value: "87%", color: MatteTheme.Colors.success)
                healthMetric(icon: "shippingbox.fill", label: "Total SKUs", value: "1,240", color: MatteTheme.Colors.info)
                healthMetric(icon: "arrow.left.arrow.right", label: "Pending Transfers", value: "5", color: MatteTheme.Colors.warning)
                healthMetric(icon: "exclamationmark.triangle", label: "Open Variances", value: "2", color: MatteTheme.Colors.error)
            }

            // Category Breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("CATEGORY STOCK LEVELS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MatteTheme.Colors.textTertiary)
                    .kerning(1)

                ForEach(["Handbags: 94%", "Watches: 88%", "Accessories: 79%", "Shoes: 85%"], id: \.self) { item in
                    let parts = item.split(separator: ":")
                    let category = String(parts[0])
                    let percentage = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    let value = Double(percentage.replacingOccurrences(of: "%", with: "")) ?? 0

                    HStack(spacing: 10) {
                        Text(category)
                            .font(.subheadline)
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .frame(width: 100, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(MatteTheme.Colors.subtleAccent)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(value > 85 ? MatteTheme.Colors.success : MatteTheme.Colors.warning)
                                    .frame(width: geo.size.width * (value / 100), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text(percentage)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                }
            }

            // Read Only Notice
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(MatteTheme.Colors.textTertiary)
                Text("Inventory data is read-only. Contact store managers for updates.")
                    .font(.system(size: 10))
                    .foregroundColor(MatteTheme.Colors.textTertiary)
            }
            .padding(10)
            .background(MatteTheme.Colors.subtleAccent)
            .cornerRadius(10)
        }
    }

    private func healthMetric(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.06))
        .cornerRadius(14)
    }

    // MARK: - Unified Business Reports Content

    @ViewBuilder
    private var businessReportsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Report Cards
            reportSection(
                title: "Sales Metrics",
                icon: "indianrupeesign.circle",
                items: [
                    ("Total Revenue", "₹48,50,000"),
                    ("Transactions", "312"),
                    ("Avg. Value", "₹15,545"),
                    ("Top Category", "Handbags")
                ]
            )

            Divider()

            reportSection(
                title: "Inventory Health",
                icon: "shippingbox",
                items: [
                    ("Total SKUs", "1,240"),
                    ("Stock Health", "87%"),
                    ("Pending Transfers", "5"),
                    ("Open Variances", "2")
                ]
            )

            Divider()

            reportSection(
                title: "Compliance",
                icon: "checkmark.seal",
                items: [
                    ("Reports Submitted", "28"),
                    ("Approved", "24"),
                    ("Rejected", "2"),
                    ("Score", "92%")
                ]
            )

            Divider()

            reportSection(
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
    }

    private func reportSection(title: String, icon: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MatteTheme.Colors.luxuryGold)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MatteTheme.Colors.textPrimary)
            }

            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.caption)
                        .foregroundColor(MatteTheme.Colors.textSecondary)
                    Spacer()
                    Text(item.1)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }
            }
        }
    }

    // MARK: - Campaign Effectiveness Analytics

    @ViewBuilder
    private var campaignAnalyticsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overall Performance
            HStack(spacing: 0) {
                analyticsStat(value: "12%", label: "Avg. Conversion", color: MatteTheme.Colors.luxuryGold)
                Divider().frame(height: 36)
                analyticsStat(value: "4,500", label: "Total Reach", color: MatteTheme.Colors.info)
                Divider().frame(height: 36)
                analyticsStat(value: "₹6.2L", label: "Promo Revenue", color: MatteTheme.Colors.success)
            }
            .padding(.vertical, 12)
            .background(MatteTheme.Colors.dashboardBackground)
            .cornerRadius(12)

            // Campaign Breakdown
            VStack(alignment: .leading, spacing: 10) {
                Text("CAMPAIGN PERFORMANCE BREAKDOWN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MatteTheme.Colors.textTertiary)
                    .kerning(1)

                ForEach(mockPromotions.filter { $0.status == "Active" }) { promo in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(promo.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(MatteTheme.Colors.textPrimary)
                            Spacer()
                            Text(promo.discount)
                                .font(.caption.weight(.bold))
                                .foregroundColor(MatteTheme.Colors.luxuryGold)
                        }

                        HStack(spacing: 16) {
                            Label("Reach: \(promo.reach)", systemImage: "person.2")
                                .font(.caption)
                                .foregroundColor(MatteTheme.Colors.textSecondary)

                            Label(promo.dateRange, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(MatteTheme.Colors.textSecondary)
                        }

                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(MatteTheme.Colors.subtleAccent)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [MatteTheme.Colors.luxuryGold, MatteTheme.Colors.chartGold],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * 0.72, height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("72% of target reached")
                                .font(.system(size: 10))
                                .foregroundColor(MatteTheme.Colors.textTertiary)
                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(MatteTheme.Colors.dashboardBackground)
                    .cornerRadius(12)
                }
            }

            // ROI Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("RETURN ON INVESTMENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MatteTheme.Colors.textTertiary)
                    .kerning(1)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Campaign Spend")
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Text("₹1,85,000")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 4) {
                        Text("Revenue Generated")
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Text("₹6,20,000")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(MatteTheme.Colors.success)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ROI")
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textSecondary)
                        Text("3.35x")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(MatteTheme.Colors.luxuryGold)
                    }
                }
                .padding(14)
                .background(MatteTheme.Colors.dashboardBackground)
                .cornerRadius(12)
            }
        }
    }

    private func analyticsStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(MatteTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
