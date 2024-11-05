//
//  OrderModel.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/9/24.
//

import Foundation

struct Order: Identifiable, Codable, Equatable, Hashable {
    var id: String? // Firebase document ID
    var order_number: String
    var patient_id: String
    var patient_ssn: String?
    var patient_dob: Date
    var patient_phone: String?
    var patient_email: String?
    var specimen_type: String?
    var specimen_source: String? // New field for specimen source
    var specimen_comments: String? // New field for specimen comments
    var test_name: [String]
    var test_code: [String]?
    var order_date: Date
    var billing_code: String
    var insurance_provider: String
    var insurance_card_picture: [String]? // New field for insurance card picture (same as picture field)
    var referring_physician_name: String
    var referring_physician_id: String?
    var referring_physician_npi: String?
    var physician_phone: String?
    var physician_email: String?
    var physician_address: String
    var physician_address2: String?
    var physician_city: String
    var physician_state: String
    var physician_zipcode: String
    var patient_name: String
    var patient_address: String
    var patient_address2: String?
    var patient_city: String
    var patient_state: String
    var patient_zipcode: String
    var patient_gender: String? // New field for patient gender
    var patient_ethnicity: String? // New field for patient ethnicity
    var collection_date: Date?
    var collection_time: Date?
    var barcode: String
    var phlebotomist: [String]
    var logistic: [String]
    var status: [OrderStatus] // Use OrderStatus struct
    var note: [OrderNote]? // Updated note structure to have the same format as status
    var pickup_required: Bool? // Non-required field for pickup
    var attachment: String?
    var picture: [String]?
    var test_priority: String? // New field for test priority
    var test_comments: String? // New field for test comments
    var requirements: [String]?
    var sales_id: String?
    var sales_name: String?
    var sales_email: String?
    var sales_phone: String?
    var facility_id: String?
    var facility_npi: String?
    var facility_name: String?

    // New field for storing the signature
    var referring_physician_signature: String? // Base64-encoded signature or URL

    // New field for tracking collection tubes
    var collectionTubes: [CollectionTube] = [] // Track collection tubes and quantities used
    var distance: Double? // New field to store distance in miles
    
    // Convert Order to dictionary for Firebase
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "order_number": order_number,
            "patient_id": patient_id,
            "patient_ssn": patient_ssn ?? "",
            "patient_dob": patient_dob.timeIntervalSince1970,
            "patient_phone": patient_phone ?? "",
            "patient_email": patient_email ?? "",
            "specimen_type": specimen_type ?? "",
            "specimen_source": specimen_source ?? "",
            "specimen_comments": specimen_comments ?? "",
            "test_name": test_name,
            "test_code": test_code ?? [],
            "order_date": order_date.timeIntervalSince1970,
            "billing_code": billing_code,
            "insurance_provider": insurance_provider,
            "insurance_card_picture": insurance_card_picture ?? [],
            "referring_physician_name": referring_physician_name,
            "referring_physician_id": referring_physician_id ?? "",
            "referring_physician_npi": referring_physician_npi ?? "",
            "physician_phone": physician_phone ?? "",
            "physician_email": physician_email ?? "",
            "physician_address": physician_address,
            "physician_address2": physician_address2 ?? "",
            "physician_city": physician_city,
            "physician_state": physician_state,
            "physician_zipcode": physician_zipcode,
            "patient_name": patient_name,
            "patient_address": patient_address,
            "patient_address2": patient_address2 ?? "",
            "patient_city": patient_city,
            "patient_state": patient_state,
            "patient_zipcode": patient_zipcode,
            "patient_gender": patient_gender ?? "",
            "patient_ethnicity": patient_ethnicity ?? "",
            "collection_date": collection_date?.timeIntervalSince1970 ?? 0,
            "collection_time": collection_time?.timeIntervalSince1970 ?? 0,
            "barcode": barcode,
            "phlebotomist": phlebotomist,
            "logistic": logistic,
            "attachment": attachment ?? "",
            "picture": picture ?? [],
            "test_priority": test_priority ?? "",
            "test_comments": test_comments ?? "",
            "requirements": requirements ?? [],
            "sales_id": sales_id ?? "",
            "sales_name": sales_name ?? "",
            "sales_email": sales_email ?? "",
            "sales_phone": sales_phone ?? "",
            "facility_id": facility_id ?? "",
            "facility_npi": facility_npi ?? "",
            "facility_name": facility_name ?? "",
            "referring_physician_signature": referring_physician_signature ?? "",
            "pickup_required": pickup_required ?? false, // Include pickup required field
            "distance": distance ?? 0.0, // Include distance if available
            "collectionTubes": collectionTubes.map { $0.toDictionary() }
        ]

        // Convert status array to dictionary
        let statusArray = status.map { $0.toDictionary() }
        dict["status"] = statusArray

        // Convert note array to dictionary if available
        if let note = note {
            dict["note"] = note.map { $0.toDictionary() }
        }

        // Include id if available
        if let id = id {
            dict["id"] = id
        }

        return dict
    }

    // Create Order from Firebase dictionary
    static func fromDictionary(_ data: [String: Any], id: String) -> Order? {
        // Core required fields
        guard let order_number = data["order_number"] as? String,
              let patient_id = data["patient_id"] as? String,
              let patient_dob = data["patient_dob"] as? TimeInterval,
              let specimen_type = data["specimen_type"] as? String,
              let test_name = data["test_name"] as? [String],
              let order_date = data["order_date"] as? TimeInterval,
              let billing_code = data["billing_code"] as? String,
              let insurance_provider = data["insurance_provider"] as? String,
              let referring_physician_name = data["referring_physician_name"] as? String,
              let physician_address = data["physician_address"] as? String,
              let physician_city = data["physician_city"] as? String,
              let physician_state = data["physician_state"] as? String,
              let physician_zipcode = data["physician_zipcode"] as? String,
              let patient_name = data["patient_name"] as? String,
              let patient_address = data["patient_address"] as? String,
              let patient_city = data["patient_city"] as? String,
              let patient_state = data["patient_state"] as? String,
              let patient_zipcode = data["patient_zipcode"] as? String,
              let barcode = data["barcode"] as? String else {
            return nil
        }
        
        // Optional fields
        let patient_phone = data["patient_phone"] as? String
        let patient_ssn = data["patient_ssn"] as? String
        let patient_email = data["patient_email"] as? String
        let patient_address2 = data["patient_address2"] as? String
        let test_code = data["test_code"] as? [String]
        let specimen_source = data["specimen_source"] as? String
        let specimen_comments = data["specimen_comments"] as? String
        let patient_gender = data["patient_gender"] as? String
        let patient_ethnicity = data["patient_ethnicity"] as? String
        let referring_physician_id = data["referring_physician_id"] as? String
        let referring_physician_npi = data["referring_physician_npi"] as? String
        let physician_phone = data["physician_phone"] as? String
        let physician_email = data["physician_email"] as? String
        let physician_address2 = data["physician_address2"] as? String
        let insurance_card_picture = data["insurance_card_picture"] as? [String]
        let collection_date = (data["collection_date"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
        let collection_time = (data["collection_time"] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
        let phlebotomist = data["phlebotomist"] as? [String] ?? []
        let logistic = data["logistic"] as? [String] ?? []
        let attachment = data["attachment"] as? String
        let picture = data["picture"] as? [String]
        let test_priority = data["test_priority"] as? String
        let test_comments = data["test_comments"] as? String
        let requirements = data["requirements"] as? [String]
        let sales_id = data["sales_id"] as? String
        let sales_name = data["sales_name"] as? String
        let sales_email = data["sales_email"] as? String
        let sales_phone = data["sales_phone"] as? String
        let facility_id = data["facility_id"] as? String
        let facility_npi = data["facility_npi"] as? String
        let facility_name = data["facility_name"] as? String
        let referring_physician_signature = data["referring_physician_signature"] as? String
        let pickup_required = data["pickup_required"] as? Bool ?? false
        let collectionTubes = (data["collectionTubes"] as? [[String: Any]])?.compactMap { CollectionTube.fromDictionary($0) } ?? []
        let distance = data["distance"] as? Double ?? 0.0
        
        // Convert status array from dictionary
        var statusArray: [OrderStatus] = []
        if let statusDictArray = data["status"] as? [[String: Any]] {
            statusArray = statusDictArray.compactMap { OrderStatus.fromDictionary($0) }
        }

        // Convert note array from dictionary
        var noteArray: [OrderNote] = []
        if let noteDictArray = data["note"] as? [[String: Any]] {
            noteArray = noteDictArray.compactMap { OrderNote.fromDictionary($0) }
        }

        return Order(
            id: id,
            order_number: order_number,
            patient_id: patient_id,
            patient_ssn: patient_ssn,
            patient_dob: Date(timeIntervalSince1970: patient_dob),
            patient_phone: patient_phone,
            patient_email: patient_email,
            specimen_type: specimen_type,
            specimen_source: specimen_source,
            specimen_comments: specimen_comments,
            test_name: test_name,
            test_code: test_code,
            order_date: Date(timeIntervalSince1970: order_date),
            billing_code: billing_code,
            insurance_provider: insurance_provider,
            insurance_card_picture: insurance_card_picture,
            referring_physician_name: referring_physician_name,
            referring_physician_id: referring_physician_id,
            referring_physician_npi: referring_physician_npi,
            physician_phone: physician_phone,
            physician_email: physician_email,
            physician_address: physician_address,
            physician_address2: physician_address2,
            physician_city: physician_city,
            physician_state: physician_state,
            physician_zipcode: physician_zipcode,
            patient_name: patient_name,
            patient_address: patient_address,
            patient_address2: patient_address2,
            patient_city: patient_city,
            patient_state: patient_state,
            patient_zipcode: patient_zipcode,
            patient_gender: patient_gender,
            patient_ethnicity: patient_ethnicity,
            collection_date: collection_date,
            collection_time: collection_time,
            barcode: barcode,
            phlebotomist: phlebotomist,
            logistic: logistic,
            status: statusArray,
            note: noteArray,
            pickup_required: pickup_required,
            attachment: attachment,
            picture: picture,
            test_priority: test_priority,
            test_comments: test_comments,
            requirements: requirements,
            sales_id: sales_id,
            sales_name: sales_name,
            sales_email: sales_email,
            sales_phone: sales_phone,
            facility_id: facility_id,
            facility_npi: facility_npi,
            facility_name: facility_name,
            referring_physician_signature: referring_physician_signature,
            collectionTubes: collectionTubes,
            distance: distance // Initialize with the distance value
        )
    }
}

// Struct to store the status of an order
struct OrderStatus: Codable, Equatable, Hashable {
    var status: String
    var timestamp: Date
    
    // Helper method to convert to dictionary if needed
    func toDictionary() -> [String: Any] {
        return [
            "status": status,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }

    // Helper method to create OrderStatus from dictionary
    static func fromDictionary(_ dict: [String: Any]) -> OrderStatus? {
        guard let status = dict["status"] as? String,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        return OrderStatus(status: status, timestamp: Date(timeIntervalSince1970: timestamp))
    }
}

// Struct to store a note for an order, similar to status
struct OrderNote: Identifiable, Codable, Hashable {
    var id = UUID() // Add an ID to conform to Identifiable
    var note: String
    var timestamp: Date
    
    func toDictionary() -> [String: Any] {
        return [
            "note": note,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> OrderNote? {
        guard let note = dict["note"] as? String,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        return OrderNote(note: note, timestamp: Date(timeIntervalSince1970: timestamp))
    }
}

// Struct to store collection tube details
struct CollectionTube: Identifiable, Codable, Equatable, Hashable {
    var id = UUID().uuidString
    var name: String
    var quantity: Int

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "quantity": quantity
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> CollectionTube? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let quantity = dict["quantity"] as? Int else {
            return nil
        }
        return CollectionTube(id: id, name: name, quantity: quantity)
    }
}
