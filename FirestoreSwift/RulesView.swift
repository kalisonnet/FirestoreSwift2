//
//  RulesView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/27/24.
//


import SwiftUI
import FirebaseDatabase

struct RulesListView: View {
    @State private var rules: [Rule] = [] // List of rules fetched from Firebase
    @State private var showAddRuleView = false // Flag to show the Add Rule View
    @State private var selectedRule: Rule? // Rule selected for editing

    var body: some View {
        NavigationStack {
            List {
                // Loop through the rules and use NavigationLink to navigate to RulesView for editing
                ForEach(rules) { rule in
                    NavigationLink(destination: RulesView(rulesList: $rules, existingRule: rule)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Phlebotomist ID: \(rule.phlebotomistId)")
                                Text("Physician IDs: \(rule.referring_physician_id.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if rule.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rules")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedRule = nil // Clear selection for adding a new rule
                        showAddRuleView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                fetchRules() // Fetch the rules from Firebase when the view appears
            }
            // Present the Add Rule View as a sheet when the add button is pressed
            .sheet(isPresented: $showAddRuleView) {
                // Pass nil to the RulesView for adding a new rule
                RulesView(rulesList: $rules, existingRule: nil)
            }
        }
    }

    // Function to fetch rules from Firebase
    private func fetchRules() {
        let ref = Database.database().reference().child("rules")
        ref.observe(.value) { snapshot in
            var fetchedRules: [Rule] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let ruleData = snapshot.value as? [String: Any],
                   let rule = Rule.fromDictionary(ruleData, id: snapshot.key) {
                    fetchedRules.append(rule)
                }
            }
            rules = fetchedRules
        }
    }
}

struct RulesView: View {
    @Binding var rulesList: [Rule] // The list of rules passed in to update
    var existingRule: Rule? // Optional: passed in if editing a rule
    
    @State private var physicianNumbers: [String] = [] // List of Physician numbers
    @State private var selectedPhlebotomistId: String? // Selected phlebotomist's ID
    @State private var isActive: Bool = false // Active/Inactive toggle
    @State private var showPhlebotomistSelection = false // To control showing the phlebotomist selection sheet
    @Environment(\.dismiss) var dismiss // To navigate back

    @ObservedObject var userManager = UserManager() // UserManager to fetch users from Firebase
    
    init(rulesList: Binding<[Rule]>, existingRule: Rule? = nil) {
        self._rulesList = rulesList
        self.existingRule = existingRule
        if let rule = existingRule {
            _physicianNumbers = State(initialValue: rule.referring_physician_id)
            _selectedPhlebotomistId = State(initialValue: rule.phlebotomistId)
            _isActive = State(initialValue: rule.isActive)
        }
    }

    var body: some View {
        Form {
            // Physician Numbers Entry Section
            Section(header: Text("Physician ID")) {
                ForEach(physicianNumbers.indices, id: \.self) { index in
                    HStack {
                        TextField("Enter Physician ID", text: Binding(
                            get: { physicianNumbers[index] },
                            set: { physicianNumbers[index] = $0 }
                        ))
                        Button(action: {
                            physicianNumbers.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle")
                        }
                    }
                }
                Button(action: {
                    physicianNumbers.append("")
                }) {
                    Text("Add Physician ID")
                }
            }
            
            // Phlebotomist Selection Section
            Section(header: Text("Select Phlebotomist")) {
                Button(action: {
                    showPhlebotomistSelection.toggle() // Trigger the sheet to open
                }) {
                    Text(selectedPhlebotomistId == nil ? "Select Phlebotomist" : "Phlebotomist Selected")
                }
            }
            
            // Active/Inactive Toggle Section
            Section {
                Toggle(isOn: $isActive) {
                    Text("Active")
                }
            }
            
            // Save Rule Button
            Button(action: {
                saveRule()
            }) {
                Text(existingRule == nil ? "Save Rule" : "Update Rule")
            }
        }
        .navigationTitle(existingRule == nil ? "Create Rule" : "Edit Rule")
        .sheet(isPresented: $showPhlebotomistSelection) {
            PhlebotomistSelectionView(phlebotomists: userManager.phlebotomists(), selectedPhlebotomistId: $selectedPhlebotomistId)
        }
    }

    // Function to save or update the rule to Firebase Realtime Database and go back to Rules ListView
    private func saveRule() {
        // Ensure that the selectedPhlebotomistId and physician numbers are valid
        guard !physicianNumbers.isEmpty, let phlebotomistId = selectedPhlebotomistId, !phlebotomistId.isEmpty else {
            print("Missing physician numbers or phlebotomist selection.")
            return
        }

        let ruleId = existingRule?.id ?? UUID().uuidString.replacingOccurrences(of: ".", with: "_")
        let newRule = Rule(
            id: ruleId,
            referring_physician_id: physicianNumbers,
            phlebotomistId: phlebotomistId,
            isActive: isActive
        )

        // Reference to Firebase Realtime Database
        let ref = Database.database().reference().child("rules").child(newRule.id)

        // Save or update the rule in Firebase
        ref.setValue(newRule.toDictionary()) { error, _ in
            if let error = error {
                print("Error saving rule: \(error.localizedDescription)")
            } else {
                print("Rule saved successfully!")

                if let index = rulesList.firstIndex(where: { $0.id == newRule.id }) {
                    rulesList[index] = newRule // Update the rule in the list
                } else {
                    rulesList.append(newRule) // Add new rule to the list
                }

                // After saving, navigate back to the previous view
                dismiss()
            }
        }
    }
}

// Phlebotomist Selection View
struct PhlebotomistSelectionView: View {
    var phlebotomists: [User]
    @Binding var selectedPhlebotomistId: String?
    
    var body: some View {
        List(phlebotomists) { phlebotomist in
            HStack {
                AsyncImage(url: URL(string: phlebotomist.avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .clipped()
                } placeholder: {
                    Image(systemName: "person.circle")
                }
                .frame(width: 40, height: 40)
                
                Text(phlebotomist.username)
                Spacer()
                if phlebotomist.id == selectedPhlebotomistId {
                    Image(systemName: "checkmark")
                }
            }
            .onTapGesture {
                selectedPhlebotomistId = phlebotomist.id
            }
        }
    }
}


// Extension to convert the Rule to a dictionary
extension Rule {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "referring_physician_id": referring_physician_id,
            "phlebotomistId": phlebotomistId,
            "isActive": isActive
        ]
    }

    static func fromRuleDictionary(_ data: [String: Any], id: String) -> Rule? {
        guard let referringPhysicianId = data["referring_physician_id"] as? [String],
              let phlebotomistId = data["phlebotomistId"] as? String,
              let isActive = data["isActive"] as? Bool else {
            return nil
        }

        return Rule(id: id, referring_physician_id: referringPhysicianId, phlebotomistId: phlebotomistId, isActive: isActive)
    }
}
