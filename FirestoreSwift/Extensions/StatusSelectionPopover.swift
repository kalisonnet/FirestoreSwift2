//
//  StatusSelectionPopover.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/11/24.
//

import SwiftUI

struct StatusSelectionView: View {
    @Binding var showStatusSelection: Bool
    @Binding var showDonePopup: Bool
    var updateOrderStatus: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Order Status")
                    .font(.headline)
                    .padding()

                Button(action: {
                    updateOrderStatus("In-Progress")
                    showStatusSelection = false
                }) {
                    Text("Start")
                        .font(.title2)
                        .foregroundColor(.blue) // Text color for "Start"
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                Button(action: {
                    showDonePopup = true
                    showStatusSelection = false
                }) {
                    Text("Completed Partialy")
                        .font(.title2)
                        .foregroundColor(.green) // Text color for "Completed"
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                Button(action: {
                    showDonePopup = true
                    showStatusSelection = false
                }) {
                    Text("Completed")
                        .font(.title2)
                        .foregroundColor(.green) // Text color for "Completed"
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                Button(action: {
                    updateOrderStatus("Failed")
                    showStatusSelection = false
                }) {
                    Text("Failed")
                        .font(.title2)
                        .foregroundColor(.red) // Text color for "Failed"
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Status Options")
            .navigationBarItems(trailing: Button("Cancel") {
                showStatusSelection = false
            })
        }
    }
}
