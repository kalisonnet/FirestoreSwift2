//
//  ContentView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 8/6/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                }
                NavigationLink(destination: SignUpView()) {
                    Text("Sign Up")
                }
            }
            .navigationBarTitle("Welcome to LabExpert")
        }
    }
}
