//
//  LXConstants.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/1/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public class LXConstants {
    static let PURCHASE_INVESTOR_CONTACT = Activity(data: ["id" : "Purchase Investor Contact", "name" : "Purchase Investor Contact", "points" : 25.0, "description" : "Purchase of investor contact."])
    static let REFERRAL = Activity(data: ["id" : "Refer a Friend", "name" : "Refer a Friend", "points" : 15.0, "description" : "When you refer a friend you both get 15 points when they sign up."])
    static let CONTRIBUTE_INVESTOR = Activity(data: ["id" : "Add an Investor", "name" : "Add an Investor", "points" : 20.0, "description" : "Get up to 20 points when you contribute a new investor."])
    static let POST = Activity(data: ["id" : "Add a Post", "name" : "Add a Post", "points" : 2.5, "description" : "Get 2.5 points for every post you contribute."])
}
