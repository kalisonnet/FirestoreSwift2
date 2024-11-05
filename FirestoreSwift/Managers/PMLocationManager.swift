//
//  PMLocationManager.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/20/24.
//

/*import Foundation
import CoreLocation
import FirebaseDatabase

class PMLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var ref: DatabaseReference!
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var phlebotomistLocations: [String: CLLocationCoordinate2D] = [:] // Stores each user's location

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Start tracking user location for multiple phlebotomists
    func startTrackingPhlebotomists(phlebotomistIds: [String]) {
        for userId in phlebotomistIds {
            let userRef = Database.database().reference().child("users").child(userId).child("location")
            userRef.observe(.value) { snapshot in
                if let locationData = snapshot.value as? [String: Double],
                   let latitude = locationData["latitude"],
                   let longitude = locationData["longitude"] {
                    DispatchQueue.main.async {
                        self.phlebotomistLocations[userId] = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
            }
        }
    }
    
    // Stop tracking phlebotomists
    func stopTrackingPhlebotomists() {
        // Implement cleanup of Firebase observers if necessary
    }
    
    // CLLocationManagerDelegate for current user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location.coordinate
        }
    }
}*/

