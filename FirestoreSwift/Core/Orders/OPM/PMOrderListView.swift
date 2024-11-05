//
//  PMOrderListView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//

import SwiftUI
import FirebaseStorage

struct PMOrderListView: View {
    @StateObject var orderManager = OrderManager.shared
    @StateObject var userManager = UserManager()
    @State private var showAddOrderView = false
    @State private var showAssignUserView = false
    @State private var selectedOrder: Order? = nil
    @State private var selectedOrders = Set<String>()
    @State private var isSelecting = false
    @State private var selectAll = false
    @State private var showStatusActionSheet = false
    @State private var showDonePopup = false
    @State private var collectionDate = Date()
    @State private var collectionTime = Date()
    @State private var collectionTubes: [CollectionTube] = []
    @State private var note: String = ""
    @State private var attachment: UIImage?
    @State private var pictures: [UIImage] = [] // For multiple images
    @State private var showImagePicker = false
    @State private var showPOrderDetailView = false
    @State private var searchText = "" // For search functionality
    
    
    @State private var showStatusSelection = false // New state for showing status selection view
    
    @State private var rules: [Rule] = [] // Populate this from your actual source of rules
    
    @State private var showArchiveView = false // New state to show ArchiveView
    
    
    var filteredOrders: [Order] {
            return orderManager.orders
                .filter { !$0.status.contains(where: { $0.status == "Completed" }) } // Exclude completed orders
                .filter { searchText.isEmpty || $0.patient_name.lowercased().contains(searchText.lowercased()) }
        }

        var body: some View {
            NavigationView {
                VStack {
                    // Search bar
                    TextField("Search Orders", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    List {
                        ForEach(filteredOrders, id: \.id) { order in
                            OrderRowView(order: order, isSelecting: isSelecting, selectedOrders: $selectedOrders, userManager: userManager)
                                .onTapGesture {
                                    if !isSelecting {
                                        selectedOrder = order
                                        if let orderId = selectedOrder?.id, !orderId.isEmpty {
                                            showPOrderDetailView = true // Only trigger navigation if orderId is valid
                                        } else {
                                            print("Invalid order ID")
                                        }
                                    }
                                }
                                .background(
                                    NavigationLink(
                                        destination: PMOrderDetailView(order: selectedOrder ?? order)
                                            .onDisappear {
                                                selectedOrder = nil // Reset selected order when navigating back
                                            },
                                        tag: order,
                                        selection: $selectedOrder
                                    ) {
                                        EmptyView()
                                    }
                                    .hidden()
                                )
                        }
                        .onDelete(perform: deleteOrder)
                    }
                    .listStyle(PlainListStyle())
                    .navigationTitle("Orders")
                    .navigationBarItems(
                        leading: isSelecting ? selectAllButton : nil,
                        trailing: HStack {
                            Button(action: { showAddOrderView = true }) {
                                Image(systemName: "plus")
                            }
                            editButton
                            Button("Archive") {
                                showArchiveView = true
                            }
                        }
                    )
                    
                    if !selectedOrders.isEmpty {
                        actionToolbar
                    }
                }
                .sheet(isPresented: $showAddOrderView) {
                    AddOrderView(orderManager: orderManager)
                }
                .sheet(isPresented: $showAssignUserView) {
                    AssignUserView(userManager: userManager) { users in
                        assignSelectedOrders(to: users)
                    }
                }
                .sheet(isPresented: $showStatusSelection) {
                    StatusSelectionView(
                        showStatusSelection: $showStatusSelection,
                        showDonePopup: $showDonePopup,
                        updateOrderStatus: updateOrderStatus
                    )
                }
                .sheet(isPresented: $showDonePopup) {
                    DonePopupView(
                        collectionDate:$collectionDate,
                        collectionTime:$collectionTime,
                        collectionTubes: $collectionTubes,
                        note: $note,
                        attachment: $attachment,
                        showImagePicker: $showImagePicker,
                        pictures: $pictures
                    ) {
                        saveOrderCompletion()
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(images: $pictures)
                }
                .sheet(isPresented: $showArchiveView) {
                    ArchiveView(orderManager: orderManager)
                }
                .onAppear {
                    orderManager.fetchOrders()
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

    private var actionToolbar: some View {
        HStack {
            Button(action: { showAssignUserView = true }) { Text("Assign").frame(maxWidth: .infinity) }
            Button(action: printLabelsForSelectedOrders) { Text("Print Label").frame(maxWidth: .infinity) }
            Button(action: markSelectedOrders) { Text("Mark").frame(maxWidth: .infinity) }
            Button(action: deleteSelectedOrders) { Text("Delete").frame(maxWidth: .infinity).foregroundColor(.red) }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }

    private var editButton: some View {
        Button(action: {
            isSelecting.toggle()
            if !isSelecting { selectedOrders.removeAll(); selectAll = false }
        }) {
            Text(isSelecting ? "Done" : "Edit")
        }
    }
    
    
    
    private func selectAllFilteredOrders() {
        selectedOrders = Set(filteredOrders.compactMap { $0.id })
    }
    
    private var selectAllButton: some View {
        Button(action: {
            if selectAll {
                deselectAllOrders()
            } else {
                selectAllFilteredOrders() // Only select the filtered results
            }
            selectAll.toggle()
        }) {
            Text(selectAll ? "Deselect All" : "Select All")
        }
    }

    private func toggleSelection(for order: Order) {
        if selectedOrders.contains(order.id ?? "") {
            selectedOrders.remove(order.id ?? "")
        } else {
            selectedOrders.insert(order.id ?? "")
        }
    }

    private func selectAllOrders() {
        selectedOrders = Set(orderManager.orders.compactMap { $0.id }) // Use compactMap to unwrap optional IDs
    }

    private func deselectAllOrders() {
        selectedOrders.removeAll()
    }

    private func deleteOrder(at offsets: IndexSet) {
        offsets.forEach { index in
            let order = orderManager.orders[index]
            orderManager.deleteOrder(order)
        }
    }

    private func assignSelectedOrders(to users: [User]) {
        selectedOrders.forEach { orderId in
            if var order = orderManager.orders.first(where: { $0.id == orderId }) {
                order.phlebotomist = users.map { $0.id }
                orderManager.updateOrder(order)
            }
        }
        selectedOrders.removeAll()
        isSelecting = false
    }

    private func printLabelsForSelectedOrders() {
        for orderId in selectedOrders {
            if let order = orderManager.orders.first(where: { $0.id == orderId }) {
                if let barcodeImage = generateBarcode(from: order.barcode) {
                    printOrderLabel(patientName: order.patient_name, barcodeImage: barcodeImage)
                } else {
                    print("Failed to generate barcode for order \(String(describing: order.id))")
                }
            }
        }
    }

    // Helper function to generate a barcode image from a string
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        
        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                // Transform the image to a larger size
                let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
                return UIImage(ciImage: transformedImage)
            }
        }
        
        return nil
    }

    // Function to print the order label with a barcode image and patient name
    private func printOrderLabel(patientName: String, barcodeImage: UIImage) {
        // Initialize the custom print page renderer
        let printRenderer = InMemoryPrintPageRenderer(patientName: patientName, barcodeImage: barcodeImage)
        
        // Create the print interaction controller
        let printController = UIPrintInteractionController.shared
        printController.printPageRenderer = printRenderer
        
        // Set print job info
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = "Print Order Label"
        printController.printInfo = printInfo
        
        // Present the print interaction controller
        printController.present(animated: true, completionHandler: nil)
    }

    // Custom print page renderer class to render the barcode image and patient name
    class InMemoryPrintPageRenderer: UIPrintPageRenderer {
        var patientName: String
        var barcodeImage: UIImage
        
        init(patientName: String, barcodeImage: UIImage) {
            self.patientName = patientName
            self.barcodeImage = barcodeImage
            super.init()
            
            // Set up margins and paper size
            let pageFrame = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size in points
            self.setValue(NSValue(cgRect: pageFrame), forKey: "paperRect")
            let printableRect = pageFrame.insetBy(dx: 20, dy: 20) // Set margins
            self.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        }
        
        // Draw the content for the page
        func drawContent(forPageAt pageIndex: Int, in contentRect: CGRect) {
            // Draw the patient name at the top of the page
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            let nameString = NSString(string: "Patient: \(patientName)")
            nameString.draw(at: CGPoint(x: contentRect.origin.x + 20, y: contentRect.origin.y + 40), withAttributes: nameAttributes)
            
            // Draw the barcode image below the patient name
            let barcodeRect = CGRect(x: contentRect.origin.x + 20, y: contentRect.origin.y + 80, width: 200, height: 80)
            barcodeImage.draw(in: barcodeRect)
        }
    }


    private func markSelectedOrders() {
            if !selectedOrders.isEmpty {
                showStatusSelection = true // Show StatusSelectionView
            }
        }

    private func deleteSelectedOrders() {
        selectedOrders.forEach { orderId in
            if let order = orderManager.orders.first(where: { $0.id == orderId }) {
                orderManager.deleteOrder(order)
            }
        }
        selectedOrders.removeAll()
        isSelecting = false
    }

    // Function to update the order status with timestamp
    private func updateOrderStatus(status: String) {
            let timestamp = Date()
            selectedOrders.forEach { orderId in
                if var order = orderManager.orders.first(where: { $0.id == orderId }) {
                    let statusEntry = OrderStatus(status: status, timestamp: timestamp)
                    order.status.append(statusEntry)
                    orderManager.updateOrder(order)
                }
            }
            
            selectedOrders.removeAll()
            isSelecting = false
        }

    // Function to save the completion of the order, including attachments and picture
    private func saveOrderCompletion() {
        let timestamp = Date()
        
        selectedOrders.forEach { orderId in
            if let order = orderManager.orders.first(where: { $0.id == orderId }) {
                var updatedOrder = order // Create a mutable copy
                
                // Append the "Completed" status with the timestamp
                let statusEntry = OrderStatus(status: "Completed", timestamp: timestamp)
                updatedOrder.status.append(statusEntry)
                
                // Check if the note text is not empty and append to the notes array
                if !note.isEmpty {
                    let newOrderNote = OrderNote(note: note, timestamp: timestamp)
                    updatedOrder.note = (updatedOrder.note ?? []) + [newOrderNote] // Append to existing notes array
                }
                
                // Concatenate existing collection tubes with new ones to avoid overwriting
                updatedOrder.collectionTubes = (updatedOrder.collectionTubes) + collectionTubes
                
                let dispatchGroup = DispatchGroup()
                
                // Handle the attachment upload
                if let attachmentImage = attachment {
                    dispatchGroup.enter()
                    uploadAttachment(image: attachmentImage, folder: "attachments") { url in
                        updatedOrder.attachment = url?.absoluteString
                        dispatchGroup.leave()
                    }
                }
                
                // Handle the multiple picture uploads
                var uploadedPictureUrls: [String] = updatedOrder.picture ?? [] // Append to existing pictures array
                for pictureImage in pictures {
                    dispatchGroup.enter()
                    uploadAttachment(image: pictureImage, folder: "pictures") { url in
                        if let urlString = url?.absoluteString {
                            uploadedPictureUrls.append(urlString)
                        }
                        dispatchGroup.leave()
                    }
                }
                
                // Once all uploads are complete, update the order
                dispatchGroup.notify(queue: .main) {
                    updatedOrder.picture = uploadedPictureUrls
                    orderManager.updateOrder(updatedOrder)
                }
            }
        }
        
        selectedOrders.removeAll()
        isSelecting = false
    }





    private func uploadAttachment(image: UIImage, folder: String, completion: @escaping (URL?) -> Void) {
        let storageRef = Storage.storage().reference().child("\(folder)/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading \(folder): \(error.localizedDescription)")
                completion(nil)
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL for \(folder): \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url)
            }
        }
    }
}



