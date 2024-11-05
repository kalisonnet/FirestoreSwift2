//
//  OrderRowView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/8/24.
//

import SwiftUI

struct OrderRowView: View {
    var order: Order
    var isSelecting: Bool
    @Binding var selectedOrders: Set<String>
    var userManager: UserManager

    var body: some View {
        HStack {
            if isSelecting {
                Image(systemName: selectedOrders.contains(order.id ?? "") ? "checkmark.circle.fill" : "circle")
                    .onTapGesture {
                        toggleSelection()
                    }
            }
            VStack(alignment: .leading) {
                Text("\(order.referring_physician_name): \(order.referring_physician_id ?? "Unknown ID")")
                    .font(.headline)
                



                /*Text(order.test_name.joined(separator: ", "))
                    .font(.headline)*/
                Text(order.test_priority ?? "No Records")
                    .font(.subheadline)
                
                if !order.phlebotomist.isEmpty {
                    ForEach(order.phlebotomist, id: \.self) { assignedUserId in
                        if let assignedUser = userManager.users.first(where: { $0.id == assignedUserId }) {
                            HStack {
                                AsyncImage(url: URL(string: assignedUser.avatarUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                        .clipped()
                                } placeholder: {
                                    Circle().frame(width: 30, height: 30).foregroundColor(.gray)
                                }
                                Text("Assigned to: \(assignedUser.username)")
                                    .font(.subheadline)
                            }
                        }
                    }
                } else {
                    Text("Not Assigned")
                        .font(.subheadline)
                }
            }
        }
    }

    private func toggleSelection() {
        if selectedOrders.contains(order.id ?? "") {
            selectedOrders.remove(order.id ?? "")
        } else {
            selectedOrders.insert(order.id ?? "")
        }
    }
}

