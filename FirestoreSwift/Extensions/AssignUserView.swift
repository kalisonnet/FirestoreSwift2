//
//  AssignUssrView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/12/24.
//

import SwiftUI

struct AssignUserView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userManager: UserManager
    @State private var selectedUsers = Set<User>() // Track selected users
    var assignOrder: ([User]) -> Void
    
    var body: some View {
        NavigationView {
            List(phlebotomistUsers, id: \.id) { user in
                HStack {
                    AsyncImage(url: URL(string: user.avatarUrl)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .clipped()
                    } placeholder: {
                        Circle().frame(width: 40, height: 40).foregroundColor(.gray)
                    }
                    Text(user.username)
                        .font(.headline)
                    Spacer()
                    // Show checkmark if the user is selected
                    if selectedUsers.contains(user) {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSelection(for: user) // Toggle user selection
                }
            }
            .navigationTitle("Phlebotomist Users")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Assign") {
                    assignOrder(Array(selectedUsers)) // Pass the selected users
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var phlebotomistUsers: [User] {
        return userManager.users.filter { $0.role == "PHLEBOTOMIST" }
    }

    private func toggleSelection(for user: User) {
        if selectedUsers.contains(user) {
            selectedUsers.remove(user)
        } else {
            selectedUsers.insert(user)
        }
    }
}

