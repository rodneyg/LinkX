//
//  Investor.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 3/23/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Investor {
    public var id: String
    public var first: String
    public var last: String
    public var title: String
    public var firm: String
    public var contactInfo: ContactInfo
    public var rating: Rating
    public var metadata: [String : Any]
    
    public struct ContactInfo {
        public var email: String
        public var city: String
        public var state: String
        
        init(data: [String : Any]) {
            self.email = (data["email"] as? String) ?? ""
            self.city = (data["city"] as? String) ?? ""
            self.state = (data["state"] as? String) ?? ""
        }
    }
    
    public struct Rating {
        public var avgRating: Double
        public var numOfRatings: Int
        
        init(data: [String : Any]) {
            self.avgRating = (data["avg_rating"] as? Double) ?? 0.0
            self.numOfRatings = (data["num_of_ratings"] as? Int) ?? 0
        }
    }
    
    public init(data: [String : Any]) {
        self.id = (data["id"] as? String) ?? ""
        self.first = (data["first"] as? String) ?? ""
        self.last = (data["last"] as? String) ?? ""
        self.title = (data["title"] as? String) ?? ""
        self.firm = (data["firm"] as? String) ?? ""
        self.metadata = data
        
        if let contactData = data["contact_info"] as? [String : Any] {
            self.contactInfo = ContactInfo(data: contactData)
        } else {
            self.contactInfo = ContactInfo(data: [String : Any]())
        }
        
        if let ratingData = data["rating"] as? [String : Any] {
            self.rating = Rating(data: ratingData)
        } else {
            self.rating = Rating(data: [String : Any]())
        }
    }
    
    public func fullName() -> String {
        return "\(first) \(last)"
    }
}
