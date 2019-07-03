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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(activity: Activity) {
        guard let points = activity.points else {
            return //points is nil
        }
        
        typeText.text = activity.name
        pointsLabel.text = "\(points.value)"
    }
}
