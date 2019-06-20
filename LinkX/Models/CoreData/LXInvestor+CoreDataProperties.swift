//
//  LXInvestor+CoreDataProperties.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 4/13/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//
//

import Foundation
import CoreData

extension LXInvestor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LXInvestor> {
        return NSFetchRequest<LXInvestor>(entityName: "LXInvestor")
    }

    @NSManaged public var city: String?
    @NSManaged public var email: String?
    @NSManaged public var firm: String?
    @NSManaged public var first: String?
    @NSManaged public var id: String?
    @NSManaged public var last: String?
    @NSManaged public var metadata: NSData?
    @NSManaged public var state: String?
    @NSManaged public var title: String?

    public func fullName() -> String {
        return "\(first ?? "") \(last ?? "")"
    }
}
