//
//  MainTabView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/10/24.
//

import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseDatabase

struct MainTabView: View {
    @StateObject private var orderManager = OrderManager() // Using the existing OrderManager
    @StateObject private var locationManager = CombinedLocationManager(userId: Auth.auth().currentUser?.uid ?? "") // Initialize LocationManager
    @State private var isLoggedOut = false
    @State private var role: String? = nil // State to store the user's role
    @State private var showPatientLocation = false // Control toggle for patient/physician location
    @ObservedObject var userManager = UserManager() // Initialize UserManager
    
    
    var body: some View {
        Group {
            if let role = role {
                TabView {
                    if role == "ADMIN" {
                        // Admin Views
                        POrderListView(orderManager: orderManager)
                            .tabItem {
                                Image(systemName: "doc.text")
                                Text("Orders")
                            }
                        
                        AdminDashboardView()
                            .tabItem {
                                Image(systemName: "speedometer")
                                Text("Dashboard")
                            }
                        
                        AdminMapView(orderManager: orderManager, locationManager: locationManager)
                            .tabItem {
                                Image(systemName: "map")
                                Text("Map")
                            }
                        
                        AdminSettingsView(isLoggedOut: $isLoggedOut)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                    } else if role == "PHLEBOTOMY MANAGER" {
                        // Phlebotomy Manager Views
                        PMOrderListView(orderManager: orderManager)
                            .tabItem {
                                Image(systemName: "doc.text")
                                Text("Orders")
                            }
                        
                        PMDashboardView()
                            .tabItem {
                                Image(systemName: "speedometer")
                                Text("Dashboard")
                            }
                        
                        VStack {
                            // Add a toggle to control switching between patient and physician locations
                            Toggle(isOn: $showPatientLocation) {
                                Text(showPatientLocation ? "Show Patient Location" : "Show Physician Location")
                            }
                            .padding()

                            PMMapView(orderManager: orderManager, locationManager: locationManager, showPatientLocation: $showPatientLocation)
                                .edgesIgnoringSafeArea(.all) // Ensure the map view fills the space
                        }
                        .tabItem {
                            Image(systemName: "map")
                            Text("Map")
                        }
                        
                        PMSettingsView(isLoggedOut: $isLoggedOut)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                    } else if role == "LOGISTIC MANAGER" {
                        // Logistic Manager Views
                        POrderListView(orderManager: orderManager)
                            .tabItem {
                                Image(systemName: "doc.text")
                                Text("Orders")
                            }
                        
                        LMDashboardView()
                            .tabItem {
                                Image(systemName: "speedometer")
                                Text("Dashboard")
                            }
                        
                        LMMapView(orderManager: orderManager, locationManager: locationManager)
                            .tabItem {
                                Image(systemName: "map")
                                Text("Map")
                            }
                        
                        LMSettingsView(isLoggedOut: $isLoggedOut)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                    } else if role == "PHLEBOTOMIST" {
                        // Phlebotomist Views
                        POrderListView(orderManager: orderManager)
                            .tabItem {
                                Image(systemName: "doc.text")
                                Text("Orders")
                            }
                        
                        PDashboardView()
                            .tabItem {
                                Image(systemName: "speedometer")
                                Text("Dashboard")
                            }
                        
                        PMapView(orderManager: orderManager, locationManager: locationManager)
                            .tabItem {
                                Image(systemName: "map")
                                Text("Map")
                            }
                        
                        PSettingsView(isLoggedOut: $isLoggedOut)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                    } else if role == "LOGISTIC" {
                        // Logistic Views
                        PMOrderListView(orderManager: orderManager)
                            .tabItem {
                                Image(systemName: "doc.text")
                                Text("Orders")
                            }
                        
                        LDashboardView()
                            .tabItem {
                                Image(systemName: "speedometer")
                                Text("Dashboard")
                            }
                        
                        LMapView(orderManager: orderManager, locationManager: locationManager)
                            .tabItem {
                                Image(systemName: "map")
                                Text("Map")
                            }
                        
                        LSettingsView(isLoggedOut: $isLoggedOut)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                    } else if role == "SALES" {
                        // Sales Views
                        PMOrderListView(orderManager: orderManager)
                            .tabItem {
                                Image(systemName: "doc.text")
                                Text("Orders")
                            }
                        
                        SDashboardView()
                            .tabItem {
                                Image(systemName: "speedometer")
                                Text("Dashboard")
                            }
                        
                        SMapView(orderManager: orderManager, locationManager: locationManager)
                            .tabItem {
                                Image(systemName: "map")
                                Text("Map")
                            }
                        
                        SSettingsView(isLoggedOut: $isLoggedOut)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                    }
                }
                .fullScreenCover(isPresented: $isLoggedOut) {
                    LoginView() // Redirect to LoginView after logout
                }
            } else {
                ProgressView("Loading...") // Show a loading view while the role is being fetched
            }
        }
        .onAppear(perform: fetchUserRole) // Fetch the user's role when the view appears
    }
    
    // Fetch the user's role from Firebase
    func fetchUserRole() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(userId).child("role")
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userRole = snapshot.value as? String {
                DispatchQueue.main.async {
                    self.role = userRole
                }
            }
        }
    }
}
