//
//  UsersInfoView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/26/24.
//

import SwiftUI
import FirebaseDatabase

struct UsersRoleView: View {
    @State private var phlebotomists: [User] = [] // List of Phlebotomists
    @State private var isLoading = true
    @State private var searchText = ""

    // Filtered users based on search text
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return phlebotomists
        } else {
            return phlebotomists.filter {
                $0.username.lowercased().contains(searchText.lowercased()) ||
                $0.phoneNumber.contains(searchText) || // Matching phone number
                $0.email.lowercased().contains(searchText.lowercased()) // Matching email
            }
        }
    }

    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView("Loading Users...")
            } else if phlebotomists.isEmpty {
                Text("No Phlebotomists found.")
                    .foregroundColor(.gray)
            } else {
                List(filteredUsers, id: \.self) { user in
                    NavigationLink(destination: UserDetailsView(user: user)) {
                        HStack {
                            // User Avatar
                            if let url = URL(string: user.avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .clipped()
                                } placeholder: {
                                    Circle()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                            }
                            // User Info
                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.headline)
                                Text(user.phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .navigationTitle("Phlebotomists")
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            }
        }
        .onAppear {
            fetchPhlebotomists()
        }
    }

    // Function to fetch all users with the role 'Phlebotomist'
    private func fetchPhlebotomists() {
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedUsers: [User] = []
            
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let userData = child.value as? [String: Any],
                   let role = userData["role"] as? String,
                   role == "PHLEBOTOMIST" {
                    let user = User(id: child.key, data: userData) // Use new User model
                    fetchedUsers.append(user)
                }
            }
            
            DispatchQueue.main.async {
                self.phlebotomists = fetchedUsers
                self.isLoading = false
            }
        }
    }
}
