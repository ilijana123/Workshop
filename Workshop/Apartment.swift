import Foundation

class Apartment {
    var apartmentId: String
    var sellerId: String
    var locationName: String
    var price: String
    var squareMeters: String
    var numberOfRooms: String
    var timeSlots: [String: [String: Bool]]
    var averageRating: Double?

    init(apartmentId: String, sellerId: String, locationName: String, price: String, squareMeters: String, numberOfRooms: String, timeSlots: [String: [String: Bool]]) {
        self.apartmentId = apartmentId
        self.sellerId = sellerId
        self.locationName = locationName
        self.price = price
        self.squareMeters = squareMeters
        self.numberOfRooms = numberOfRooms
        self.timeSlots = timeSlots
        self.averageRating = nil
    }
}
