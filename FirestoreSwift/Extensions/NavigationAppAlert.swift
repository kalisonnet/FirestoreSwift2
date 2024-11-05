//
//  NavigationAppAlert.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/10/24.
//

import UIKit
import SwiftUI
import MapKit

// Wrap UIAlertController in UIViewControllerRepresentable for SwiftUI
struct NavigationAppAlert: UIViewControllerRepresentable {
    var physicianLocation: CLLocationCoordinate2D

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        DispatchQueue.main.async {
            self.presentAlert(on: viewController)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private func presentAlert(on viewController: UIViewController) {
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
        
        // Google Maps option if available
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
        
        // Present the alert
        viewController.present(alertController, animated: true, completion: nil)
    }
}
