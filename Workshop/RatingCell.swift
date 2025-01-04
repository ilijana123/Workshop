//
//  RatingCell.swift
//  Workshop
//
//  Created by Ilijana Simonovska on 12/23/24.
//

import UIKit

class RatingCell: UITableViewCell {
    @IBOutlet weak var apartmentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var starsStackView: UIStackView!

    func configureStars(for rating: Int) {
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for i in 0..<5 {
            let isFilled = i < rating
            let imageName = isFilled ? "star.fill" : "star"
            let star = UIImageView(image: UIImage(systemName: imageName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)))
            star.translatesAutoresizingMaskIntoConstraints = false
            star.contentMode = .scaleAspectFit
            star.tintColor = isFilled ? .systemYellow : .systemGray
            starsStackView.addArrangedSubview(star)
        }

        starsStackView.distribution = .fillEqually
        starsStackView.alignment = .center

        starsStackView.layoutIfNeeded()
    }




}
