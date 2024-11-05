//
//  SignatureView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/3/24.
//

import SwiftUI

struct SignatureView: View {
    @State private var path = Path()
    @State private var signatureImage: UIImage? // Holds the image of the signature
    @Binding var shouldClearCanvas: Bool // Control clearing of the canvas
    @State private var showApostille = false // Shows the apostille after saving
    var onSave: (UIImage) -> Void // Closure to pass the saved signature to AddOrderView

    var body: some View {
        VStack {
            Text("Referring Physician Signature")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(white: 0.95), Color(white: 0.9)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(radius: 3)
                
                // Canvas for drawing the signature
                Canvas { context, size in
                    context.stroke(path, with: .color(.black), lineWidth: 2)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if path.isEmpty {
                                path.move(to: value.location)
                            } else {
                                path.addLine(to: value.location)
                            }
                        }
                )
            }
            .frame(height: 200)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
            .padding()

            // Show apostille under the signature after saving
            if showApostille {
                VStack {
                    Text("Apostille Verified")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("Date: \(getCurrentDate())")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
            }

            HStack(spacing: 20) {
                // Clear Signature button
                Button(action: clearSignature) {
                    Text("Clear Signature")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Save Signature button
                Button(action: saveSignature) {
                    Text("Save Signature")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .onChange(of: shouldClearCanvas) { newValue in
            if newValue {
                clearSignature()
                shouldClearCanvas = false // Reset after clearing
            }
        }
    }

    // Save the drawn signature as an image
    private func saveSignature() {
        let signatureFrameSize = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: signatureFrameSize)

        signatureImage = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setLineWidth(2)
            cgContext.addPath(path.cgPath) // Add the drawn path to the context
            cgContext.strokePath() // Stroke the path to create the image
        }

        if let image = signatureImage {
            onSave(image) // Notify the parent view that the signature is saved
            showApostille = true // Show apostille details after saving
        }
    }

    // Function to clear the signature
    private func clearSignature() {
        path = Path() // Clear the path
        showApostille = false // Hide apostille when cleared
        print("Signature cleared.")
    }

    // Function to get the current date in a readable format
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}
