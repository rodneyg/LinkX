//
//  FundTableViewCell.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/11/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

class FundTableViewCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var lastLabel: UILabel!
    
    public func configure(fund: Fund) {
        nameLabel.text = fund.name
        
        if let sectors = fund.metadata["sectors"] as? [String] {
            subtitleLabel.text = sectors.joined(separator:",")
        }
        
        if let stages = fund.metadata["stage"] as? [String] {
            lastLabel.text = stages.joined(separator:",")
        }
    }
}
