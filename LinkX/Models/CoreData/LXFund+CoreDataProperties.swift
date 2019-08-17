//
//  LXFund+CoreDataProperties.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/12/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//
//

import Foundation
import CoreData


extension LXFund {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LXFund> {
        return NSFetchRequest<LXFund>(entityName: "LXFund")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var state: String?
    @NSManaged public var city: String?
    @NSManaged public var email: String?
    @NSManaged public var stage: String?
    @NSManaged public var sectors: NSObject?

}
