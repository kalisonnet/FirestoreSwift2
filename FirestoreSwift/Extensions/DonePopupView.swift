//
//  DonePopupView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/12/24.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DonePopupView: View {
    @Binding var collectionDate: Date
    @Binding var collectionTime: Date
    @Binding var collectionTubes: [CollectionTube]
    @Binding var note: String
    @Binding var attachment: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var pictures: [UIImage]

    @State private var showDocumentPicker = false
    @State private var selectedFileUrl: URL?
    @State private var showAlert = false
    @State private var isDateSelected = false
    @State private var isTimeSelected = false
    @State private var willDeliverMyself = false
    @State private var willUseDriver = false
    @State private var tubeName = ""
    @State private var tubeQuantity = 1
    @State private var newNote = "" // For adding a new note
    @State private var notes: [OrderNote] = []
    
    @FocusState private var isTextFieldFocused: Bool

    let saveCompletion: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    Text("Complete Order")
                        .font(.headline)
                        .padding()
                    
                    DatePicker("Select Date", selection: $collectionDate, displayedComponents: .date)
                        .onChange(of: collectionDate) { _ in isDateSelected = true }
                        .padding()
                    
                    DatePicker("Select Time", selection: $collectionTime, displayedComponents: .hourAndMinute)
                        .onChange(of: collectionTime) { _ in isTimeSelected = true }
                        .padding()
                    
                    Section(header: Text("Notes")) {
                        TextEditor(text: $note)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                            .padding(.vertical, 5)
                        
                        Button(action: addNote) {
                            Text("Add Note")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .focused($isTextFieldFocused)
                        }
                        .disabled(note.isEmpty) // Check `note` instead of `newNote`

                        if !notes.isEmpty {
                            List {
                                ForEach(notes) { note in
                                    VStack(alignment: .leading) {
                                        Text(note.note)
                                        Text(note.timestamp, style: .date)
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }

                    .padding()

                    Button(action: { showDocumentPicker = true }) {
                        Label(selectedFileUrl == nil ? "Add Attachment" : "Change Attachment", systemImage: "paperclip")
                    }
                    .padding()
                    
                    Button(action: { showImagePicker = true }) {
                        Label(pictures.isEmpty ? "Add Pictures" : "Add More Pictures", systemImage: "camera")
                    }
                    .padding()
                    
                    if !pictures.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(pictures, id: \.self) { picture in
                                    Image(uiImage: picture)
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Collection Tubes")
                            .font(.subheadline)
                            .padding(.bottom, 5)
                        
                        VStack(spacing: 10) {
                            TextField("Tube Name", text: $tubeName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isTextFieldFocused)
                                .padding(.horizontal)
                            
                            Stepper("Qty: \(tubeQuantity)", value: $tubeQuantity, in: 1...100)
                                .padding(.horizontal)
                            
                            Button(action: addCollectionTube) {
                                Label("Add Tube", systemImage: "plus")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        List {
                            ForEach(collectionTubes) { tube in
                                HStack {
                                    Text(tube.name)
                                    Spacer()
                                    Text("Qty: \(tube.quantity)")
                                }
                            }
                            .onDelete(perform: removeTube)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    
                    VStack(alignment: .leading) {
                        Text("Who will deliver to the Lab?")
                            .font(.subheadline)
                            .padding(.bottom, 5)
                        
                        HStack {
                            Toggle(isOn: Binding(
                                get: { willDeliverMyself },
                                set: { newValue in
                                    willDeliverMyself = newValue
                                    if newValue { willUseDriver = false }
                                }
                            )) {
                                Text("Me")
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            
                            Toggle(isOn: Binding(
                                get: { willUseDriver },
                                set: { newValue in
                                    willUseDriver = newValue
                                    if newValue { willDeliverMyself = false }
                                }
                            )) {
                                Text("Driver")
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        if isDateValid() && isTimeValid() {
                            saveCompletion()
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            showAlert = true
                        }
                    }) {
                        Text("Save")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .onTapGesture {
                if isTextFieldFocused { isTextFieldFocused = false }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid Selection"),
                    message: Text("Please select a valid collection date and time before saving."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $pictures)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(selectedFileUrl: $selectedFileUrl)
            }
        }
    }

    private func isDateValid() -> Bool {
        return isDateSelected
    }

    private func isTimeValid() -> Bool {
        return isTimeSelected
    }

    private func addNote() {
        let newOrderNote = OrderNote(note: note, timestamp: Date())
        notes.append(newOrderNote) // Append the current note to the list
        note = "" // Clear the `note` field after adding
    }


    private func addCollectionTube() {
        guard !tubeName.isEmpty else { return }
        let newTube = CollectionTube(name: tubeName, quantity: tubeQuantity)
        collectionTubes.append(newTube)
        tubeName = ""
        tubeQuantity = 1
    }

    private func removeTube(at offsets: IndexSet) {
        collectionTubes.remove(atOffsets: offsets)
    }
}


// Custom CheckboxToggleStyle
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                configuration.label
            }
        }
    }
}

// Document Picker to select files
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileUrl: URL?

    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedFileUrl: $selectedFileUrl)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var selectedFileUrl: URL?

        init(selectedFileUrl: Binding<URL?>) {
            _selectedFileUrl = selectedFileUrl
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            selectedFileUrl = urls.first
        }
    }
}
