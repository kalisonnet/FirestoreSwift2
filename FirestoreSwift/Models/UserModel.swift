//
//  UserModel.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/10/24.
//

import Foundation
import SwiftUI

struct User: Identifiable, Hashable {
    var id: String
    var username: String
    var role: String
    var email: String
    var phoneNumber: String
    var avatarUrl: String
    var isActive: Bool
    
    // Initialize the model from Firebase data
    init(id: String, data: [String: Any]) {
        self.id = id
        self.username = data["username"] as? String ?? ""
        self.role = data["role"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.phoneNumber = data["phoneNumber"] as? String ?? ""
        self.avatarUrl = data["avatarUrl"] as? String ?? ""
        self.isActive = data["isActive"] as? Bool ?? true
    }
}
