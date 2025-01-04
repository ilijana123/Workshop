import Foundation
import FirebaseDatabase

struct Booking {
    let bookingId: String
    let apartmentId: String
    let sellerId: String
    let buyerId: String
    let timeSlot: String?
    let visited: Bool
    let ratingSeller: Float
    let ratingApartment: Float
    let sellerDecision: String
    init(bookingId:String,apartmentId:String,sellerId:String,buyerId:String,timeSlot:String,visited:Bool,ratingSeller:Float,ratingApartment:Float,sellerDecision:String) {
        self.bookingId=bookingId;
        self.apartmentId=apartmentId;
        self.sellerId=sellerId;
        self.buyerId=buyerId;
        self.timeSlot=timeSlot;
        self.visited=visited;
        self.ratingSeller=ratingSeller;
        self.ratingApartment=ratingApartment;
        self.sellerDecision=sellerDecision;

    }
}

