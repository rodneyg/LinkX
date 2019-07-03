//
//  ContributeTableViewCell.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/1/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

class ActivityTableViewCell: UITableViewCell {

    @IBOutlet var typeText: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var descriptionText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(activity: Activity) {
        typeText.text = activity.name
        descriptionText.text = activity.description
        
        if let points = activity.points {
            pointsLabel.text = "\(points) \npoints"
            pointsLabel.layer.cornerRadius = 5.0
            pointsLabel.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
            pointsLabel.layer.borderWidth = 0.5
        } else {
            pointsLabel.isHidden = true
        }
    }
}
