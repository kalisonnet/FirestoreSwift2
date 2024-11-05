//
//  PMOrderDetailView.
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseDatabase

struct PMOrderDetailView: View {
    var order: Order
    @StateObject private var locationManager = CombinedLocationManager()
    @State private var physicianLocation: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var phlebotomistAvatarURL: URL?
    @State private var phlebotomistName: String = "Phlebotomist"
    @State private var showAddOrderView = false
    @State private var showPrintSheet = false
    @State private var distanceInMiles: Double? // New state variable for distance
    
    var physicianName: String { order.referring_physician_name }

    var body: some View {
        ScrollView { // Wrap entire VStack in ScrollView
            VStack(alignment: .leading, spacing: 10) {
                // Display order details
                Text("Patient Name: \(order.patient_name)")
                    .font(.headline)
                Text("Test Name: \(order.test_name)")
                    .font(.subheadline)
                Text("Test Date: \(order.order_date)")
                    .font(.subheadline)
                
                Text("Order Status History")
                    .font(.headline)
                    .padding(.bottom, 10)

                ForEach(order.status, id: \.timestamp) { statusEntry in
                    HStack {
                        Text("Status: \(statusEntry.status)")
                        Spacer()
                        Text("Time: \(formatTimestamp(statusEntry.timestamp))")
                            .foregroundColor(.gray)
                    }
                }

                // Display Barcode image
                if !order.barcode.isEmpty {
                    if let barcodeImage = generateBarcode(from: order.barcode) {
                        Image(uiImage: barcodeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 80)
                    } else {
                        Text("Failed to generate Barcode").foregroundColor(.red)
                    }
                } else {
                    Text("No Barcode Available")
                }

                // Check if the order status is "Completed"
                if order.status.contains(where: { $0.status == "Completed" }) {
                    showInventorySection()
                } else {
                    PMCustomMapView(
                        userLocation: $locationManager.specificPhlebotomistLocation,
                        physicianLocation: physicianLocation,
                        route: $route,
                        userAvatarURL: phlebotomistAvatarURL,
                        userName: phlebotomistName,
                        physicianName: physicianName
                    )
                    .frame(height: 300)
                    .onAppear {
                        resetState()
                        fetchPhysicianLocation(for: order)

                        if let phlebotomistId = order.phlebotomist.first, !phlebotomistId.isEmpty {
                            locationManager.startTrackingPhlebotomist(phlebotomistId: phlebotomistId)
                            fetchPhlebotomistDetails(phlebotomistId: phlebotomistId)
                        }
                        setupView()
                    }

                    // Display distance if route is calculated
                    if let distanceInMiles = distanceInMiles {
                                            Text("Total Distance: \(distanceInMiles, specifier: "%.2f") miles")
                                                .padding()
                                        }
                    


                    Spacer()

                    Button(action: { showAddOrderView = true }) {
                        Text("Edit Order")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                // Print button
                Button(action: printOrderDetails) {
                    Text("Print")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .sheet(isPresented: $showAddOrderView) {
                AddOrderView(orderManager: OrderManager.shared, order: order)
            }
        }
    }

    // Display the statuses with timestamps when the order is completed
    func showStatusesWithTimestamps() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Status History")
                .font(.title2)
                .padding(.bottom, 10)

            ForEach(order.status, id: \.timestamp) { statusEntry in
                HStack {
                    Text("Status: \(statusEntry.status)")
                    Spacer()
                    Text("Time: \(formatTimestamp(statusEntry.timestamp))")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    
    // Function to set up the view and start tracking locations
        private func setupView() {
            resetState()
            fetchPhysicianLocation(for: order)

            if let phlebotomistId = order.phlebotomist.first, !phlebotomistId.isEmpty {
                locationManager.startTrackingPhlebotomist(phlebotomistId: phlebotomistId)
                fetchPhlebotomistDetails(phlebotomistId: phlebotomistId)
            }
        }
    
    
    private func updateDistance() {
            if let route = route {
                distanceInMiles = route.distance / 1609.34

                // Update Firebase with the new distance
                if let distance = distanceInMiles, let orderId = order.id {
                    let databaseRef = Database.database().reference().child("orders").child(orderId)
                    databaseRef.updateChildValues(["distance": distance])
                }
            }
        }
    
    // Function to calculate the route and update the distance in Firebase
        private func calculateAndStoreDistance() {
            guard let userLocation = locationManager.specificPhlebotomistLocation, let physicianLocation = physicianLocation else { return }

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: physicianLocation))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let route = response?.routes.first {
                    self.route = route
                    self.distanceInMiles = route.distance / 1609.34 // Convert meters to miles

                    // Update Firebase with the calculated distance
                    if let orderId = order.id {
                        let databaseRef = Database.database().reference().child("orders").child(orderId)
                        databaseRef.updateChildValues(["distance": self.distanceInMiles ?? 0])
                    }
                } else if let error = error {
                    print("Error calculating route: \(error.localizedDescription)")
                }
            }
        }
    
    
    // Inventory Section: Display collectionTubes, pictures, and attachments
    func showInventorySection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Inventory")
                .font(.title2)
                .padding(.top, 20)

            // Collection Tubes Section
            if !order.collectionTubes.isEmpty {
                VStack(alignment: .leading) {
                    Text("Collection Tubes:")
                        .font(.headline)
                    ForEach(order.collectionTubes) { tube in
                        Text("Tube: \(tube.name), Quantity: \(tube.quantity)")
                    }
                }
                .padding(.bottom, 10)
            } else {
                Text("No collection tubes added")
                    .foregroundColor(.gray)
                    .italic()
            }

            // Pictures Section
            if let pictures = order.picture, !pictures.isEmpty {
                VStack(alignment: .leading) {
                    Text("Pictures:")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(pictures, id: \.self) { pictureURL in
                                AsyncImage(url: URL(string: pictureURL)) { image in
                                    image.resizable()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            } else {
                Text("No pictures available")
                    .foregroundColor(.gray)
                    .italic()
            }

            // Attachments Section
            if let attachment = order.attachment, !attachment.isEmpty {
                VStack(alignment: .leading) {
                    Text("Attachments:")
                        .font(.headline)
                    Text("Attachment URL: \(attachment)")
                        .foregroundColor(.blue)
                        .underline()
                        .onTapGesture {
                            if let url = URL(string: attachment) {
                                UIApplication.shared.open(url)
                            }
                        }
                }
            } else {
                Text("No attachments available")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Print Order Details
    func printOrderDetails() {
        let printRenderer = OrderPrintPageRenderer(order: order, barcodeImage: generateBarcode(from: order.barcode))

        let printController = UIPrintInteractionController.shared
        printController.printPageRenderer = printRenderer

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Order Details"
        printController.printInfo = printInfo

        printController.present(animated: true, completionHandler: nil)
    }

    // Reset state variables on view appear
    func resetState() {
        physicianLocation = nil
        route = nil
        locationManager.specificPhlebotomistLocation = nil
    }

    // Fetch the physician's location
    func fetchPhysicianLocation(for order: Order) {
        let address = "\(order.physician_address), \(order.physician_city), \(order.physician_state), \(order.physician_zipcode)"
        locationManager.fetchPhysicianLocation(address: address) { location in
            if let location = location {
                self.physicianLocation = location
                // Calculate and store distance once both locations are set
                                if locationManager.specificPhlebotomistLocation != nil {
                                    calculateAndStoreDistance()
                                }
            }
        }
    }
    
    // Fetch the phlebotomist details
    func fetchPhlebotomistDetails(phlebotomistId: String) {
        let userRef = Database.database().reference().child("users").child(phlebotomistId)
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else {
                print("No user data found for phlebotomist.")
                self.phlebotomistName = "Unknown Phlebotomist"
                return
            }

            if let avatarUrlString = userData["avatarUrl"] as? String,
               let avatarUrl = URL(string: avatarUrlString) {
                self.phlebotomistAvatarURL = avatarUrl
            }

            self.phlebotomistName = userData["username"] as? String ?? "Unknown Phlebotomist"
        }
    }
    
    // Calculate the route
    func calculateRoute() {
        guard let userLocation = locationManager.specificPhlebotomistLocation, let physicianLocation = physicianLocation else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: physicianLocation))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                self.route = route
            }
        }
    }

    // Function to format the timestamp
    func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    // Generate barcode image
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)

        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")

            if let outputImage = filter.outputImage {
                let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
                let context = CIContext()
                if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }

        return nil
    }
}


// MARK: - Custom Print Renderer
class OrderPrintPageRenderer: UIPrintPageRenderer {
    var order: Order
    var barcodeImage: UIImage?

    init(order: Order, barcodeImage: UIImage?) {
        self.order = order
        self.barcodeImage = barcodeImage
        super.init()

        let pageFrame = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        self.setValue(NSValue(cgRect: pageFrame), forKey: "paperRect")
        let printableRect = pageFrame.insetBy(dx: 20, dy: 20)
        self.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
    }

    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        super.drawPage(at: pageIndex, in: printableRect)

        // Draw patient name
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]
        let nameString = "Patient: \(order.patient_name)"
        nameString.draw(at: CGPoint(x: printableRect.origin.x + 20, y: printableRect.origin.y + 40), withAttributes: nameAttributes)

        // Draw test name
        let testNameString = "Test Name: \(order.test_name)"
        testNameString.draw(at: CGPoint(x: printableRect.origin.x + 20, y: printableRect.origin.y + 80), withAttributes: nameAttributes)

        // Draw barcode
        if let barcodeImage = barcodeImage {
            let barcodeRect = CGRect(x: printableRect.origin.x + 20, y: printableRect.origin.y + 120, width: 200, height: 80)
            barcodeImage.draw(in: barcodeRect)
        }
    }
}
