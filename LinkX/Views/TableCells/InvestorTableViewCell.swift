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
    
    @IBOutlet var profileImage: UIImageView!
    
    public func configure(investor: Investor) {
        name.text = investor.fullName()
        firm.text = investor.firm
        
        setProfileImage()
    }
    
    public func configure(storedInvestor: LXInvestor) {
        name.text = storedInvestor.fullName()
        firm.text = storedInvestor.firm ?? ""
        
        setProfileImage()
    }
    
    func setProfileImage() {
        profileImage.contentMode = .scaleAspectFill
        profileImage.clipsToBounds = true
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        profileImage.layer.cornerRadius = 54 / 2.0
        profileImage.isUserInteractionEnabled = true
    }
}
