//
//  POrderDetailView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/19/24.
//

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseDatabase

struct POrderDetailView: View {
    var order: Order // Directly pass the `Order` object instead of fetching by ID
    @StateObject private var locationManager = CombinedLocationManager() // Use the CombinedLocationManager
    @State private var physicianLocation: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var showAddOrderView = false
    
    @State private var rules: [Rule] = [] // Populate this from your actual source of rules
    
    @State private var userAvatarURL: URL? // Avatar URL for logged-in user
    @State private var userName: String = "" // Username for logged-in user
    @State private var distanceInMiles: Double? // State variable for distance
    
    var physicianName: String { order.referring_physician_name } // Get physician name from the order

    // Function to check if any status in the order is "Completed"
    var isOrderCompleted: Bool {
        return order.status.contains { $0.status == "Completed" }
    }

    var body: some View {
        NavigationStack {
            ScrollView { // Enable scrolling for the content
                VStack(alignment: .leading, spacing: 20) {
                    // Display order details
                    Text("Order Number: \(order.order_number)")
                        .font(.headline)
                    
                    Text("Patient Name: \(order.patient_name)")
                        .font(.subheadline)
                    
                    Text("Patient DOB: \(formatTimestamp(order.patient_dob))")
                        .font(.subheadline)
                    
                    Text("Test Name: \(order.test_name.joined(separator: ", "))")
                        .font(.subheadline)
                    
                    // Specimen details
                    Text("Specimen Type: \(order.specimen_type ?? "N/A")")
                    Text("Specimen Source: \(order.specimen_source ?? "N/A")")
                    Text("Specimen Comments: \(order.specimen_comments ?? "N/A")")
                    
                    // Additional order details
                    Text("Test Comments: \(order.test_comments ?? "N/A")")
                    Text("Requirements: \(order.requirements?.joined(separator: ", ") ?? "N/A")")

                    // Check if order is marked as "Completed"
                    if isOrderCompleted {
                        Text("Order Status: Completed")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        if let completedStatus = order.status.first(where: { $0.status == "Completed" }) {
                            Text("Completed on: \(formatTimestamp(completedStatus.timestamp))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        ForEach(order.status, id: \.self) { status in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Status: \(status.status)")
                                    .font(.body)
                                    .bold()
                                Text("Timestamp: \(formatTimestamp(status.timestamp))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 10)
                        }
                        
                    } else {
                        // Display Barcode image if order is not completed
                        if !order.barcode.isEmpty {
                            if let barcodeImage = generateBarcode(from: order.barcode) {
                                Image(uiImage: barcodeImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 80)
                            } else {
                                Text("Failed to generate Barcode").foregroundColor(.red)
                            }
                        } else {
                            Text("No Barcode Available")
                        }
                        
                        // Show the map view and buttons if order is not completed
                        PCustomMapView(
                            userLocation: $locationManager.userLocation,
                            physicianLocation: physicianLocation,
                            route: $route,
                            userAvatarURL: userAvatarURL,
                            userName: userName,
                            physicianName: physicianName
                        )
                        .frame(height: 300)
                        .onAppear {
                            resetState() // Reset the state on view appear
                            fetchPhysicianLocation(for: order)
                            locationManager.checkLocationAuthorization() // Ensure user location tracking is active
                            fetchUserDetails() // Fetch the logged-in user's details
                            setupView()
                        }
                        .onChange(of: order) { oldValue, newOrder in
                            resetState() // Reset the state when a new order is selected
                            fetchPhysicianLocation(for: newOrder)
                        }
                        
                        // Display calculated distance
                                                if let distanceInMiles = distanceInMiles {
                                                    Text("Total Distance: \(distanceInMiles, specifier: "%.2f") miles")
                                                        .padding()
                                                }
                        
                        Button(action: startNavigation) {
                            Text("Start Navigation")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }

                    // Display notes
                    if let notes = order.note, !notes.isEmpty {
                        Text("Order Notes:")
                            .font(.headline)
                        ForEach(notes) { note in
                            VStack(alignment: .leading) {
                                Text(note.note)
                                    .font(.body)
                                Text("Timestamp: \(formatTimestamp(note.timestamp))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 5)
                        }
                    } else {
                        Text("No notes available.")
                    }

                    Spacer().frame(height: 20) // Extra spacing at the bottom
                }
                .padding()
            }
            .sheet(isPresented: $showAddOrderView) {
                AddOrderView(orderManager: OrderManager.shared, order: order)
            }
        }
    }
    
    // Function to set up view and start location tracking
        private func setupView() {
            resetState()
            fetchPhysicianLocation(for: order)
            locationManager.checkLocationAuthorization() // Ensure user location tracking is active
            fetchUserDetails() // Fetch the logged-in user's details
        }
    
    // Function to reset state variables on view appear
    func resetState() {
        physicianLocation = nil
        route = nil
    }

    // Fetch the physician's location based on the address in the selected order
    func fetchPhysicianLocation(for order: Order) {
        let address = "\(order.physician_address), \(order.physician_city), \(order.physician_state), \(order.physician_zipcode)"
        print("Fetching location for physician at address: \(address)")
        locationManager.fetchPhysicianLocation(address: address) { location in
            if let location = location {
                self.physicianLocation = location
                calculateAndStoreDistance() // Calculate and store the route distance
            }
        }
    }
    
    
    // Function to calculate and store the route distance in Firebase
        private func calculateAndStoreDistance() {
            guard let userLocation = locationManager.userLocation, let physicianLocation = physicianLocation else { return }

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: physicianLocation))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let route = response?.routes.first {
                    self.route = route
                    self.distanceInMiles = route.distance / 1609.34 // Convert meters to miles

                    // Update Firebase with the calculated distance
                    if let orderId = order.id {
                        let databaseRef = Database.database().reference().child("orders").child(orderId)
                        databaseRef.updateChildValues(["distance": self.distanceInMiles ?? 0])
                    }
                } else if let error = error {
                    print("Error calculating route: \(error.localizedDescription)")
                }
            }
        }
    

    // Fetch the logged-in user's details from Firebase
    func fetchUserDetails() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }
        
        let userRef = Database.database().reference().child("users").child(userId)
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else {
                print("No user data found.")
                return
            }

            if let avatarUrlString = userData["avatarUrl"] as? String,
               let avatarUrl = URL(string: avatarUrlString) {
                self.userAvatarURL = avatarUrl // Set the avatar URL
            }
            
            self.userName = userData["username"] as? String ?? "Unknown User" // Set the username
        }
    }

    // Calculate the route between the user's location and the physician's location
    func calculateRoute() {
        guard let userLocation = locationManager.userLocation, let physicianLocation = physicianLocation else {
            print("Cannot calculate route: locations missing.")
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: physicianLocation))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating route: \(error.localizedDescription)")
                return
            }
            if let route = response?.routes.first {
                self.route = route
            }
        }
    }

    // Start navigation using the Maps app
    func startNavigation() {
        guard let physicianLocation = physicianLocation else { return }
        
        let alertController = UIAlertController(
            title: "Choose Navigation App",
            message: "Select the app you want to use for navigation",
            preferredStyle: .actionSheet
        )
        
        // Apple Maps option
        let appleMapsAction = UIAlertAction(title: "Apple Maps", style: .default) { _ in
            let appleMapsUrl = URL(string: "http://maps.apple.com/?daddr=\(physicianLocation.latitude),\(physicianLocation.longitude)&dirflg=d")!
            UIApplication.shared.open(appleMapsUrl, options: [:], completionHandler: nil)
        }
        alertController.addAction(appleMapsAction)
        
        // Google Maps option
        if let googleMapsUrl = URL(string: "comgooglemaps://?daddr=\(physicianLocation.latitude),\(physicianLocation.longitude)&directionsmode=driving"),
           UIApplication.shared.canOpenURL(googleMapsUrl) {
            let googleMapsAction = UIAlertAction(title: "Google Maps", style: .default) { _ in
                UIApplication.shared.open(googleMapsUrl, options: [:], completionHandler: nil)
            }
            alertController.addAction(googleMapsAction)
        }
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present the action sheet
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(alertController, animated: true, completion: nil)
        }
    }
    // Function to generate barcode image from a string
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)

        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")

            if let outputImage = filter.outputImage {
                let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
                let context = CIContext()
                if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }

        return nil
    }

    // Helper function to format timestamp into a readable string
    func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
