//
//  PDetailedMapView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/19/24.
//

/*import SwiftUI
import MapKit

struct PDetailedMapView: View {
    @ObservedObject var locationManager: CombinedLocationManager
    @State private var physicianLocation: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var shouldZoom = false
    var mapView = MKMapView()
    var order: Order // Order is passed into the view

    var body: some View {
        VStack {
            PCustomMapView(
                userLocation: $locationManager.userLocation,  // Phlebotomist's own location
                physicianLocation: $physicianLocation,         // Physician's location
                route: $route,                                 // Route between user and physician
                mapView: mapView                               // Map view object
            )
                .frame(height: 300)
                .onAppear {
                    setupMapForOrder()
                }
                .onChange(of: order) { oldValue, newOrder in
                    resetMapData()
                    setupMapForOrder()
                }

            if let route = route {
                Text("Total Distance: \(route.distance / 1000, specifier: "%.2f") km")
                    .padding()
            }

            Button(action: startNavigation) {
                Text("Start Navigation")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }

    // New method to setup map for the selected order
    func setupMapForOrder() {
        fetchPhysicianLocation {
            if let userLocation = locationManager.userLocation, let physicianLocation = physicianLocation {
                shouldZoom = true
                zoomToFit(userLocation: userLocation, physicianLocation: physicianLocation)
                calculateRoute() // Calculate route for the selected order
            }
        }
    }

    // Fetch the physician location based on the address in the order
    func fetchPhysicianLocation(completion: @escaping () -> Void) {
        let address = "\(order.physician_address), \(order.physician_city), \(order.physician_state), \(order.physician_zipcode)"
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print("Geocoding failed: \(error.localizedDescription)")
                return
            }
            if let location = placemarks?.first?.location {
                physicianLocation = location.coordinate
                completion() // Call the completion handler after geocoding is done
            } else {
                print("No location found for the address.")
            }
        }
    }

    // Reset the state of the map data when a new order is fetched
    func resetMapData() {
        physicianLocation = nil
        route = nil
        mapView.removeOverlays(mapView.overlays) // Ensure overlays are removed
        mapView.removeAnnotations(mapView.annotations) // Clear previous annotations
    }

    // Calculate the route from the user's location to the physician's location
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
                mapView.addOverlay(route.polyline) // Add the new route polyline to the map
                shouldZoom = true // Trigger zoom once the route is calculated
            }
        }
    }

    // Zoom the map to fit both the user and physician locations
    func zoomToFit(userLocation: CLLocationCoordinate2D, physicianLocation: CLLocationCoordinate2D) {
        let annotations = [
            MKPointAnnotation(__coordinate: userLocation),
            MKPointAnnotation(__coordinate: physicianLocation)
        ]
        mapView.showAnnotations(annotations, animated: true)
    }

    // Start navigation when the user clicks the button
    func startNavigation() {
        guard let physicianLocation = physicianLocation else { return }
        let url = URL(string: "http://maps.apple.com/?daddr=\(physicianLocation.latitude),\(physicianLocation.longitude)&dirflg=d")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}*/
