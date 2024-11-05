//
//  AddOrderView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/9/24.
//

import SwiftUI
import FirebaseDatabase
import MapKit
import FirebaseStorage

struct AddOrderView: View {
    @ObservedObject var orderManager: OrderManager
    @State var order: Order? // The order being edited, if any

    // Order form fields
        @State private var orderNumber = ""
        @State private var patientName = ""
        @State private var patientId = ""
        @State private var patientDob = Date()
        @State private var patientPhone = ""
        @State private var patientEmail = ""
        @State private var patientAddress = ""
        @State private var patientAddress2 = ""
        @State private var patientCity = ""
        @State private var patientState = ""
        @State private var patientZipcode = ""
        @State private var specimenType = ""
        @State private var specimenSource = "" // New field
        @State private var specimenComments = "" // New field
        @State private var patientGender = "Male" // Default gender selection
        @State private var patientEthnicity: String? = nil // Optional for placeholder
        @State private var testPriority = "Routine"
        @State private var testComments = "" // New field
        @State private var requirements: [String] = []
        @State private var insuranceCardPicture: UIImage? // New insurance card picture field
        @State private var testName: [String] = [] // Array for multiple test names
        @State private var testCode: [String] = [] // Array for multiple test codes
        @State private var orderDate = Date()
        @State private var billingCode = ""
        @State private var insuranceProvider = ""
        @State private var referringPhysicianName = ""
        @State private var referringPhysicianId = ""
        @State private var referringPhysicianNpi = ""
        @State private var referringPhysicianSignature: UIImage?
        @State private var physicianPhone = ""
        @State private var physicianEmail = ""
        @State private var physicianAddress = ""
        @State private var physicianAddress2 = ""
        @State private var physicianCity = ""
        @State private var physicianState = ""
        @State private var physicianZipcode = ""
        @State private var collectionDate: Date? = nil // Optional, starts as nil
        @State private var collectionTime: Date? = nil // Optional, starts as nil
        @State private var barcode = ""
        @State private var salesId = ""
        @State private var salesName = ""
        @State private var salesEmail = ""
        @State private var salesPhone = ""
        @State private var facilityId = ""
        @State private var facilityNpi = ""
        @State private var facilityName = ""

        @State private var collectionTubes: [CollectionTube] = [] // List of collection tubes
        @State private var tubeName = "" // Temporary state to store tube name input
        @State private var tubeQuantity = 1 // Temporary state to store tube quantity input
        
        @State private var phlebotomistIds: [String] = [] // Array to store assigned phlebotomists
        @State private var logisticIds: [String] = [] // Array to store logistic IDs
    
        @State private var newNote = "" // Field for adding a new note
        @State private var notes: [OrderNote] = [] // List of notes for the order

    
        @State private var pickupRequired: Bool = false
    
        @StateObject private var patientAddressVM = AddressAutocompleteViewModel()
        @StateObject private var physicianAddressVM = AddressAutocompleteViewModel()

        @State private var showSuccessAlert = false
        @State private var alertMessage = ""
        @State private var showDatePicker = false // Toggle to show date picker
        @State private var showTimePicker = false // Toggle to show time picker
        @State private var showImagePicker = false // This needs to be initialized
        @State private var insuranceCardPictures: [UIImage] = [] // This also needs to be initialized
    
    
        @State private var shouldClearCanvas = false // Controls if the signature canvas should be cleared
    
        @Environment(\.presentationMode) var presentationMode // To dismiss the view

        // Custom initializer
        /*init(orderManager: OrderManager, order: Order? = nil) {
            self.orderManager = orderManager
            self.order = order

            // Initialize @State properties that require initialization in init
            _showImagePicker = State(initialValue: false)
            _insuranceCardPictures = State(initialValue: [])
        }*/

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Order details")) {
                    TextField("Order Number", text: $orderNumber)
                    DatePicker("Order Date", selection: $orderDate, displayedComponents: .date)
                    
                    TextField("Barcode", text: $barcode)
                }
                
                Section(header: Text("Notes")) {
                                    TextEditor(text: $newNote)
                                        .frame(height: 100)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                                        .padding(.vertical, 5)
                                    
                                    Button(action: addNote) {
                                        Text("Add Note")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .disabled(newNote.isEmpty)

                                    if !notes.isEmpty {
                                        List {
                                            ForEach(notes) { note in
                                                VStack(alignment: .leading) {
                                                    Text(note.note)
                                                    Text(note.timestamp, style: .date)
                                                        .font(.footnote)
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.vertical, 5)
                                            }
                                        }
                                    }
                                }
                                




                Section(header: Text("Patient Details")) {
                    TextField("Patient Name", text: $patientName)
                    TextField("Patient ID", text: $patientId)
                    DatePicker("Patient DOB", selection: $patientDob, displayedComponents: .date)
                    
                    // Phone field with numeric keyboard and custom formatting
                    TextField("Patient Phone", text: $patientPhone)
                        .keyboardType(.numberPad)
                        .onChange(of: patientPhone) { oldValue, newValue in
                            // Remove any non-numeric characters from input
                            let cleanedPhoneNumber = newValue.filter { "0123456789".contains($0) }
                            
                            // Format to (XXX) XXX-XXXX
                            if cleanedPhoneNumber.count <= 10 {
                                if cleanedPhoneNumber.count <= 3 {
                                    patientPhone = "(\(cleanedPhoneNumber))"
                                } else if cleanedPhoneNumber.count <= 6 {
                                    patientPhone = "(\(cleanedPhoneNumber.prefix(3))) \(cleanedPhoneNumber.dropFirst(3))"
                                } else {
                                    patientPhone = "(\(cleanedPhoneNumber.prefix(3))) \(cleanedPhoneNumber.dropFirst(3).prefix(3))-\(cleanedPhoneNumber.dropFirst(6))"
                                }
                            } else {
                                patientPhone = String(cleanedPhoneNumber.prefix(10)) // Limit to 10 digits
                            }
                        }
                    
                    // Email field with email keyboard and no auto-capitalization
                    TextField("Patient Email", text: $patientEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress) // Improve autofill behavior
                    
                    
                    // Gender dropdown
                    Picker("Gender", selection: $patientGender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Ethnicity dropdown
                    Picker("Select Ethnicity", selection: $patientEthnicity) {
                        Text("Options").tag(String?.none)
                        Text("American Indian/Alaska Native").tag("American Indian/Alaska Native")
                        Text("Asian").tag("Asian")
                        Text("Black or African American").tag("Black or African American")
                        Text("Hispanic or Latino").tag("Hispanic or Latino")
                        Text("Native Hawaiian or Other Pacific Islander").tag("Native Hawaiian or Other Pacific Islander")
                        Text("White").tag("White")
                        Text("Other").tag("Other")
                    }
                    
                    // Address Autocomplete for patient
                    TextField("Patient Address", text: $patientAddressVM.queryFragment)
                        .onChange(of: patientAddressVM.queryFragment) { oldValue, newValue in
                            if newValue != patientAddress {
                                patientAddressVM.updateSearchResults(for: newValue)
                            }
                        }
                        .onAppear {
                            if let order = order {
                                patientAddressVM.queryFragment = order.patient_address
                            }
                        }

                    if patientAddressVM.isSearching && !patientAddressVM.queryFragment.isEmpty {
                        List(patientAddressVM.searchResults, id: \.self) { completion in
                            Button(action: {
                                patientAddressVM.selectCompletion(completion) { placemark in
                                    patientAddress = placemark?.name ?? ""
                                    patientCity = placemark?.locality ?? ""
                                    patientState = placemark?.administrativeArea ?? ""
                                    patientZipcode = placemark?.postalCode ?? ""
                                    patientAddressVM.queryFragment = placemark?.name ?? ""
                                    patientAddressVM.isSearching = false
                                }
                            }) {
                                VStack(alignment: .leading) {
                                    Text(completion.title).bold()
                                    Text(completion.subtitle).font(.subheadline).foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }

                    // Additional field for address line 2 (e.g., apartment, floor)
                    TextField("Address Line 2 (Apt, Floor, etc.)", text: $patientAddress2)

                    TextField("Patient City", text: $patientCity)
                    TextField("Patient State", text: $patientState)
                    TextField("Patient Zipcode", text: $patientZipcode)

                }

                Section(header: Text("Specimen Details")) {
                    TextField("Specimen Type", text: $specimenType)
                    TextField("Specimen Source", text: $specimenSource) // New field
                    TextField("Specimen Comments", text: $specimenComments) // New field
                }

                Section(header: Text("Test Details")) {
                    TextField("Test Name", text: Binding(
                        get: { testName.joined(separator: ", ") },
                        set: { testName = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                    TextField("Test Code", text: Binding(
                        get: { testCode.joined(separator: ", ") },
                        set: { testCode = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                    
                    
                    // Test priority dropdown
                    Picker("Test Priority", selection: $testPriority) {
                        Text("Routine").tag("Routine")
                        Text("STAT").tag("STAT")
                    }
                    
                    TextField("Test Comments", text: $testComments) // New field
                    TextField("Test Requirements", text: Binding(
                        get: { requirements.joined(separator: ", ") },
                        set: { requirements = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                }

                Section(header: Text("Billing & Insurance")) {
                    TextField("Billing Code", text: $billingCode)
                    TextField("Insurance Provider", text: $insuranceProvider)

                    // Insurance card picture upload (similar to picture field)
                    VStack(alignment: .leading) {
                        Text("Insurance Card Picture")
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(insuranceCardPictures, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                        .padding(.trailing, 5)
                                }
                            }
                        }
                        Button(action: {
                            showImagePicker.toggle() // Trigger ImagePicker
                        }) {
                            Text("Add Insurance Card")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(images: $insuranceCardPictures)
                        }
                    }
                }
                
                Section(header: Text("Facility Details")) {
                    TextField("Facility ID", text: $facilityId)
                    TextField("Facility NPI", text: $facilityNpi)
                    TextField("Facility Name", text: $facilityName)
                }

                Section(header: Text("Physician Details")) {
                    TextField("Referring Physician Name", text: $referringPhysicianName)
                    TextField("Referring Physician ID", text: $referringPhysicianId)
                    TextField("Referring Physician NPI", text: $referringPhysicianNpi)
                    TextField("Physician Phone", text: $physicianPhone)
                            .keyboardType(.numberPad)
                            .onChange(of: physicianPhone) { oldValue, newValue in
                                // Remove any non-numeric characters from input
                                let cleanedPhoneNumber = newValue.filter { "0123456789".contains($0) }
                                
                                // Format to (XXX) XXX-XXXX
                                if cleanedPhoneNumber.count <= 10 {
                                    if cleanedPhoneNumber.count <= 3 {
                                        physicianPhone = "(\(cleanedPhoneNumber))"
                                    } else if cleanedPhoneNumber.count <= 6 {
                                        physicianPhone = "(\(cleanedPhoneNumber.prefix(3))) \(cleanedPhoneNumber.dropFirst(3))"
                                    } else {
                                        physicianPhone = "(\(cleanedPhoneNumber.prefix(3))) \(cleanedPhoneNumber.dropFirst(3).prefix(3))-\(cleanedPhoneNumber.dropFirst(6))"
                                    }
                                } else {
                                    patientPhone = String(cleanedPhoneNumber.prefix(10)) // Limit to 10 digits
                                }
                            }
                        
                        // Email field with email keyboard and no auto-capitalization
                    TextField("Physician Email", text: $physicianEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                    
                    
                    // Signature View with clear logic
                    SignatureView(shouldClearCanvas: $shouldClearCanvas) { image in
                        referringPhysicianSignature = image
                        print("Signature saved in AddOrderView.")
                    }
                    
                    TextField("Physician Address", text: $physicianAddressVM.queryFragment)
                        .onChange(of: physicianAddressVM.queryFragment) { oldValue, newValue in
                            if newValue != physicianAddress {
                                physicianAddressVM.updateSearchResults(for: newValue)
                            }
                        }
                        .onAppear {
                            if let order = order {
                                physicianAddressVM.queryFragment = order.physician_address
                            }
                        }
                    
                    if physicianAddressVM.isSearching && !physicianAddressVM.queryFragment.isEmpty {
                        List(physicianAddressVM.searchResults, id: \.self) { completion in
                            Button(action: {
                                physicianAddressVM.selectCompletion(completion) { placemark in
                                    physicianAddress = placemark?.name ?? ""
                                    physicianCity = placemark?.locality ?? ""
                                    physicianState = placemark?.administrativeArea ?? ""
                                    physicianZipcode = placemark?.postalCode ?? ""
                                    physicianAddressVM.queryFragment = placemark?.name ?? ""
                                    physicianAddressVM.isSearching = false
                                }
                            }) {
                                VStack(alignment: .leading) {
                                    Text(completion.title).bold()
                                    Text(completion.subtitle).font(.subheadline).foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    
                    TextField("Address Line 2 (Apt, Floor, etc.)", text: $physicianAddress2)
                    
                    TextField("Physician City", text: $physicianCity)
                    TextField("Physician State", text: $physicianState)
                    TextField("Physician Zipcode", text: $physicianZipcode)
                }

                /*Section(header: Text("Collection Details")) {
                    // DatePicker only shows if the date is not nil
                    if let collectionDate = collectionDate {
                        DatePicker("Collection Date", selection: Binding(
                            get: { collectionDate },
                            set: { self.collectionDate = $0 }
                        ), displayedComponents: .date)
                    } else {
                        Button(action: {
                            showDatePicker.toggle()
                        }) {
                            Text("Select Collection Date")
                        }
                        .sheet(isPresented: $showDatePicker) {
                            DatePicker("Select Date", selection: Binding(
                                get: { collectionDate ?? Date() }, // Allow user to pick any date
                                set: { collectionDate = $0 }
                            ), displayedComponents: .date)
                            .onDisappear {
                                showDatePicker = false
                            }
                        }
                    }

                    // TimePicker only shows if the time is not nil
                    if let collectionTime = collectionTime {
                        DatePicker("Collection Time", selection: Binding(
                            get: { collectionTime },
                            set: { self.collectionTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                    } else {
                        Button(action: {
                            showTimePicker.toggle()
                        }) {
                            Text("Select Collection Time")
                        }
                        .sheet(isPresented: $showTimePicker) {
                            DatePicker("Select Time", selection: Binding(
                                get: { collectionTime ?? Date() }, // Allow user to pick any time
                                set: { collectionTime = $0 }
                            ), displayedComponents: .hourAndMinute)
                            .onDisappear {
                                showTimePicker = false
                            }
                        }
                    }

                    
                }*/
                
                /*Section(header: Text("Collection Tubes")) {
                    HStack {
                        TextField("Tube Name", text: $tubeName)
                        Stepper(value: $tubeQuantity, in: 1...100) {
                            Text("Quantity: \(tubeQuantity)")
                        }
                    }

                    Button(action: addCollectionTube) {
                        Text("Add Tube")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    // List of added collection tubes
                    List {
                        ForEach(collectionTubes) { tube in
                            HStack {
                                Text(tube.name)
                                Spacer()
                                Text("x\(tube.quantity)")
                            }
                        }
                        .onDelete(perform: deleteTube)
                    }
                }*/
                
                Section(header: Text("Sales Representative")) {
                    TextField("Sales ID", text: $salesId)
                    TextField("Sales Name", text: $salesName)
                    TextField("Sales Email", text: $salesEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                    TextField("Sales Phone", text: $salesPhone)
                            .keyboardType(.numberPad)
                            .onChange(of: salesPhone) { oldValue, newValue in
                                // Remove any non-numeric characters from input
                                let cleanedPhoneNumber = newValue.filter { "0123456789".contains($0) }
                                
                                // Format to (XXX) XXX-XXXX
                                if cleanedPhoneNumber.count <= 10 {
                                    if cleanedPhoneNumber.count <= 3 {
                                        salesPhone = "(\(cleanedPhoneNumber))"
                                    } else if cleanedPhoneNumber.count <= 6 {
                                        salesPhone = "(\(cleanedPhoneNumber.prefix(3))) \(cleanedPhoneNumber.dropFirst(3))"
                                    } else {
                                        salesPhone = "(\(cleanedPhoneNumber.prefix(3))) \(cleanedPhoneNumber.dropFirst(3).prefix(3))-\(cleanedPhoneNumber.dropFirst(6))"
                                    }
                                } else {
                                    salesPhone = String(cleanedPhoneNumber.prefix(10)) // Limit to 10 digits
                                }
                            }
                    
                }
                
                Section {
                    Button(action: {
                        checkAndApplyRulesThenSaveOrder()
                    }) {
                        Text(order == nil ? "Add Order" : "Update Order")
                    }
                }
            }
            .navigationTitle(order == nil ? "Add Order" : "Edit Order")
            .onAppear {
                if let order = order {
                    loadOrderDetails(order) // Load order data into fields
                }
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss() // Dismiss the view when "OK" is pressed
                    }
                )
            }
        }
    }
    
    
    
    // Load existing order details for editing
    private func loadOrderDetails(_ order: Order) {
        orderNumber = order.order_number
        notes = order.note ?? []
        patientName = order.patient_name
        patientId = order.patient_id
        patientDob = order.patient_dob
        patientPhone = order.patient_phone ?? ""
        patientEmail = order.patient_email ?? ""
        patientAddress = order.patient_address
        patientAddress2 = order.patient_address2 ?? ""
        patientCity = order.patient_city
        patientState = order.patient_state
        patientZipcode = order.patient_zipcode
        specimenType = order.specimen_type ?? ""
        specimenSource = order.specimen_source ?? "" // Load specimen source
        specimenComments = order.specimen_comments ?? "" // Load specimen comments
        testName = order.test_name
        testCode = order.test_code ?? []
        orderDate = order.order_date
        billingCode = order.billing_code
        insuranceProvider = order.insurance_provider
        referringPhysicianName = order.referring_physician_name
        referringPhysicianId = order.referring_physician_id ?? ""
        referringPhysicianNpi = order.referring_physician_npi ?? ""
        physicianPhone = order.physician_phone ?? ""
        physicianEmail = order.physician_email ?? ""
        physicianAddress = order.physician_address
        physicianAddress2 = order.physician_address2 ?? ""
        physicianCity = order.physician_city
        physicianState = order.physician_state
        physicianZipcode = order.physician_zipcode
        salesId = order.sales_id ?? ""
        salesName = order.sales_name ?? ""
        salesEmail = order.sales_email ?? ""
        salesPhone = order.sales_phone ?? ""
        facilityId = order.facility_id ?? ""
        facilityNpi = order.facility_npi ?? ""
        facilityName = order.facility_name ?? ""
        collectionDate = order.collection_date ?? Date()
        collectionTime = order.collection_time ?? Date()
        barcode = order.barcode
        phlebotomistIds = order.phlebotomist
        logisticIds = order.logistic
        patientGender = order.patient_gender ?? "Male" // Load patient gender
        patientEthnicity = order.patient_ethnicity ?? "White" // Load patient ethnicity
        testPriority = order.test_priority ?? "Routine" // Load test priority
        testComments = order.test_comments ?? "" // Load test comments
        requirements = order.requirements ?? []
        pickupRequired = order.pickup_required ?? false
        // Handle insuranceCardPicture if applicable
    }
    
    // Check rules before saving order
    private func checkAndApplyRulesThenSaveOrder() {
        let ref = Database.database().reference().child("rules")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            var matchingRule: Rule?

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let ruleData = snapshot.value as? [String: Any],
                   let rule = Rule.fromDictionary(ruleData, id: snapshot.key),
                   rule.referring_physician_id.contains(self.referringPhysicianId), rule.isActive {
                    matchingRule = rule
                    break
                }
            }

            if let rule = matchingRule {
                // If rule is found, assign phlebotomist
                self.phlebotomistIds = [rule.phlebotomistId]
            } else {
                // No rule found, phlebotomist remains empty
                self.phlebotomistIds = []
            }

            self.saveOrder()
        }
    }
    
    private func addNote() {
            let newOrderNote = OrderNote(note: newNote, timestamp: Date())
            notes.append(newOrderNote) // Add the note to the notes array
            newNote = "" // Clear the text area for adding new notes
        }
    
    // Add a new collection tube to the list
    func addCollectionTube() {
        let newTube = CollectionTube(name: tubeName, quantity: tubeQuantity)
        collectionTubes.append(newTube)
        tubeName = "" // Clear the input field
        tubeQuantity = 1 // Reset quantity
    }

    // Delete a tube from the list
    func deleteTube(at offsets: IndexSet) {
        collectionTubes.remove(atOffsets: offsets)
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert UIImage to data")
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("insurance_card_pictures/\(UUID().uuidString).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                completion(url)
            }
        }
    }

    // Function to upload all insurance card pictures
    private func uploadInsuranceCardPictures(completion: @escaping ([String]) -> Void) {
        var uploadedUrls: [String] = []
        let dispatchGroup = DispatchGroup()

        for picture in insuranceCardPictures {
            dispatchGroup.enter()
            uploadImage(picture) { url in
                if let url = url {
                    uploadedUrls.append(url.absoluteString)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(uploadedUrls)
        }
    }
    
    // Function to upload the referring physician signature
    private func uploadReferringPhysicianSignature(_ signature: UIImage?, completion: @escaping (String?) -> Void) {
        guard let signature = signature else {
            print("Signature is nil, skipping upload.")
            // No signature provided, return nil
            completion(nil)
            return
        }

        guard let imageData = signature.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert signature UIImage to data")
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("referring_physician_signatures/\(UUID().uuidString).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading signature: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL for signature: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                print("Signature URL uploaded: \(url?.absoluteString ?? "No URL")")
                completion(url?.absoluteString)
            }
        }
    }
    
    // Save or update the order with image upload logic
    private func saveOrder() {
        if let order = order {
            // Update existing order with uploaded images
            uploadInsuranceCardPictures { urls in
                // Upload signature
                self.uploadReferringPhysicianSignature(self.referringPhysicianSignature) { signatureURL in
                    var updatedOrder = order
                    updatedOrder.order_number = orderNumber
                    updatedOrder.note = notes
                    updatedOrder.patient_name = patientName
                    updatedOrder.patient_id = patientId
                    updatedOrder.patient_dob = patientDob
                    updatedOrder.patient_phone = patientPhone
                    updatedOrder.patient_email = patientEmail
                    updatedOrder.patient_address2 = patientAddress2
                    updatedOrder.specimen_type = specimenType
                    updatedOrder.specimen_source = specimenSource
                    updatedOrder.specimen_comments = specimenComments
                    updatedOrder.test_name = testName
                    updatedOrder.test_code = testCode
                    updatedOrder.order_date = orderDate
                    updatedOrder.billing_code = billingCode
                    updatedOrder.insurance_provider = insuranceProvider
                    updatedOrder.insurance_card_picture = urls
                    updatedOrder.referring_physician_name = referringPhysicianName
                    updatedOrder.referring_physician_id = referringPhysicianId
                    updatedOrder.referring_physician_npi = referringPhysicianNpi
                    updatedOrder.physician_phone = physicianPhone
                    updatedOrder.physician_email = physicianEmail
                    updatedOrder.physician_address = physicianAddress
                    updatedOrder.physician_address2 = physicianAddress2
                    updatedOrder.physician_city = physicianCity
                    updatedOrder.physician_state = physicianState
                    updatedOrder.physician_zipcode = physicianZipcode
                    updatedOrder.facility_id = facilityId
                    updatedOrder.facility_name = facilityName
                    updatedOrder.facility_npi = facilityNpi
                    updatedOrder.patient_gender = patientGender
                    updatedOrder.patient_ethnicity = patientEthnicity
                    updatedOrder.test_priority = testPriority
                    updatedOrder.test_comments = testComments
                    updatedOrder.requirements = requirements
                    updatedOrder.collection_date = collectionDate
                    updatedOrder.collection_time = collectionTime
                    updatedOrder.barcode = barcode
                    updatedOrder.phlebotomist = phlebotomistIds
                    updatedOrder.logistic = logisticIds
                    updatedOrder.collectionTubes = collectionTubes
                    updatedOrder.pickup_required = false
                    updatedOrder.referring_physician_signature = signatureURL // Set the URL for the signature
                    if let signatureURL = signatureURL {
                        updatedOrder.referring_physician_signature = signatureURL
                        print("Saving signature URL: \(signatureURL)")
                    } else {
                        print("Signature URL is nil, not saving the signature")
                    }
                    // Update order in the database
                    orderManager.updateOrder(updatedOrder)

                    alertMessage = "Order updated successfully!"
                    showSuccessAlert = true
                }
            }
        } else {
            // Add a new order
            uploadInsuranceCardPictures { urls in
                self.uploadReferringPhysicianSignature(self.referringPhysicianSignature) { signatureURL in
                    let newOrder = Order(
                        id: UUID().uuidString,
                        order_number: orderNumber,
                        patient_id: patientId,
                        patient_dob: patientDob,
                        patient_phone: patientPhone,
                        patient_email: patientEmail,
                        specimen_type: specimenType,
                        specimen_source: specimenSource,
                        specimen_comments: specimenComments,
                        test_name: testName,
                        test_code: testCode,
                        order_date: orderDate,
                        billing_code: billingCode,
                        insurance_provider: insuranceProvider,
                        insurance_card_picture: urls,
                        referring_physician_name: referringPhysicianName,
                        referring_physician_id: referringPhysicianId,
                        referring_physician_npi: referringPhysicianNpi,
                        physician_phone: physicianPhone,
                        physician_email: physicianEmail,
                        physician_address: physicianAddress,
                        physician_address2: physicianAddress2,
                        physician_city: physicianCity,
                        physician_state: physicianState,
                        physician_zipcode: physicianZipcode,
                        patient_name: patientName,
                        patient_address: patientAddress,
                        patient_address2: patientAddress2,
                        patient_city: patientCity,
                        patient_state: patientState,
                        patient_zipcode: patientZipcode,
                        patient_gender: patientGender,
                        patient_ethnicity: patientEthnicity,
                        collection_date: collectionDate,
                        collection_time: collectionTime,
                        barcode: barcode,
                        phlebotomist: phlebotomistIds,
                        logistic: logisticIds,
                        status: [],
                        note: notes,
                        pickup_required: false,
                        attachment: nil,
                        picture: nil,
                        test_priority: testPriority,
                        test_comments: testComments,
                        requirements: requirements,
                        sales_id: salesId,
                        sales_name: salesName,
                        sales_email: salesEmail,
                        sales_phone: salesPhone,
                        facility_id: facilityId,
                        facility_npi: facilityNpi,
                        facility_name: facilityName,
                        referring_physician_signature: signatureURL,
                        collectionTubes: collectionTubes
                    )

                    // Add new order to the database
                    orderManager.addOrder(newOrder)

                    alertMessage = "New order added successfully!"
                    showSuccessAlert = true
                }
            }
        }
    }
}



