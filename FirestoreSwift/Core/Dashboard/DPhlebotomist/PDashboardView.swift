//
//  PDashboardView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct PDashboardView: View {
    @State private var userRole: String = ""
       @State private var isLoading = true
       @StateObject private var orderManager = OrderManager.shared
       @State private var activeUsers: [User] = [] // New state for active users
       @State private var userId: String? = Auth.auth().currentUser?.uid // User ID


    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Dashboard...")
                } else {
                    if userRole == "PHLEBOTOMIST" {
                        Text("Assigned Orders")
                            .font(.headline)
                        List {
                            ForEach(Array(groupedOrdersByStatus.keys), id: \.self) { status in
                                Section(header: Text(status).font(.headline)) {
                                    ForEach(groupedOrdersByStatus[status]!, id: \.id) { order in
                                        VStack(alignment: .leading) {
                                            Text(order.patient_name)
                                                .font(.headline)
                                            // Test name or other information
                                            Text(order.test_name.joined(separator: ", "))
                                                .font(.subheadline)
                                            
                                            // Display order status line
                                            if let lastStatus = order.status.last {
                                                HStack {
                                                    Text("Status:")
                                                        .font(.footnote)
                                                        .fontWeight(.semibold)
                                                    Text(lastStatus.status)
                                                        .font(.footnote)
                                                        .foregroundColor(statusColor(for: lastStatus.status))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else if userRole.contains("MANAGER") {
                        managerOverview
                    } else {
                        Text("Welcome to your Dashboard")
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                loadUserRoleAndOrders()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Filter and group orders by status for the Phlebotomist
    var groupedOrdersByStatus: [String: [Order]] {
        guard let userId = userId else { return [:] }
        
        // First filter the orders assigned to the current Phlebotomist
        let phlebotomistOrders = orderManager.orders.filter { order in
            order.phlebotomist.contains(userId)
        }
        
        // Group the orders by their latest status
        return Dictionary(grouping: phlebotomistOrders) { order in
            order.status.last?.status ?? "Unknown"
        }
    }
    
    // Manager-specific overview view
    var managerOverview: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Manager Overview")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            // Orders summary
            Text("Orders Summary")
                .font(.headline)
            HStack {
                VStack {
                    Text("Total Orders")
                    Text("\(orderManager.orders.count)")
                        .font(.title)
                }
                Spacer()
                VStack {
                    Text("Completed Orders")
                    Text("\(orderManager.orders.filter { $0.status.last?.status == "Completed" }.count)")
                        .font(.title)
                }
                Spacer()
                VStack {
                    Text("Orders in Progress")
                    Text("\(orderManager.orders.filter { $0.status.last?.status == "In-Progress" }.count)")
                        .font(.title)
                }
            }
            .padding()

            // Active users list
            Text("Active Users")
                .font(.headline)
            List(activeUsers) { user in
                HStack {
                    // Load the avatar image using AsyncImage
                    AsyncImage(url: URL(string: user.avatarUrl)) { image in
                        image
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(user.username)
                            .font(.headline)
                        Text(user.role)
                            .font(.subheadline)
                        Text(user.email)
                            .font(.footnote)
                        Text(user.phoneNumber)
                            .font(.footnote)
                    }
                }
            }
        }
        .padding()
    }
    
    // Function to load the user's role and fetch orders based on the role
    private func loadUserRoleAndOrders() {
        guard let userId = userId else {
            return
        }

        // Fetch user role from the Realtime Database
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any],
               let role = userData["role"] as? String {
                self.userRole = role
                fetchOrdersAndUsersBasedOnRole(role: role)
            }
        }
    }
    
    // Fetch orders and users based on role
    private func fetchOrdersAndUsersBasedOnRole(role: String) {
        orderManager.fetchOrders {
            // Once orders are fetched, fetch active users for manager role
            if role.contains("MANAGER") {
                fetchActiveUsers()
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    // Fetch active users (or all users, based on the role)
    private func fetchActiveUsers() {
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedUsers: [User] = []
            for case let child as DataSnapshot in snapshot.children {
                if let userData = child.value as? [String: Any] {
                    // Create user object using the User model
                    let user = User(id: child.key, data: userData)
                    fetchedUsers.append(user)
                }
            }
            
            DispatchQueue.main.async {
                self.activeUsers = fetchedUsers
                self.isLoading = false
            }
        }
    }
    
    // Helper function to determine the color for the status text
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Completed":
            return .green
        case "In-Progress":
            return .orange
        case "Failed":
            return .red
        default:
            return .gray
        }
    }
}
