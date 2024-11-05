//
//  MapView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/10/24.
//


import SwiftUI
import MapKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct MapView: UIViewRepresentable {
    @ObservedObject var orderManager: OrderManager
    @ObservedObject var locationManager: CombinedLocationManager
    var mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Enable clustering for pins and clusters
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        // Fetch and display physician locations
        orderManager.fetchOrders {
            orderManager.fetchPhysicianCoordinates { annotations in
                mapView.addAnnotations(annotations)
                print("Added \(annotations.count) physician annotations to the map")
                zoomToFitAllAnnotations() // Ensure correct zoom for all locations
            }
        }
        
        // Start listening for real-time updates of all users' locations
        listenForAllUserLocationUpdates()
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update the map if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator to handle MapKit delegate methods
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // Handle view for annotations and clusters
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // If annotation is a cluster, create a cluster view
            if let cluster = annotation as? MKClusterAnnotation {
                guard let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier) as? MKMarkerAnnotationView else {
                    return nil
                }
                clusterView.markerTintColor = .red
                clusterView.canShowCallout = true
                clusterView.glyphText = "\(cluster.memberAnnotations.count)" // Show the total count of annotations in the cluster
                return clusterView
            }
            // Handle individual annotation (user or physician)
            let identifier = annotation.title == "Assigned User" ? "userPin" : "physicianPin"
            
            guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView else {
                return nil
            }
            
            annotationView.canShowCallout = true
            annotationView.markerTintColor = (annotation.title == "Assigned User") ? .blue : .green
            return annotationView
        }

        // Renderer for polylines (route drawing)
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }

    // Function to listen for real-time updates of all users' locations
    func listenForAllUserLocationUpdates() {
        // Correctly access userLocations directly from the locationManager
        let userLocations = locationManager.allUserLocations
        
        for (userId, userCoordinate) in userLocations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = userCoordinate
            annotation.title = "User \(userId)"
            annotation.subtitle = "Real-time Location"
            
            // Remove old annotation if it exists
            mapView.annotations
                .filter { $0.title == "User \(userId)" }
                .forEach { mapView.removeAnnotation($0) }
            
            // Add new annotation
            mapView.addAnnotation(annotation)
        }
        
        // Ensure proper zoom for all locations after updates
        zoomToFitAllAnnotations()
    }

    // Updated function to zoom the map to fit all annotations (both users and physicians)
    func zoomToFitAllAnnotations() {
        var zoomRect = MKMapRect.null
        for annotation in mapView.annotations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0, height: 0)
            zoomRect = zoomRect.union(pointRect)
        }
        
        // Add padding to the region to ensure all annotations are fully visible
        mapView.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }

    // Function to draw the route between the user and the physician
    func drawRoute(userCoordinate: CLLocationCoordinate2D, physicianCoordinate: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: userCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: physicianCoordinate)
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            
            if let route = response?.routes.first {
                print("Route found with distance: \(route.distance) meters")
                mapView.addOverlay(route.polyline)
            }
        }
    }
}
