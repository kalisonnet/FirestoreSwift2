//
//  SOrderListView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//

/*import SwiftUI
import FirebaseStorage

struct SOrderListView: View {
    @StateObject var orderManager = OrderManager.shared
    @StateObject var userManager = UserManager() // Fetch the list of users
    @State private var showAddOrderView = false
    @State private var showAssignUserView = false // Show user assignment view
    @State private var selectedOrder: Order? = nil // This holds the currently selected order
    @State private var selectedOrders = Set<String>() // Set to track selected order IDs
    @State private var isSelecting = false // Toggle selection mode
    @State private var selectAll = false // Toggle between Select All and Deselect All
    @State private var showStatusActionSheet = false
    @State private var showDonePopup = false
    @State private var note: String = ""
    @State private var attachment: UIImage?
    @State private var showImagePicker = false
    @State private var showOrderDetailView = false // Controls navigation to OrderDetailView
    
    var body: some View {
        NavigationView {
            VStack {
                // List of Orders with checkboxes
                List {
                    ForEach(orderManager.orders, id: \.id) { order in
                        HStack {
                            // Show checkbox in selection mode
                            if isSelecting {
                                Image(systemName: selectedOrders.contains(order.id ?? "") ? "checkmark.circle.fill" : "circle")
                                    .onTapGesture {
                                        toggleSelection(for: order)
                                    }
                            }
                            
                            // Order information
                            VStack(alignment: .leading) {
                                Text(order.test_name)
                                    .font(.headline)
                                Text(order.patient_name)
                                    .font(.subheadline)
                                
                                // Show the assigned users' avatars and names (phlebotomists)
                                if !order.phlebotomist.isEmpty {
                                    ForEach(order.phlebotomist, id: \.self) { assignedUserId in
                                        if let assignedUser = userManager.users.first(where: { $0.id == assignedUserId }) {
                                            HStack {
                                                AsyncImage(url: URL(string: assignedUser.avatarUrl)) { image in
                                                    image
                                                        .resizable()
                                                        .frame(width: 30, height: 30)
                                                        .clipShape(Circle())
                                                } placeholder: {
                                                    Circle().frame(width: 30, height: 30).foregroundColor(.gray)
                                                }
                                                Text("Assigned to: \(assignedUser.username)")
                                                    .font(.subheadline)
                                            }
                                        }
                                    }
                                } else {
                                    Text("Not Assigned")
                                        .font(.subheadline)
                                }
                            }
                            .onTapGesture {
                                if !isSelecting {
                                    // Explicitly set selectedOrder
                                    selectedOrder = order
                                }
                            }
                            
                            // NavigationLink to OrderDetailView
                            NavigationLink(
                                destination: OrderDetailView(order: selectedOrder ?? order),
                                isActive: Binding(
                                    get: { selectedOrder != nil },  // Navigate only if selectedOrder is not nil
                                    set: { if !$0 { selectedOrder = nil } }  // Reset selectedOrder when dismissed
                                )
                            ) {
                                EmptyView() // NavigationLink's destination
                            }
                            .frame(width: 0, height: 0) // Hidden NavigationLink
                        }
                    }
                    .onDelete(perform: deleteOrder) // Enable deletion of orders
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Orders")
                .navigationBarItems(
                    leading: isSelecting ? selectAllButton : nil, // Show Select All button only in edit mode
                    trailing: HStack {
                        // "+" Button to add a new order
                        Button(action: {
                            showAddOrderView = true
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        // Edit button for toggling selection mode
                        editButton
                    }
                )
                
                // Bottom toolbar with actions if any order is selected
                if !selectedOrders.isEmpty {
                    HStack {
                        Button(action: {
                            showAssignUserView = true // Show the assign user sheet
                        }) {
                            Text("Assign")
                                .frame(maxWidth: .infinity)
                        }
                        Button(action: printLabelsForSelectedOrders) {
                            Text("Print Label")
                                .frame(maxWidth: .infinity)
                        }
                        Button(action: markSelectedOrders) {
                            Text("Mark")
                                .frame(maxWidth: .infinity)
                        }
                        Button(action: deleteSelectedOrders) {
                            Text("Delete")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                }
            }
            // Show the AddOrderView when required
            .sheet(isPresented: $showAddOrderView) {
                AddOrderView(orderManager: orderManager)
            }
            // Show the AssignUserView for assigning users to orders
            .sheet(isPresented: $showAssignUserView) {
                AssignUserView(userManager: userManager) { users in
                    assignSelectedOrders(to: users)
                }
            }
            // Show status action sheet
            .actionSheet(isPresented: $showStatusActionSheet) {
                ActionSheet(title: Text("Select Status"), buttons: [
                    .default(Text("Start")) {
                        updateOrderStatus(status: "In-Progress")
                    },
                    .default(Text("Done")) {
                        showDonePopup = true
                    },
                    .destructive(Text("Failed")) {
                        updateOrderStatus(status: "Failed")
                    },
                    .cancel()
                ])
            }
            // Show Done Popup
            .sheet(isPresented: $showDonePopup) {
                DonePopupView(note: $note, attachment: $attachment, showImagePicker: $showImagePicker) {
                    saveOrderCompletion()
                }
            }
            // Show Image Picker
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $attachment)
            }
            .onAppear {
                orderManager.fetchOrders() // Fetch orders when the view appears
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // Edit button for toggling selection mode
    private var editButton: some View {
        Button(action: {
            isSelecting.toggle()
            if !isSelecting { // Reset selection and select all toggle when done
                selectedOrders.removeAll()
                selectAll = false
            }
        }) {
            Text(isSelecting ? "Done" : "Edit")
        }
    }

    // Select All/Deselect All button
    private var selectAllButton: some View {
        Button(action: {
            if selectAll {
                deselectAllOrders()
            } else {
                selectAllOrders()
            }
            selectAll.toggle() // Toggle between Select All and Deselect All
        }) {
            Text(selectAll ? "Deselect All" : "Select All")
        }
    }

    // Toggle selection for individual orders
    private func toggleSelection(for order: Order) {
        if selectedOrders.contains(order.id ?? "") {
            selectedOrders.remove(order.id ?? "")
        } else {
            selectedOrders.insert(order.id ?? "")
        }
    }
    
    // Select all orders
    private func selectAllOrders() {
        selectedOrders = Set(orderManager.orders.compactMap { $0.id }) // Use compactMap to unwrap optional IDs
    }

    
    // Deselect all orders
    private func deselectAllOrders() {
        selectedOrders.removeAll()
    }

    // Function to delete an order
    private func deleteOrder(at offsets: IndexSet) {
        offsets.forEach { index in
            let order = orderManager.orders[index]
            orderManager.deleteOrder(order)
        }
    }
    
    // Assign the selected orders to the selected users
    private func assignSelectedOrders(to users: [User]) {
        selectedOrders.forEach { orderId in
            if var order = orderManager.orders.first(where: { $0.id == orderId }) {
                order.phlebotomist = users.map { $0.id } // Assign multiple users to the order
                orderManager.updateOrder(order) // Update order in the database
            }
        }
        selectedOrders.removeAll() // Clear the selection
        isSelecting = false // Exit selection mode
    }

    // Helper function to generate a barcode image from a string
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        
        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
                return UIImage(ciImage: transformedImage)
            }
        }
        
        return nil
    }

    // Action: Print labels for selected orders
    private func printLabelsForSelectedOrders() {
        for orderId in selectedOrders {
            if let order = orderManager.orders.first(where: { $0.id == orderId }) {
                // Generate the barcode image from the barcode string (Assuming you have a helper for that)
                if let barcodeImage = generateBarcode(from: order.barcode) {
                    // Call the function to print the label with patient name and barcode image
                    printOrderLabel(patientName: order.patient_name, barcodeImage: barcodeImage)
                } else {
                    print("Failed to generate barcode for order \(order.id)")
                }
            }
        }
    }
    
    // Action: Mark selected orders
    private func markSelectedOrders() {
        if !selectedOrders.isEmpty {
            showStatusActionSheet = true
        }
    }
    
    // Action: Delete selected orders
    private func deleteSelectedOrders() {
        selectedOrders.forEach { orderId in
            if let order = orderManager.orders.first(where: { $0.id == orderId }) {
                orderManager.deleteOrder(order)
            }
        }
        selectedOrders.removeAll()
        isSelecting = false // Exit selection mode after deletion
    }
    
    // Update order status in Firebase
    private func updateOrderStatus(status: String) {
        selectedOrders.forEach { orderId in
            if var order = orderManager.orders.first(where: { $0.id == orderId }) {
                order.status = status
                orderManager.updateOrder(order)
            }
        }
    }

    // Save the order completion with picture, note, and attachment
    private func saveOrderCompletion() {
        selectedOrders.forEach { orderId in
            if var order = orderManager.orders.first(where: { $0.id == orderId }) {
                order.status = "Done"
                order.note = note

                // Upload both picture and attachment (if any)
                let dispatchGroup = DispatchGroup()

                // Handle attachment upload (file/document)
                if let attachmentImage = attachment {
                    dispatchGroup.enter()
                    uploadAttachment(image: attachmentImage, folder: "attachments") { url in
                        order.attachment = url?.absoluteString
                        dispatchGroup.leave()
                    }
                }

                // Handle picture upload (image)
                if let pictureImage = attachment {
                    dispatchGroup.enter()
                    uploadAttachment(image: pictureImage, folder: "pictures") { url in
                        order.picture = url?.absoluteString
                        dispatchGroup.leave()
                    }
                }

                // Once both uploads are done, update the order
                dispatchGroup.notify(queue: .main) {
                    orderManager.updateOrder(order)
                }
            }
        }

        selectedOrders.removeAll() // Clear selection after marking as Done
        isSelecting = false // Exit selection mode
    }

    // Upload attachment to Firebase Storage
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
}*/
