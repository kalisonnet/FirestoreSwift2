//
//  PMDashboardView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//
import SwiftUI
import Charts
import FirebaseAuth
import FirebaseDatabase

struct PMDashboardView: View {
    @State private var selectedDate = Date()
    @State private var orderStats = OrderStats()
    @State private var userStats = UserStats()
    @State private var weeklyOrderCounts: [Int] = Array(repeating: 0, count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date Picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground)))
                    .padding(.horizontal)
                    .onChange(of: selectedDate) { newDate in
                        loadDashboardData(for: newDate)
                    }

                VStack(spacing: 16) {
                    // Order Summary Section
                    SectionView(title: "Order Summary for \(dateFormatter.string(from: selectedDate))") {
                        HStack {
                            DashboardStat(title: "Total Orders", value: "\(orderStats.totalOrders)", color: .blue)
                            DashboardStat(title: "In Progress", value: "\(orderStats.inProgress)", color: .orange)
                            DashboardStat(title: "Completed", value: "\(orderStats.completed)", color: .green)
                            DashboardStat(title: "Failed", value: "\(orderStats.failed)", color: .red)
                        }
                    }

                    // User Summary Section
                    SectionView(title: "User Summary by Role") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(userStats.roles, id: \.role) { roleStat in
                                    DashboardStat(title: roleStat.role, value: "\(roleStat.count)", color: .purple)
                                }
                            }
                        }
                        DashboardStat(title: "Total Users", value: "\(userStats.total)", color: .blue)
                    }

                    // Additional Totals Section
                    SectionView(title: "Additional Totals") {
                        HStack {
                            DashboardStat(title: "Total Tests", value: "\(orderStats.totalTests)", color: .cyan)
                            DashboardStat(title: "Total Distance", value: "\(String(format: "%.2f", orderStats.totalDistance)) miles", color: .indigo)
                            DashboardStat(title: "Collection Tubes", value: "\(orderStats.totalTubes)", color: .pink)
                        }
                    }
                }
                .padding(.horizontal)

                // Weekly Orders Chart
                SectionView(title: "Weekly Orders") {
                    LineChartView(data: weeklyOrderCounts)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 10)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            loadDashboardData(for: selectedDate)
        }
    }

    private func loadDashboardData(for date: Date) {
        fetchOrderStats(for: date) { stats in
            self.orderStats = stats
        }
        fetchUserStats { stats in
            self.userStats = stats
        }
        fetchWeeklyOrderCounts(for: date) { counts in
            self.weeklyOrderCounts = counts
        }
    }
}

// Section Container View
struct SectionView<Content: View>: View {
    var title: String
    var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)
            content
                .padding()
                .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground)))
        }
        .padding(.horizontal)
    }
}

// Dashboard Stat View
struct DashboardStat: View {
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack {
            Text(value).font(.title2).bold().foregroundColor(color)
            Text(title).font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// Line Chart View for Weekly Orders
struct LineChartView: View {
    var data: [Int]

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Orders", value)
                )
                .foregroundStyle(.blue)
            }
        }
        .frame(height: 200)
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
}

// Data Models
struct OrderStats {
    var totalOrders = 0
    var inProgress = 0
    var completed = 0
    var failed = 0
    var totalTests = 0
    var totalDistance = 0.0
    var totalTubes = 0
}

struct UserStats {
    var roles: [RoleStat] = []
    var total: Int {
        roles.reduce(0) { $0 + $1.count }
    }
}

struct RoleStat {
    var role: String
    var count: Int
}

// Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

// Firebase Data Fetching
extension PMDashboardView {
    private func fetchOrderStats(for date: Date, completion: @escaping (OrderStats) -> Void) {
        let ref = Database.database().reference().child("orders")
        ref.observeSingleEvent(of: .value) { snapshot in
            var stats = OrderStats()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let orderData = child.value as? [String: Any],
                   let orderDate = orderData["order_date"] as? Double {
                    let orderDate = Date(timeIntervalSince1970: orderDate)
                    if Calendar.current.isDate(orderDate, inSameDayAs: date) {
                        stats.totalOrders += 1
                        
                        if let statusArray = orderData["status"] as? [[String: Any]] {
                            for statusDict in statusArray {
                                if let status = statusDict["status"] as? String {
                                    switch status {
                                    case "In-Progress":
                                        stats.inProgress += 1
                                    case "Completed":
                                        stats.completed += 1
                                    case "Failed":
                                        stats.failed += 1
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                        
                        stats.totalTests += (orderData["test_name"] as? [String])?.count ?? 0
                        stats.totalDistance += orderData["distance"] as? Double ?? 0.0
                        if let tubes = orderData["collectionTubes"] as? [[String: Any]] {
                            stats.totalTubes += tubes.reduce(0) { $0 + ($1["quantity"] as? Int ?? 0) }
                        }
                    }
                }
            }
            completion(stats)
        }
    }

    private func fetchUserStats(completion: @escaping (UserStats) -> Void) {
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value) { snapshot in
            var stats = UserStats()
            var roleCounts: [String: Int] = [:]
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let userData = child.value as? [String: Any],
                   let role = userData["role"] as? String {
                    roleCounts[role, default: 0] += 1
                }
            }
            stats.roles = roleCounts.map { RoleStat(role: $0.key, count: $0.value) }
            completion(stats)
        }
    }

    private func fetchWeeklyOrderCounts(for date: Date, completion: @escaping ([Int]) -> Void) {
        let ref = Database.database().reference().child("orders")
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        
        ref.observeSingleEvent(of: .value) { snapshot in
            var weeklyCounts = Array(repeating: 0, count: 7)
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let orderData = child.value as? [String: Any],
                   let orderDate = orderData["order_date"] as? Double {
                    let orderDate = Date(timeIntervalSince1970: orderDate)
                    if orderDate >= startOfWeek, orderDate < Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)! {
                        let dayIndex = Calendar.current.component(.weekday, from: orderDate) - 1
                        weeklyCounts[dayIndex] += 1
                    }
                }
            }
            completion(weeklyCounts)
        }
    }
}
