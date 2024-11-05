//
//  TPCustomMapView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/21/24.
//

import SwiftUI
import MapKit

struct PCustomMapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D? // Phlebotomist's location
    var physicianLocation: CLLocationCoordinate2D? // Physician's location
    @Binding var route: MKRoute? // Route between phlebotomist and physician
    var userAvatarURL: URL? // URL for user’s avatar
    var userName: String // Username for the logged-in user
    var physicianName: String // Referring physician's name

    let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false // Disable default user location marker
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations) // Remove old annotations
        uiView.removeOverlays(uiView.overlays) // Remove old polylines

        // Add custom annotation for user location
        if let userLocation = userLocation {
            let userAnnotation = CustomAnnotation(coordinate: userLocation, title: userName, subtitle: "User", avatarURL: userAvatarURL)
            uiView.addAnnotation(userAnnotation)
        }

        // Add annotation for physician location with referring physician's name
        if let physicianLocation = physicianLocation {
            let physicianAnnotation = MKPointAnnotation()
            physicianAnnotation.coordinate = physicianLocation
            physicianAnnotation.title = physicianName // Use referring physician's name
            uiView.addAnnotation(physicianAnnotation)
        }

        // Calculate and show the route if both locations are available
        if let userLocation = userLocation, let physicianLocation = physicianLocation, shouldCalculateRoute() {
            context.coordinator.calculateRoute(from: userLocation, to: physicianLocation, mapView: uiView)
        }

        // Zoom the map to fit both user and physician locations
        if let userLocation = userLocation, let physicianLocation = physicianLocation {
            zoomToFit(userLocation: userLocation, physicianLocation: physicianLocation, mapView: uiView)
        }
    }

    // Function to zoom to fit both user and physician locations
    private func zoomToFit(userLocation: CLLocationCoordinate2D, physicianLocation: CLLocationCoordinate2D, mapView: MKMapView) {
        var zoomRect = MKMapRect.null

        let userPoint = MKMapPoint(userLocation)
        let physicianPoint = MKMapPoint(physicianLocation)

        let userRect = MKMapRect(x: userPoint.x, y: userPoint.y, width: 0.1, height: 0.1)
        let physicianRect = MKMapRect(x: physicianPoint.x, y: physicianPoint.y, width: 0.1, height: 0.1)

        zoomRect = zoomRect.union(userRect)
        zoomRect = zoomRect.union(physicianRect)

        let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        mapView.setVisibleMapRect(zoomRect, edgePadding: edgePadding, animated: true)
    }

    // Throttle route requests to avoid API limits
    private func shouldCalculateRoute() -> Bool {
        // Implement route throttling if necessary
        return true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: PCustomMapView

        init(_ parent: PCustomMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let customAnnotation = annotation as? CustomAnnotation {
                let identifier = "CustomUserAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKAnnotationView
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    // Set a fixed size for the avatar
                    annotationView?.frame.size = CGSize(width: 40, height: 40)
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Set up the custom annotation view with user avatar and username
                annotationView?.image = UIImage(systemName: "person.circle.fill") // Default image
                if let avatarURL = customAnnotation.avatarURL {
                    // Load the avatar image asynchronously and resize it
                    let task = URLSession.shared.dataTask(with: avatarURL) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                let resizedImage = image.resizeToFit(size: CGSize(width: 40, height: 40))
                                let circularImage = resizedImage?.clipToCircle()
                                annotationView?.image = circularImage
                            
                            }
                        }
                    }
                    task.resume()
                }

                return annotationView
            } else if annotation.title == parent.physicianName {
                let identifier = "PhysicianAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.markerTintColor = .green
                } else {
                    annotationView?.annotation = annotation
                }
                annotationView?.glyphText = "📍"
                return annotationView
            }
            return nil
        }

        func calculateRoute(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D, mapView: MKMapView) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    print("Error calculating route: \(error.localizedDescription)")
                    return
                }

                if let route = response?.routes.first {
                    DispatchQueue.main.async {
                        mapView.addOverlay(route.polyline)
                    }
                }
            }
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
}

// Custom annotation class to hold user-specific information like avatar and username
class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var avatarURL: URL?

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, avatarURL: URL?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.avatarURL = avatarURL
    }
}

// Helper extension to resize the avatar image
extension UIImage {
    func resizeToFit(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func clipToCircle() -> UIImage? {
        let minDimension = min(size.width, size.height)
        let size = CGSize(width: minDimension, height: minDimension)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let rect = CGRect(origin: .zero, size: size)
        
        UIBezierPath(ovalIn: rect).addClip()
        draw(in: rect)
        
        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return circularImage
    }
}
