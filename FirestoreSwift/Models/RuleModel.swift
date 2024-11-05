//
//  RuleModel.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/27/24.
//

import Foundation

// Rule Model (Assuming this is the structure of the Rule)
struct Rule: Identifiable {
    var id: String
    var referring_physician_id: [String] // List of physician IDs this rule applies to
    var phlebotomistId: String // ID of the assigned phlebotomist
    var isActive: Bool // Indicates if the rule is active

    // Convert Firebase dictionary to Rule object
    static func fromDictionary(_ data: [String: Any], id: String) -> Rule? {
        guard let referringPhysicianId = data["referring_physician_id"] as? [String],
              let phlebotomistId = data["phlebotomistId"] as? String,
              let isActive = data["isActive"] as? Bool else {
            return nil
        }

        return Rule(id: id, referring_physician_id: referringPhysicianId, phlebotomistId: phlebotomistId, isActive: isActive)
    }

    // Convert Rule object to dictionary for saving to Firebase
    func toRuleDictionary() -> [String: Any] {
        return [
            "referring_physician_id": referring_physician_id,
            "phlebotomistId": phlebotomistId,
            "isActive": isActive
        ]
    }
}
