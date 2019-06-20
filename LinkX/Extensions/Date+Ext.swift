//
//  Date+Ext.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 3/23/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var thirtyDaysAhead: Date? {
        var components = DateComponents()
        components.day = 30
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
    
    var yesterday: Date? {
        var components = DateComponents()
        components.day = -1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
    
    func timeAgo(date: Date, numericDates: Bool) -> String {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.day, .month, .year, .hour, .second, .weekOfYear, .minute], from: self, to: date)
        
        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1y ago"
            } else {
                return "Last yr"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1m ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1w ago"
            } else {
                return "Last wk"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1d ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!)h ago"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!)m ago"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1m ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!)s ago"
        } else {
            return "Now"
        }
        
    }
}

