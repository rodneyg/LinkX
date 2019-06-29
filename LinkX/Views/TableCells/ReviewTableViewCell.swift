//
//  ReviewTableViewCell.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/21/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

class ReviewTableViewCell: UITableViewCell {

    @IBOutlet var textView: UITextView!
    @IBOutlet var submitButton: UIButton!
    
    var reviewSubmitted: ((String) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
