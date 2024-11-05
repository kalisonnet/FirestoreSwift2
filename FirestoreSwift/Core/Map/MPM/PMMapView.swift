//
//  PMMapView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//

import SwiftUI
import MapKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct PMMapView: UIViewRepresentable {
    @ObservedObject var orderManager: OrderManager
    @ObservedObject var locationManager: CombinedLocationManager
    @Binding var showPatientLocation: Bool // Binding to track the toggle state

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: PMMapView

        init(parent: PMMapView) {
            self.parent = parent
        }

        // Handle annotation views (for physicians, patients, and phlebotomists)
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let phlebotomistAnnotation = annotation as? PhlebotomistAnnotation {
                let identifier = "PhlebotomistAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKAnnotationView

                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.frame.size = CGSize(width: 40, height: 40)
                } else {
                    annotationView?.annotation = annotation
                }

                // Set default image or system image as a placeholder
                annotationView?.image = UIImage(systemName: "person.circle.fill") // Default system placeholder

                if let avatarUrl = phlebotomistAnnotation.avatarUrl, let url = URL(string: avatarUrl) {
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                if let resizedImage = image.resizeImageToFit(size: CGSize(width: 40, height: 30))?.clipImageToCircle() {
                                    annotationView?.image = resizedImage
                                }
                            }
                        }
                    }
                }


                // Configure callout view with phlebotomist name
                let calloutLabel = UILabel()
                calloutLabel.text = phlebotomistAnnotation.username
                annotationView?.detailCalloutAccessoryView = calloutLabel

                return annotationView
            } else if let cluster = annotation as? MKClusterAnnotation {
                let clusterView = MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: nil)
                clusterView.markerTintColor = .red
                clusterView.glyphText = "\(cluster.memberAnnotations.count)"
                clusterView.canShowCallout = true
                return clusterView
            }

            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            annotationView.canShowCallout = true
            annotationView.markerTintColor = annotation.subtitle == "Patient" ? .blue : .green
            return annotationView
        }

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

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false // Disable showing your own location
        mapView.userTrackingMode = .none // Do not follow the user's location

        // Start tracking all phlebotomists
        locationManager.startTrackingAllPhlebotomists()
        
        // Fetch initial annotations
        updateMapAnnotations(on: mapView)
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update annotations when the view updates
        updateMapAnnotations(on: uiView)
    }

    // Update the map annotations to show phlebotomists, patients, and physicians
    func updateMapAnnotations(on mapView: MKMapView) {
        // Remove all previous annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add phlebotomist locations with avatars and usernames
        for (_, details) in locationManager.allUserDetails {
            let annotation = PhlebotomistAnnotation(coordinate: details.coordinate, avatarUrl: details.avatarUrl, username: details.username)
            mapView.addAnnotation(annotation)
        }

        if showPatientLocation {
            // Show patient locations
            orderManager.fetchPatientCoordinates { annotations in
                annotations.forEach { $0.subtitle = "Patient" }
                mapView.addAnnotations(annotations)
                print("Added \(annotations.count) patient annotations to the map")
                zoomToFitAllAnnotations(on: mapView)
            }
        } else {
            // Show physician locations
            orderManager.fetchPhysicianCoordinates { annotations in
                annotations.forEach { $0.subtitle = "Physician" }
                mapView.addAnnotations(annotations)
                print("Added \(annotations.count) physician annotations to the map")
                zoomToFitAllAnnotations(on: mapView)
            }
        }

        // Debug: Print how many phlebotomist annotations were added
        print("Added \(mapView.annotations.count) annotations (phlebotomists, patients, and physicians)")
        
        // Zoom to fit all annotations
        if !mapView.annotations.isEmpty {
            zoomToFitAllAnnotations(on: mapView)
        }
    }

    // Zoom to fit all annotations
    func zoomToFitAllAnnotations(on mapView: MKMapView) {
        var zoomRect = MKMapRect.null
        
        for annotation in mapView.annotations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0, height: 0)
            zoomRect = zoomRect.union(pointRect)
        }

        if !zoomRect.isNull {
            mapView.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        }
    }
}

// Custom annotation class for phlebotomists
class PhlebotomistAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var avatarUrl: String?
    var username: String
    var title: String? {
        return username // Set the username as the title
    }

    init(coordinate: CLLocationCoordinate2D, avatarUrl: String?, username: String) {
        self.coordinate = coordinate
        self.avatarUrl = avatarUrl
        self.username = username
    }
}

// Renaming these methods to avoid conflicts
extension UIImage {
    func resizeImageToFit(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func clipImageToCircle() -> UIImage? {
        let minEdge = min(self.size.width, self.size.height)
        let size = CGSize(width: minEdge, height: minEdge)
        let rect = CGRect(origin: CGPoint(x: (self.size.width - minEdge) / 2, y: (self.size.height - minEdge) / 2), size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
        self.draw(in: CGRect(origin: CGPoint(x: -rect.origin.x, y: -rect.origin.y), size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

