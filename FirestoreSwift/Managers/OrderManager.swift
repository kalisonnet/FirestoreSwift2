//
//  OrderManager.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/9/24.
//

import Foundation
import FirebaseDatabase
import MapKit
import FirebaseAuth

class OrderManager: ObservableObject {
    
    static let shared = OrderManager()
    
    @Published var orders: [Order] = []
    let ref = Database.database().reference().child("orders")
    
    // Fetch and geocode physician addresses to create map annotations
    func fetchPhysicianCoordinates(completion: @escaping ([MKPointAnnotation]) -> Void) {
        var annotations: [MKPointAnnotation] = []
        let geocoder = CLGeocoder()
        
        func geocodeNext(index: Int) {
            if index >= orders.count {
                completion(annotations)
                return
            }
            
            let order = orders[index]
            let fullAddress = "\(order.physician_address), \(order.physician_city), \(order.physician_state) \(order.physician_zipcode)"
            print("Processing address: \(fullAddress)") // Debugging
            
            geocoder.geocodeAddressString(fullAddress) { placemarks, error in
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription) for address: \(fullAddress)")
                } else if let placemark = placemarks?.first, let location = placemark.location {
                    let annotation = MKPointAnnotation()
                    annotation.title = order.referring_physician_name
                    annotation.subtitle = order.test_name.joined(separator: ", ")
                    annotation.coordinate = location.coordinate
                    annotations.append(annotation)
                    print("Geocoded address: \(fullAddress) to \(annotation.coordinate)") // Debugging
                }
                
                geocodeNext(index: index + 1) // Move to the next address
            }
        }
        
        geocodeNext(index: 0) // Start geocoding the first address
    }
    
    // Fetch and geocode physician addresses to create map annotations for orders assigned to the logged-in phlebotomist
        func fetchPhysicianCoordinatesForLoggedInUser(completion: @escaping ([MKPointAnnotation]) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("No logged-in user.")
                completion([])
                return
            }

            var annotations: [MKPointAnnotation] = []
            let geocoder = CLGeocoder()

            func geocodeNext(index: Int) {
                if index >= orders.count {
                    completion(annotations)
                    return
                }

                let order = orders[index]
                if order.phlebotomist.contains(userId) {
                    let fullAddress = "\(order.physician_address), \(order.physician_city), \(order.physician_state) \(order.physician_zipcode)"
                    print("Processing address: \(fullAddress)") // Debugging

                    geocoder.geocodeAddressString(fullAddress) { placemarks, error in
                        if let error = error {
                            print("Geocoding error: \(error.localizedDescription) for address: \(fullAddress)")
                        } else if let placemark = placemarks?.first, let location = placemark.location {
                            let annotation = MKPointAnnotation()
                            annotation.title = order.referring_physician_name
                            annotation.subtitle = order.test_name.joined(separator: ", ")
                            annotation.coordinate = location.coordinate
                            annotations.append(annotation)
                            print("Geocoded address: \(fullAddress) to \(annotation.coordinate)") // Debugging
                        }

                        geocodeNext(index: index + 1) // Move to the next address
                    }
                } else {
                    geocodeNext(index: index + 1) // Skip this order if the user isn't assigned
                }
            }

            geocodeNext(index: 0) // Start geocoding the first address
        }
    
    
    
    // Fetch and geocode physician addresses to create map annotations
    func fetchPatientCoordinates(completion: @escaping ([MKPointAnnotation]) -> Void) {
        var annotations: [MKPointAnnotation] = []
        let geocoder = CLGeocoder()
        
        func geocodeNext(index: Int) {
            if index >= orders.count {
                completion(annotations)
                return
            }
            
            let order = orders[index]
            let fullAddress = "\(order.patient_address), \(order.patient_city), \(order.patient_state) \(order.patient_zipcode)"
            print("Processing address: \(fullAddress)") // Debugging
            
            geocoder.geocodeAddressString(fullAddress) { placemarks, error in
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription) for address: \(fullAddress)")
                } else if let placemark = placemarks?.first, let location = placemark.location {
                    let annotation = MKPointAnnotation()
                    annotation.title = order.patient_name
                    annotation.subtitle = order.test_name.joined(separator: ", ")
                    annotation.coordinate = location.coordinate
                    annotations.append(annotation)
                    print("Geocoded address: \(fullAddress) to \(annotation.coordinate)") // Debugging
                }
                
                geocodeNext(index: index + 1) // Move to the next address
            }
        }
        
        geocodeNext(index: 0) // Start geocoding the first address
    }
    
    
    
    
    
    // Fetch and geocode physician addresses to create map annotations for orders assigned to the logged-in phlebotomist
        func fetchPatientCoordinatesForLoggedInUser(completion: @escaping ([MKPointAnnotation]) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("No logged-in user.")
                completion([])
                return
            }

            var annotations: [MKPointAnnotation] = []
            let geocoder = CLGeocoder()

            func geocodeNext(index: Int) {
                if index >= orders.count {
                    completion(annotations)
                    return
                }

                let order = orders[index]
                if order.phlebotomist.contains(userId) {
                    let fullAddress = "\(order.patient_address), \(order.patient_city), \(order.patient_state) \(order.patient_zipcode)"
                    print("Processing address: \(fullAddress)") // Debugging

                    geocoder.geocodeAddressString(fullAddress) { placemarks, error in
                        if let error = error {
                            print("Geocoding error: \(error.localizedDescription) for address: \(fullAddress)")
                        } else if let placemark = placemarks?.first, let location = placemark.location {
                            let annotation = MKPointAnnotation()
                            annotation.title = order.patient_name
                            annotation.subtitle = order.test_name.joined(separator: ", ")
                            annotation.coordinate = location.coordinate
                            annotations.append(annotation)
                            print("Geocoded address: \(fullAddress) to \(annotation.coordinate)") // Debugging
                        }

                        geocodeNext(index: index + 1) // Move to the next address
                    }
                } else {
                    geocodeNext(index: index + 1) // Skip this order if the user isn't assigned
                }
            }

            geocodeNext(index: 0) // Start geocoding the first address
        }
    
    
    // Fetch orders assigned to the logged-in phlebotomist in real-time
        func fetchOrdersForLoggedInUser(completion: @escaping () -> Void = {}) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("No logged-in user.")
                completion()
                return
            }

            ref.observe(.value) { snapshot in
                var fetchedOrders: [Order] = []

                for childSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    if let orderData = childSnapshot.value as? [String: Any] {
                        let orderId = childSnapshot.key
                        if let order = Order.fromDictionary(orderData, id: orderId), order.phlebotomist.contains(userId) {
                            // Only include orders assigned to the logged-in user
                            fetchedOrders.append(order)
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.orders = fetchedOrders
                    completion()
                }
            }
        }
    
    // Fetch orders in real-time
    func fetchOrders(completion: @escaping () -> Void = {}) {
        ref.observe(.value) { snapshot in
            var fetchedOrders: [Order] = []
            
            // Loop over the children of the snapshot (which represents the collection of orders)
            for childSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                if let orderData = childSnapshot.value as? [String: Any] {
                    let orderId = childSnapshot.key
                    if let order = Order.fromDictionary(orderData, id: orderId) { // Corrected call
                        fetchedOrders.append(order)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.orders = fetchedOrders
                completion()
            }
        }
    }
    
    
    // Fetch a specific order by its Firebase document ID
    func fetchOrderById(_ id: String, completion: @escaping (Order?) -> Void) {
        // Ensure id is valid and not empty
        guard !id.isEmpty else {
            print("Invalid orderId: \(id)")
            completion(nil)
            return
        }
        
        // Fetch the order by its document ID from Firebase Realtime Database
        ref.child(id).observeSingleEvent(of: .value) { snapshot in
            // Check if the snapshot exists
            guard snapshot.exists() else {
                print("Order not found for ID: \(id)")
                completion(nil)
                return
            }

            // Ensure the snapshot value can be cast to [String: Any]
            guard let orderData = snapshot.value as? [String: Any] else {
                print("Failed to parse order data for ID: \(id)")
                completion(nil)
                return
            }
            
            // Parse the order
            if let order = Order.fromDictionary(orderData, id: id) {
                completion(order) // Return the fetched order
            } else {
                print("Failed to parse order for ID: \(id)")
                completion(nil)
            }
        }
    }
    
    // Add a new order
    func addOrder(_ order: Order) {
        let newOrderRef = ref.childByAutoId()
        newOrderRef.setValue(order.toDictionary())
    }
    
    // Update an existing order
    func updateOrder(_ order: Order) {
        guard let orderId = order.id else { return }
        ref.child(orderId).setValue(order.toDictionary())
    }
    
    // Delete an order
    func deleteOrder(_ order: Order) {
        guard let orderId = order.id else { return }
        ref.child(orderId).removeValue()
    }
    
    // Assign user to an order
    func assignUserToOrder(orderId: String, userId: String) {
        ref.child(orderId).updateChildValues(["phlebotomist": userId])
    }
    
}
