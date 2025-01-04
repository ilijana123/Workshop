import UIKit
class NotificationCell: UITableViewCell {
    @IBOutlet weak var apartmentIdLabel: UILabel!
    @IBOutlet weak var buyerNameLabel: UILabel!
    @IBOutlet weak var buyerPhoneLabel: UILabel!
    @IBOutlet weak var timeSlotLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!

    var acceptAction: (() -> Void)?
    var rejectAction: (() -> Void)?

    @IBAction func acceptTapped(_ sender: UIButton) {
        acceptAction?()
    }

    @IBAction func rejectTapped(_ sender: UIButton) {
        rejectAction?()
    }
}
