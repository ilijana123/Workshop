//
//  NotificationModel.swift
//  Workshop
//
//  Created by Ilijana Simonovska on 12/22/24.
//
import Foundation

struct NotificationModel {
    let id: String
    let bookingId: String
    let apartmentId: String
    let buyerId: String
    let buyerName: String
    let buyerPhone: String
    let timeSlot: String
    var status: String

    init(id: String, data: [String: Any]) {
        self.id = id
        self.bookingId = data["bookingId"] as? String ?? ""
        self.apartmentId = data["apartmentId"] as? String ?? ""
        self.buyerId = data["buyerId"] as? String ?? ""
        self.buyerName = data["buyerName"] as? String ?? "Unknown"
        self.buyerPhone = data["buyerPhone"] as? String ?? "Unknown"
        self.timeSlot = data["timeSlot"] as? String ?? "Unknown"
        self.status = data["status"] as? String ?? "pending"
    }
}
