//
//  Fund.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Fund {
    public var id: String
    public var name: String
    public var contact: String
    public var city: String
    public var state: String
    public var stage: String
    public var email: String?
    public var sectors = [Sector]()
    public var publicUrl: String?
    public var metadata: [String : Any]
    
    public init(data: [String : Any]) {
        self.id = (data["id"] as? String) ?? ""
        self.name = (data["name"] as? String) ?? ""
        self.contact = (data["contact"] as? String) ?? ""
        self.city = (data["city"] as? String) ?? ""
        self.state = (data["state"] as? String) ?? ""
        self.stage = (data["stage"] as? String) ?? ""
        self.email = (data["email"] as? String) ?? ""
        self.publicUrl = (data["public_url"] as? String)
        self.metadata = data
        
        if let sectorData = data["sectors"] as? [String] {
            for sector in sectorData {
                self.sectors.append(Sector(data: [sector : sector]))
            }
        }
    }
}
