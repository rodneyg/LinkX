//
//  RateTableViewCell.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/21/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import Cosmos

class RateTableViewCell: UITableViewCell {

    @IBOutlet var rateLabel: UILabel!
    @IBOutlet var starView: CosmosView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    public func configure(name: String) {
        rateLabel.text = "Rate \(name)"
    }
}
