//
//  AnalyticsView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/11/24.
//

import SwiftUI
import FirebaseDatabase


struct AnalyticsView: View {
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var selectedPhysicianID: String = ""
    @State private var selectedPhlebotomist: User? // Track selected phlebotomist
    @State private var selectedSalesName: String = ""
    
    @State private var phlebotomistSearchText = "" // Text typed in the search field
    @State private var phlebotomistSuggestions: [User] = [] // Suggestions matching search text
    @ObservedObject var userManager: UserManager // UserManager instance for phlebotomists

    @State private var totalOrders: Int = 0
    @State private var totalCollectionTubes: [String: Int] = [:]
    @State private var grandTotalTubes: Int = 0 // Track grand total of all tubes
    @State private var totalHours: Double = 0.0
    
    @State private var totalMileage: Double = 0.0 // New field to track total mileage
    
    
    var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Analytics Report")
                        .font(.largeTitle)
                        .padding()

                    // Date Range Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Date Range")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        HStack(spacing: 30) {
                            VStack(alignment: .leading) {
                                Text("Start Date")
                                    .font(.subheadline)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden() // Hide redundant label from DatePicker
                            }
                            
                            VStack(alignment: .leading) {
                                Text("End Date")
                                    .font(.subheadline)
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden() // Hide redundant label from DatePicker
                            }
                        }
                    }
                    .padding()


                    // Filters for Physician, Phlebotomist, Sales
                    VStack(alignment: .leading) {
                        TextField("Referring Physician ID", text: $selectedPhysicianID)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // Phlebotomist Search Field with Autocomplete
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading) {
                                TextField("Phlebotomist", text: $phlebotomistSearchText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: phlebotomistSearchText) { newValue in
                                        updatePhlebotomistSuggestions(for: newValue)
                                    }
                                
                                // Suggestion list shown below the text field
                                if !phlebotomistSuggestions.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(phlebotomistSuggestions) { user in
                                            Button(action: {
                                                selectPhlebotomist(user)
                                            }) {
                                                HStack {
                                                    AsyncImage(url: URL(string: user.avatarUrl)) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 30, height: 30)
                                                            .clipShape(Circle())
                                                    } placeholder: {
                                                        Circle().frame(width: 30, height: 30).foregroundColor(.gray)
                                                    }
                                                    Text(user.username)
                                                        .font(.body)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 5)
                                                .background(Color.white)
                                            }
                                            Divider()
                                        }
                                    }
                                    .background(Color.white)
                                    .cornerRadius(5)
                                    .shadow(radius: 5)
                                    .frame(maxHeight: 150) // Limit list height
                                }
                            }
                        }
                        
                        TextField("Sales Name", text: $selectedSalesName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    
                    // Button to Fetch Report
                    Button(action: fetchAnalytics) {
                        Text("Generate Report")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()

                    // Display Results
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Total Orders: \(totalOrders)")
                            .font(.headline)
                        
                        Text("Total Collection Tubes by Type:")
                            .font(.headline)
                        ForEach(totalCollectionTubes.keys.sorted(), id: \.self) { tubeType in
                            Text("\(tubeType): \(totalCollectionTubes[tubeType] ?? 0)")
                                .font(.subheadline)
                        }
                        
                        Text("Grand Total of Collection Tubes: \(grandTotalTubes)")
                                                .font(.headline)
                                                .padding(.top, 5)
                        
                        Text("Total Hours (Start to Complete): \(totalHours, specifier: "%.2f") hours")
                            .font(.headline)
                        
                        Text("Total Mileage: \(totalMileage, specifier: "%.2f") miles") // New field for mileage
                                                .font(.headline)
                                                .padding(.top, 5)
                    }
                    .padding()

                    Spacer().frame(height: 20)
                }
                .padding()
            }
            .onTapGesture {
                self.dismissKeyboard()
            }
        }
    
    // Function to update suggestions based on search text
    private func updatePhlebotomistSuggestions(for query: String) {
        if query.isEmpty {
            phlebotomistSuggestions = []
        } else {
            phlebotomistSuggestions = userManager.users
                .filter { $0.role == "PHLEBOTOMIST" && $0.username.lowercased().contains(query.lowercased()) }
                .sorted { $0.username < $1.username }
        }
    }
    
    // Function to handle phlebotomist selection
    private func selectPhlebotomist(_ user: User) {
        selectedPhlebotomist = user
        phlebotomistSearchText = user.username // Update search text with selected username
        phlebotomistSuggestions = [] // Clear suggestions after selection
    }
    
    
    func fetchAnalytics() {
        let databaseRef = Database.database().reference().child("orders")
        
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let ordersData = snapshot.value as? [String: Any] else {
                print("No data found in snapshot.")
                return
            }
            
            let filteredOrders = ordersData.filter { order in
                let orderDict = order.value as? [String: Any]
                
                // Date range check
                if let timestamp = orderDict?["order_date"] as? Double {
                    let orderDate = Date(timeIntervalSince1970: timestamp)
                    if !(orderDate >= startDate && orderDate <= endDate) {
                        return false
                    }
                }
                
                // Filter by referring physician, phlebotomist, and sales name
                if !selectedPhysicianID.isEmpty, orderDict?["referring_physician_id"] as? String != selectedPhysicianID {
                    return false
                }
                
                if let selectedPhlebotomist = selectedPhlebotomist,
                   let phlebotomistIDs = orderDict?["phlebotomist"] as? [String],
                   !phlebotomistIDs.contains(selectedPhlebotomist.id ?? "") {
                    return false
                }
                
                if !selectedSalesName.isEmpty, orderDict?["sales_name"] as? String != selectedSalesName {
                    return false
                }
                
                return true
            }
            
            // Calculating totals
            self.totalOrders = filteredOrders.count
            self.totalCollectionTubes = [:]
            self.totalHours = 0.0
            self.totalMileage = 0.0 // Reset total mileage

            for order in filteredOrders {
                let orderDict = order.value as? [String: Any]
                
                // Count collection tubes by type and grand total
                if let tubes = orderDict?["collectionTubes"] as? [[String: Any]] {
                    for tube in tubes {
                        if let name = tube["name"] as? String,
                           let quantity = tube["quantity"] as? Int {
                            self.totalCollectionTubes[name, default: 0] += quantity
                        }
                    }
                }
                
                // Calculate hours from "In-Progress" to "Completed" in the status array
                if let statusArray = orderDict?["status"] as? [[String: Any]] {
                    var inProgressTimestamp: Double?
                    var completedTimestamp: Double?
                    
                    for status in statusArray {
                        if let statusName = status["status"] as? String,
                           let timestamp = status["timestamp"] as? Double {
                            
                            if statusName == "In-Progress" {
                                inProgressTimestamp = timestamp
                            } else if statusName == "Completed" {
                                completedTimestamp = timestamp
                            }
                        }
                    }
                    
                    // Calculate hours if both timestamps are available
                    if let start = inProgressTimestamp, let end = completedTimestamp {
                        let hours = (end - start) / 3600.0
                        self.totalHours += hours
                    }
                }
                
                // Add order's distance to total mileage
                if let distance = orderDict?["distance"] as? Double {
                    self.totalMileage += distance
                }
            }
            
            print("Total Orders: \(self.totalOrders)")
            print("Total Collection Tubes: \(self.totalCollectionTubes)")
            print("Total Hours: \(self.totalHours)")
            print("Total Mileage: \(self.totalMileage) miles")
        }
    }





    
    // Helper function to dismiss the keyboard
        private func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
}

