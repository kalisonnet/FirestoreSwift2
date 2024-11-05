//
//  UserDetailView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/26/24.
//

import SwiftUI
import FirebaseDatabase

struct UserDetailsView: View {
    @State var user: User
    @State private var username: String
    @State private var phoneNumber: String
    @State private var role: String
    @State private var isActive: Bool
    @Environment(\.dismiss) var dismiss
    
    let roles = ["PHLEBOTOMY MANAGER", "LOGISTIC MANAGER", "SALES MANAGER", "PHLEBOTOMIST", "LOGISTIC", "SALES"]
    
    init(user: User) {
        self._user = State(initialValue: user)
        self._username = State(initialValue: user.username)
        self._phoneNumber = State(initialValue: user.phoneNumber)
        self._role = State(initialValue: user.role)
        self._isActive = State(initialValue: user.isActive)
    }

    var body: some View {
        Form {
            Section(header: Text("User Info")) {
                TextField("Username", text: $username)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
            }
            
            Section(header: Text("User Role")) {
                // Role Picker
                Picker("Role", selection: $role) {
                    ForEach(roles, id: \.self) {
                        Text($0)
                    }
                }
                .padding()
                //.background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            
            
            Section(header: Text("Email")) {
                Text(user.email)
                    .foregroundColor(.gray)
            }
            
            // Toggle for Active/Inactive status
            Section(header: Text("Account Status")) {
                Toggle(isOn: $isActive) {
                    Text(isActive ? "Active" : "Inactive")
                        .foregroundColor(isActive ? .green : .red)
                }
            }

            // Save Button
            Section {
                Button(action: saveChanges) {
                    Text("Save Changes")
                }
            }
        }
        .navigationTitle(user.username)
    }
    
    // Save changes to Firebase
    private func saveChanges() {
        let ref = Database.database().reference().child("users").child(user.id)
        let updatedData: [String: Any] = [
            "username": username,
            "phoneNumber": phoneNumber,
            "role": role,
            "isActive": isActive
        ]
        
        ref.updateChildValues(updatedData) { error, _ in
            if let error = error {
                print("Failed to update user: \(error.localizedDescription)")
            } else {
                print("User updated successfully.")
            }
        }
        
        dismiss() // Dismiss the view after saving
    }
}

