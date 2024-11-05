//
//  AdminSettingsView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

struct AdminSettingsView: View {
    @Binding var isLoggedOut: Bool
    @State private var username: String = ""
    @State private var avatarUrl: String = ""
    @State private var phoneNumber: String = ""
    @State private var appearanceSelection = AppearanceOption.system
    @StateObject private var locationManager = CombinedLocationManager(userId: Auth.auth().currentUser?.uid ?? "")
    
    enum AppearanceOption: String, CaseIterable {
        case light = "Light Mode"
        case dark = "Dark Mode"
        case system = "System Default"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Section with avatar, username, and navigation to Profile Edit
                Section {
                    NavigationLink(destination: ProfileView(username: $username, avatarUrl: $avatarUrl, phoneNumber: $phoneNumber)) {
                        HStack {
                            // Avatar image
                            if let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Circle()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                            // Username
                            VStack(alignment: .leading) {
                                Text(username)
                                    .font(.headline)
                                Text("Profile")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Appearance Section
                Section {
                    NavigationLink(destination: AdminAppearanceView(appearanceSelection: $appearanceSelection)) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.blue)
                            Text("Appearance")
                        }
                    }
                }
                
                // User Role Section
                Section {
                    NavigationLink(destination: UsersRoleView()) {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(.blue)
                            Text("Users info")
                        }
                    }
                }
                
                // Rules Section (Empty View for now)
                Section {
                    NavigationLink(destination: RulesListView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Rules")
                        }
                    }
                }
                
                // Logout Button
                Section {
                    Button(action: logout) {
                        HStack {
                            Image(systemName: "power")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadUserData()
            }
        }
    }
    
    // Function to load user data from Firebase
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.username = userData["username"] as? String ?? ""
                self.phoneNumber = userData["phoneNumber"] as? String ?? ""
                self.avatarUrl = userData["avatarUrl"] as? String ?? ""
            }
        }
    }
    
    // Logout function
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedOut = true // Trigger redirect to LoginView
        } catch let error {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
}

// Profile View with Save functionality
struct AdminProfileView: View {
    @Binding var username: String
    @Binding var avatarUrl: String
    @Binding var phoneNumber: String
    
    @State private var selectedImages: [UIImage] = [] // Updated to handle multiple images
    @State private var showImagePicker = false
    @Environment(\.dismiss) var dismiss  // To dismiss the view after saving
    
    var body: some View {
        Form {
            Section(header: Text("Avatar")) {
                HStack {
                    if let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }
                    }
                    Button("Change Avatar") {
                        showImagePicker = true
                    }
                }
            }
            
            Section(header: Text("User Info")) {
                TextField("Username", text: $username)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
            }
            
            Section {
                Button(action: saveProfile) {
                    Text("Save")
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $selectedImages) // Updated to use the array for multiple images
        }
    }
    
    // Save profile changes to Firebase
    private func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(userId)
        let updatedData: [String: Any] = [
            "username": username,
            "phoneNumber": phoneNumber
        ]
        
        ref.updateChildValues(updatedData) { error, _ in
            if let error = error {
                print("Failed to update profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully.")
            }
        }
        
        // Handle avatar image upload to Firebase Storage if needed
        if let image = selectedImages.first {
            uploadAvatarImage(image)
        }
        
        dismiss()  // Dismiss the view after saving
    }
    
    // Function to upload the avatar image to Firebase Storage
    private func uploadAvatarImage(_ image: UIImage) {
        let storageRef = Storage.storage().reference().child("avatars/\(Auth.auth().currentUser!.uid).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Avatar upload failed: \(error.localizedDescription)")
            } else {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self.updateAvatarUrl(url.absoluteString)
                    }
                }
            }
        }
    }
    
    // Function to update the avatar URL in Firebase Database
    private func updateAvatarUrl(_ url: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(userId)
        ref.updateChildValues(["avatarUrl": url]) { error, _ in
            if let error = error {
                print("Failed to update avatar URL: \(error.localizedDescription)")
            } else {
                print("Avatar URL updated successfully.")
                self.avatarUrl = url // Update the binding value
            }
        }
    }
}

// Appearance View
struct AdminAppearanceView: View {
    @Binding var appearanceSelection: AdminSettingsView.AppearanceOption
    
    var body: some View {
        Form {
            Picker("Appearance", selection: $appearanceSelection) {
                ForEach(PMSettingsView.AppearanceOption.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: appearanceSelection) { oldValue, newValue in
                updateAppearance(newValue)
            }
        }
        .navigationTitle("Appearance")
    }
    
    private func updateAppearance(_ option: AdminSettingsView.AppearanceOption) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let window = windowScene.windows.first else { return }
        
        switch option {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

