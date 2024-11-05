//
//  ArchiveView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/12/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct ArchiveView: View {
    @ObservedObject var orderManager: OrderManager
    @ObservedObject var userManager = UserManager()
    
    @State private var orderNumber = ""
    @State private var patientName = ""
    @State private var referringPhysicianName = ""
    @State private var referringPhysicianID = ""
    @State private var phlebotomist = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var results: [Order] = []
    @State private var selectedOrder: Order? // Track the selected order for navigation
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Archive Search")
                    .font(.largeTitle)
                
                // Search fields
                TextField("Order Number", text: $orderNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Patient Name", text: $patientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Referring Physician Name", text: $referringPhysicianName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Referring Physician ID", text: $referringPhysicianID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Phlebotomist", text: $phlebotomist)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Date range picker
                HStack {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                // Search button
                Button("Search") {
                    performSearch()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                // Display results
                List(results, id: \.id) { order in
                    // Navigation link for each order
                    NavigationLink(
                        destination: PMOrderDetailView(order: order),
                        tag: order,
                        selection: $selectedOrder
                    ) {
                        VStack(alignment: .leading) {
                            Text("Order Number: \(order.order_number ?? "")")
                                .font(.headline)
                            Text("Patient Name: \(order.patient_name)")
                            Text("Referring Physician: \(order.referring_physician_name ?? "")")
                            Text("Date: \(formatDate(order.order_date))")
                        }
                        .contentShape(Rectangle()) // Make the whole cell tappable
                        .onTapGesture {
                            selectedOrder = order // Set selected order to trigger navigation
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Archive")
            .onAppear {
                checkUserRoleAndFetchOrders()
            }
        }
    }

    private func performSearch() {
        results = orderManager.orders.filter { order in
            // Check if any status entry in the order's status array is "Completed"
            let isCompleted = order.status.contains { $0.status == "Completed" }
            
            guard isCompleted else { return false }
            
            // Match other criteria
            let orderNumberMatch = orderNumber.isEmpty || (order.order_number.contains(orderNumber) ?? false)
            let patientNameMatch = patientName.isEmpty || order.patient_name.lowercased().contains(patientName.lowercased())
            let referringPhysicianNameMatch = referringPhysicianName.isEmpty || (order.referring_physician_name.lowercased().contains(referringPhysicianName.lowercased()) ?? false)
            let referringPhysicianIDMatch = referringPhysicianID.isEmpty || (order.referring_physician_id?.contains(referringPhysicianID) ?? false)
            let phlebotomistMatch = phlebotomist.isEmpty || order.phlebotomist.contains(phlebotomist)
            
            // Date range match
            let dateMatch = order.order_date >= startDate && order.order_date <= endDate
            
            return orderNumberMatch && patientNameMatch && referringPhysicianNameMatch && referringPhysicianIDMatch && phlebotomistMatch && dateMatch
        }
    }



    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func checkUserRoleAndFetchOrders() {
        guard let user = Auth.auth().currentUser else {
            print("No logged-in user.")
            return
        }

        userManager.fetchUserRole(for: user.uid) { role in
            if role.contains("ADMIN") || role.contains("MANAGER") {
                orderManager.fetchOrders()
            } else {
                fetchOrdersForLoggedInUser()
            }
        }
    }

    private func fetchOrdersForLoggedInUser(completion: @escaping () -> Void = {}) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            completion()
            return
        }

        orderManager.ref.observe(.value) { snapshot in
            var fetchedOrders: [Order] = []

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let orderData = snapshot.value as? [String: Any] {
                    let orderId = snapshot.key
                    if let order = Order.fromDictionary(orderData, id: orderId), order.phlebotomist.contains(userId) {
                        // Only include orders assigned to the logged-in user
                        fetchedOrders.append(order)
                    }
                }
            }

            DispatchQueue.main.async {
                orderManager.orders = fetchedOrders
                completion()
            }
        }
    }
}
