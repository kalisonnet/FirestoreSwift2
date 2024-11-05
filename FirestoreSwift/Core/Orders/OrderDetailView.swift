//
//  OrderDetailView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/15/24.
//

/*import SwiftUI
import MapKit
import FirebaseAuth

struct OrderDetailView: View {
    var order: Order
    @StateObject private var locationManager = CombinedLocationManager(userId: Auth.auth().currentUser?.uid ?? "")
    @State private var showAddOrderView = false
    @StateObject var orderManager = OrderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Patient Name: \(order.patient_name)")
                .font(.headline)
            Text("Test Name: \(order.test_name)")
                .font(.subheadline)
            
            // Display Barcode image
            if !order.barcode.isEmpty {  // Check if the barcode string is not empty
                if let barcodeImage = generateBarcode(from: order.barcode) {
                    Image(uiImage: barcodeImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 80)
                } else {
                    Text("Failed to generate Barcode")
                        .foregroundColor(.red)
                }
            } else {
                Text("No Barcode Available")
            }
            
            Spacer()
            
            // DetailedMapView showing user and physician locations with route
            DetailedMapView(locationManager: locationManager, order: order)
                .frame(height: 300)
            
            
            Spacer()
            
            Button(action: {
                // Edit order action here
                showAddOrderView = true
            }) {
                Text("Edit Order")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        // Show AddOrderView when `showAddOrderView` is true
        .sheet(isPresented: $showAddOrderView) {
            AddOrderView(orderManager: orderManager, order: order) // Pass the order to edit
        }
    }
    
    // Function to generate barcode image from a string
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        
        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                let scaleX = 3.0
                let scaleY = 3.0
                let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY)))
                
                // Convert CIImage to UIImage
                let context = CIContext()
                if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
}*/
