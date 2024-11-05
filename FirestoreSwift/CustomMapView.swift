//
//  CustomMapView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/16/24.
//

import SwiftUI
import MapKit

struct CustomMapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D? // For the logged-in user’s location (if needed)
    @Binding var phlebotomistLocation: CLLocationCoordinate2D? // For tracking the phlebotomist’s live location
    @Binding var physicianLocation: CLLocationCoordinate2D?
    @Binding var route: MKRoute?
    
    var mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Clear existing annotations and overlays
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)
        
        var annotations = [MKPointAnnotation]()

        // Show phlebotomist's live location if available
        if let phlebotomistLocation = phlebotomistLocation {
            let phlebotomistAnnotation = MKPointAnnotation()
            phlebotomistAnnotation.coordinate = phlebotomistLocation
            phlebotomistAnnotation.title = "Phlebotomist"
            annotations.append(phlebotomistAnnotation)
        }

        // Show the logged-in user's location if needed
        if let userLocation = userLocation {
            let userAnnotation = MKPointAnnotation()
            userAnnotation.coordinate = userLocation
            userAnnotation.title = "User Location"
            annotations.append(userAnnotation)
        }

        // Show physician's location
        if let physicianLocation = physicianLocation {
            let physicianAnnotation = MKPointAnnotation()
            physicianAnnotation.coordinate = physicianLocation
            physicianAnnotation.title = "Physician"
            annotations.append(physicianAnnotation)
        }

        // Add all annotations to the map
        uiView.showAnnotations(annotations, animated: true)

        // Add route overlay if available
        if let route = route {
            uiView.addOverlay(route.polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView

        init(_ parent: CustomMapView) {
            self.parent = parent
        }

        // Rendering the route overlay
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
