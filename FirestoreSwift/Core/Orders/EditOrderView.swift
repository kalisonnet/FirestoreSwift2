//
//  EditOrderView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/9/24.
//

import SwiftUI

struct EditOrderView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var order: Order
    @State private var updatedTestName = ""
    @State private var updatedPatientName = ""
    @State private var updatedTestDate = Date()
    
    var body: some View {
        Form {
            Section(header: Text("Edit Order Information")) {
                TextField("Test Name", text: $updatedTestName)
                TextField("Patient Name", text: $updatedPatientName)
                DatePicker("Test Date", selection: $updatedTestDate, displayedComponents: .date)
            }
            
            Button(action: updateOrder) {
                Text("Update Order")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            //updatedTestName = order.test_name
            updatedPatientName = order.patient_name
            updatedTestDate = order.order_date
        }
        .navigationTitle("Edit Order")
    }
    
    private func updateOrder() {
        //order.test_name = updatedTestName
        order.patient_name = updatedPatientName
        order.order_date = updatedTestDate
        
        OrderManager.shared.updateOrder(order)
        presentationMode.wrappedValue.dismiss()
    }
}
