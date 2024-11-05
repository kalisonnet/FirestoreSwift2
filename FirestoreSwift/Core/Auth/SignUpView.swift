//
//  SignUpView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/14/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import FirebaseMessaging

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phoneNumber = ""
    @State private var username = ""
    @State private var selectedRole = ""
    @State private var avatarImages: [UIImage] = [] // Array for multiple images
    @State private var avatarUrl: String?
    @State private var isLoading = false
    @State private var showImagePicker = false
    @State private var errorMessage: String?

    let roles = [/*"ADMIN", "PHLEBOTOMY MANAGER", "LOGISTIC MANAGER", "SALES MANAGER",*/ "PHLEBOTOMIST", "LOGISTIC", "SALES"]

    var body: some View {
        VStack {
            Text("Create Your Account")
                .font(.largeTitle)
                .padding(.bottom, 20)

            // Username Text Field
            TextField("Username", text: $username)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            // Email Text Field
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            // Password Text Field
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            // Confirm Password Text Field
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            // Phone Number Text Field
            TextField("Phone Number", text: $phoneNumber)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .keyboardType(.phonePad)

            // Role Picker with placeholder
            Picker("Select your Role", selection: $selectedRole) {
                Text("Select your Role").tag("") // Placeholder option
                ForEach(roles, id: \.self) {
                    Text($0).tag($0) // Ensure to tag each option to update `selectedRole`
                }
            }

            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)

            // Avatar Upload
            if let avatarImage = avatarImages.first {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .onTapGesture {
                        showImagePicker = true
                    }
            } else {
                Button(action: {
                    showImagePicker = true
                }) {
                    Text("Upload Avatar")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(action: {
                signUpUser()
            }) {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
            .padding(.top, 20)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $avatarImages) // Bind to the array for multiple images
        }
    }

    // Function to handle user registration and Firestore setup
    private func signUpUser() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }

            guard let userId = authResult?.user.uid else {
                errorMessage = "Failed to retrieve user ID"
                isLoading = false
                return
            }

            if let avatarImage = avatarImages.first {
                uploadAvatar(image: avatarImage, userId: userId) { result in
                    switch result {
                    case .success(let avatarUrl):
                        saveUserToDatabase(userId: userId, avatarUrl: avatarUrl)
                    case .failure(let error):
                        errorMessage = "Avatar upload failed: \(error.localizedDescription)"
                        isLoading = false
                    }
                }
            } else {
                saveUserToDatabase(userId: userId, avatarUrl: nil)
            }
        }
    }

    // Function to upload avatar to Firebase Storage
    private func uploadAvatar(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("avatars/\(userId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Image compression failed", code: 0, userInfo: nil)))
            return
        }

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let avatarUrl = url?.absoluteString else {
                    completion(.failure(NSError(domain: "Failed to retrieve download URL", code: 0, userInfo: nil)))
                    return
                }

                completion(.success(avatarUrl))
            }
        }
    }

    // Function to save user data to Realtime Database, including FCM token
    private func saveUserToDatabase(userId: String, avatarUrl: String?) {
        let userData: [String: Any] = [
            "email": email,
            "username": username,
            "phoneNumber": phoneNumber,
            "role": selectedRole,
            "avatarUrl": avatarUrl ?? ""
        ]

        let ref = Database.database().reference().child("users").child(userId)
        ref.setValue(userData) { error, _ in
            if let error = error {
                errorMessage = "Failed to save user data: \(error.localizedDescription)"
                isLoading = false
            } else {
                // Register the FCM token after saving user data
                registerFCMToken(userId: userId)
            }
        }
    }

    // Function to register FCM token in Realtime Database
    private func registerFCMToken(userId: String) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
                return
            }

            if let token = token {
                let ref = Database.database().reference().child("users").child(userId)
                ref.updateChildValues(["fcmToken": token]) { error, _ in
                    if let error = error {
                        errorMessage = "Failed to save FCM token: \(error.localizedDescription)"
                    } else {
                        print("FCM Token updated in Realtime Database: \(token)")
                    }
                    isLoading = false
                }
            }
        }
    }
}
