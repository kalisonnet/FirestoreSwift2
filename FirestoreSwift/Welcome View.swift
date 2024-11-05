//
//  Welcome View.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/2/24.
//

import SwiftUI

struct WelcomeView: View {
    @State private var navigateToLogin = false // State to control navigation to LoginView

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1.00)),
                    Color(UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1.00))
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image(.originalBranding)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 150)
                    .padding(.bottom, 30)
                    .padding(.top, -70)
                
                Text("SwiftDraws")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                HStack(spacing: 0) {
                    Text("Let's dive into SwiftDraws ")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        navigateToLogin = true
                    }) {
                        Text("World")
                            .foregroundColor(.red)
                    }
                }

                // This NavigationLink initiates the transition programmatically
                NavigationLink(
                    destination: LoginView(),
                    isActive: $navigateToLogin
                ) {
                    EmptyView() // Hidden link
                }
            }
            .padding()
        }
        // Embed in NavigationStack to ensure consistent navigation behavior
        .navigationTitle("")
        .navigationBarHidden(true) // Hide navigation bar for Welcome screen
    }
}
