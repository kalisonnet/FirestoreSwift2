//
//  UserManager.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/12/24.
//

import SwiftUI
import FirebaseDatabase

class UserManager: ObservableObject {
    @Published var users: [User] = []
    
    private let ref = Database.database().reference().child("users")

    init() {
        fetchUsers()
    }
    
    // Fetch all users from the Firebase Realtime Database
    func fetchUsers() {
        ref.observe(.value) { snapshot in
            var fetchedUsers: [User] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let userData = snapshot.value as? [String: Any] {
                    let user = User(id: snapshot.key, data: userData)
                    fetchedUsers.append(user)
                }
            }
            self.users = fetchedUsers
        }
    }
    
    // Fetch role for a specific user
    func fetchUserRole(for userId: String, completion: @escaping (String) -> Void) {
        ref.child(userId).observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any],
               let role = userData["role"] as? String {
                completion(role)
            } else {
                completion("") // Return empty string if no role found
            }
        }
    }
    
    // Filter phlebotomists from the fetched users
    func phlebotomists() -> [User] {
        return users.filter { $0.role == "PHLEBOTOMIST" }
    }
}
