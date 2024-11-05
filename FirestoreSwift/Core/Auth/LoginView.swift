//
//  LoginView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/14/24.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showResetPassword = false
    @State private var showSignUp = false
    @State private var isLoggedIn = false

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .padding()

            TextField("Email", text: $email)
                .padding()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .padding()

            Button(action: {
                login()
            }) {
                Text("Login")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            Button("Forgot Password?") {
                showResetPassword.toggle()
            }
            .padding()
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView()
            }

            Spacer()

            // Sign Up Navigation Button
            Button(action: {
                showSignUp.toggle()
            }) {
                Text("Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
            .padding()
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
        .padding()
        // Navigation to MainTabView after login success
        .navigationDestination(isPresented: $isLoggedIn) {
            MainTabView()
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            } else {
                print("Login successful!")
                isLoggedIn = true // Trigger navigation to MainTabView
            }
        }
    }
}


struct ResetPasswordView: View {
    @State private var email = ""

    var body: some View {
        VStack {
            Text("Reset Password")
                .font(.title)
                .padding()

            TextField("Email", text: $email)
                .padding()

            Button(action: {
                resetPassword()
            }) {
                Text("Send Reset Email")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                print("Reset email sent.")
            }
        }
    }
}
