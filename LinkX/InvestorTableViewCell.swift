//
//  InvestorTableViewCell.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 3/23/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

public class InvestorTableViewCell: UITableViewCell {
    
    @IBOutlet var name: UILabel!
    @IBOutlet var firm: UILabel!
    
    public func configure(investor: Investor) {
        name.text = investor.fullName()
        firm.text = investor.firm
    }
    
    public func configure(storedInvestor: LXInvestor) {
        name.text = storedInvestor.fullName()
        firm.text = storedInvestor.firm ?? ""
    }
}
