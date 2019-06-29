//
//  ContributionTableViewCell.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/26/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

class ContributionTableViewCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    public func configure(contribution: Contribution) {
        nameLabel.text = "You added \(contribution.firstName) \(contribution.lastName)"
        statusLabel.text = "\(contribution.status)"
    }
}
