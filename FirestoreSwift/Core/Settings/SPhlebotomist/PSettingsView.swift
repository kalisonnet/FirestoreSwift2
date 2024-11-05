//
//  PSettingsView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/18/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

struct PSettingsView: View {
    @Binding var isLoggedOut: Bool
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var avatarUrl: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var pictures: [UIImage] = [] // For multiple images
    @State private var showImagePicker = false
    @State private var appearanceSelection = AppearanceOption.system
    @State private var isLoading = false
    @StateObject private var locationManager = CombinedLocationManager(userId: Auth.auth().currentUser?.uid ?? "")
    
    enum AppearanceOption: String, CaseIterable {
        case light = "Light Mode"
        case dark = "Dark Mode"
        case system = "System Default"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    // Avatar image
                    HStack {
                        if let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .clipped()
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
                        Button("Change Avatar") {
                            showImagePicker = true
                        }
                    }
                    
                    // Username
                    TextField("Username", text: $username)
                    
                    // Email (non-editable, but visible)
                    TextField("Email", text: $email)
                        .disabled(true)
                        .foregroundColor(.gray)
                    
                    // Phone Number
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                // Appearance Mode
                Section(header: Text("Appearance")) {
                    Picker("Appearance", selection: $appearanceSelection) {
                        ForEach(AppearanceOption.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: appearanceSelection) { oldValue, newValue in
                        updateAppearance(newValue)
                    }
                }
                
                // Add a label to show the user's current location (for debugging or info)
                Section(header: Text("Current Location")) {
                    if let location = locationManager.userLocation {
                        Text("Latitude: \(location.latitude)")
                        Text("Longitude: \(location.longitude)")
                    } else {
                        Text("Location unavailable")
                    }
                }
                
                // Logout Button
                Section {
                    Button(action: logout) {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadUserData()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $pictures) // Updated to use multiple images
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProfile) {
                        Text("Save")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Function to load user data from Firebase
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.username = userData["username"] as? String ?? ""
                self.email = userData["email"] as? String ?? ""
                self.phoneNumber = userData["phoneNumber"] as? String ?? ""
                self.avatarUrl = userData["avatarUrl"] as? String ?? ""
            }
        }
    }
    
    // Function to save the updated profile data
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
        if let image = selectedImage {
            uploadAvatarImage(image)
        }
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
        ref.updateChildValues(["avatarUrl": url])
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
    
    // Update appearance
    private func updateAppearance(_ option: AppearanceOption) {
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

