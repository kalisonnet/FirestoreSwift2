//
//  CombinedLocationManager.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/10/24.
//

import CoreLocation
import FirebaseDatabase
import FirebaseAuth

class CombinedLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var ref: DatabaseReference!
    private var userLocationHandles: [String: DatabaseHandle] = [:] // Track all live location listeners
    var currentUserId: String
    
    @Published var userLocation: CLLocationCoordinate2D? // Logged-in user's live location
    @Published var allUserDetails: [String: (coordinate: CLLocationCoordinate2D, avatarUrl: String?, username: String)] = [:] // Live locations of all phlebotomists with details
    @Published var allUserLocations: [String: CLLocationCoordinate2D] = [:] // Live locations of all tracked users
    @Published var specificPhlebotomistLocation: CLLocationCoordinate2D? // Location of a specific phlebotomist
    @Published var physicianLocation: CLLocationCoordinate2D? // Location of a physician
    @Published var patientLocation: CLLocationCoordinate2D? // Location of a patient
    
    // Initialize with the logged-in user's ID
    init(userId: String = Auth.auth().currentUser?.uid ?? "") {
        self.currentUserId = userId
        super.init()
        
        // Set up the location manager for the logged-in user's location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Firebase reference for updating the user's location
        ref = Database.database().reference().child("users").child(userId).child("location")
    }

    // CLLocationManagerDelegate method: Update the logged-in user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location.coordinate
            // Update location in Firebase
            ref.setValue(["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude])
        }
    }

    // Start tracking multiple users' live locations (e.g., phlebotomists, managers, etc.)
    func startTrackingUsers(userIds: [String]) {
        for userId in userIds {
            if userLocationHandles[userId] == nil { // Avoid duplicate listeners
                let userRef = Database.database().reference().child("users").child(userId)
                
                let handle = userRef.observe(.value) { snapshot in
                    guard let userData = snapshot.value as? [String: Any] else {
                        print("No user data found for userId: \(userId)")
                        return
                    }
                    
                    // Fetch location data
                    if let locationData = userData["location"] as? [String: Double],
                       let latitude = locationData["latitude"],
                       let longitude = locationData["longitude"] {
                        
                        // Fetch avatar and username
                        let avatarUrl = userData["avatarUrl"] as? String
                        let username = userData["username"] as? String ?? "Unknown"
                        
                        DispatchQueue.main.async {
                            self.allUserDetails[userId] = (
                                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                avatarUrl: avatarUrl,
                                username: username
                            )
                            print("Phlebotomist \(username) added with location \(latitude), \(longitude)")
                        }
                    } else {
                        print("No location data found for userId: \(userId)")
                    }
                }
                userLocationHandles[userId] = handle
            }
        }
    }



    // Start tracking a specific phlebotomist's live location
    func startTrackingPhlebotomist(phlebotomistId: String) {
        if userLocationHandles[phlebotomistId] == nil { // Ensure no duplicate listeners
            let phlebotomistRef = Database.database().reference().child("users").child(phlebotomistId).child("location")
            let handle = phlebotomistRef.observe(.value) { snapshot in
                if let locationData = snapshot.value as? [String: Double],
                   let latitude = locationData["latitude"],
                   let longitude = locationData["longitude"] {
                    DispatchQueue.main.async {
                        self.specificPhlebotomistLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
            }
            userLocationHandles[phlebotomistId] = handle
        }
    }

    // Fetch all users with the "PHLEBOTOMIST" role and start tracking their locations
    func startTrackingAllPhlebotomists() {
        let usersRef = Database.database().reference().child("users")
        usersRef.observeSingleEvent(of: .value) { snapshot in
            guard let usersData = snapshot.value as? [String: [String: Any]] else {
                print("Failed to parse users data from snapshot")
                return
            }
            
            var phlebotomistIds: [String] = []
            
            for (userId, userData) in usersData {
                // Check for the role key and ensure the user is a phlebotomist
                if let role = userData["role"] as? String, role == "PHLEBOTOMIST" {
                    print("Phlebotomist found: \(userId)")
                    phlebotomistIds.append(userId)
                } else {
                    print("User \(userId) is not a phlebotomist")
                }
            }

            if phlebotomistIds.isEmpty {
                print("No phlebotomists found in the database")
            } else {
                print("Starting to track phlebotomists: \(phlebotomistIds)")
            }

            // Start tracking all phlebotomists' locations
            self.startTrackingUsers(userIds: phlebotomistIds)
        }
    }


    // Stop tracking all phlebotomists
    func stopTrackingAllPhlebotomists() {
        stopTrackingAllUsers() // Reuse the existing stopTrackingAllUsers method
    }

    // Stop tracking all users' locations
    func stopTrackingAllUsers() {
        for (userId, handle) in userLocationHandles {
            let userRef = Database.database().reference().child("users").child(userId).child("location")
            userRef.removeObserver(withHandle: handle)
        }
        userLocationHandles.removeAll()
    }

    // Stop tracking a specific user
    func stopTrackingUser(userId: String) {
        if let handle = userLocationHandles[userId] {
            let userRef = Database.database().reference().child("users").child(userId).child("location")
            userRef.removeObserver(withHandle: handle)
            userLocationHandles.removeValue(forKey: userId)
        }
    }

    // Fetch the physician’s location based on their address
    func fetchPhysicianLocation(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Failed to geocode address: \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    self.physicianLocation = location.coordinate
                    completion(location.coordinate)
                }
            } else {
                print("No location found for the address.")
                completion(nil)
            }
        }
    }

    // Fetch the patient’s location based on their address
    func fetchPatientLocation(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Failed to geocode address: \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    self.patientLocation = location.coordinate
                    completion(location.coordinate)
                }
            } else {
                print("No location found for the address.")
                completion(nil)
            }
        }
    }

    // CLLocationManagerDelegate method for error handling
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }

    // Check for location authorization status
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access denied. Please enable it in settings.")
        default:
            break
        }
    }
}
