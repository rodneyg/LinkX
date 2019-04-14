//
//  IAPHandler.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 3/23/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import Foundation

class IAPHandler: NSObject {
    
    override init() {
        if let ud = UserDefaults(suiteName: "group.ios.codesigned.LinkX") {
            defaults = ud
        } else {
            defaults = UserDefaults.standard
        }
    }
    
    var defaults: UserDefaults!
    
    static let shared = IAPHandler()
    
    let EMAILS_LEFT = "EMAILS_LEFT"
    let RESET_DATE = "reset_date"
    
    func incrementEmail() { // counter for number of runs for the app. You can call this from App Delegate
        setEmails(getEmailCount() + 1)
    }
    
    func shouldReset() -> Bool { // Reads number of runs from UserDefaults and returns it.
        let saved = defaults.value(forKey: RESET_DATE)
        
        var time = 0.0
        if (saved != nil) {
            time = saved as! Double
            return Date().timeIntervalSince1970 >= Date(timeIntervalSince1970: time).thirtyDaysAhead!.timeIntervalSince1970
        } else {
            setResetDate()
        }
        
        return false
    }
    
    func setResetDate() {
        defaults.setValuesForKeys([RESET_DATE : Date().timeIntervalSince1970])
        defaults.synchronize()
    }
    
    func setEmails(_ emails: Int) {
        defaults.setValuesForKeys([EMAILS_LEFT: emails])
        defaults.synchronize()
    }
    
    func getEmailCount() -> Int { // Reads number of runs from UserDefaults and returns it.
        let saved = defaults.value(forKey: EMAILS_LEFT)
        
        var count = 0
        if (saved != nil) {
            count = saved as! Int
        }
        
        return count
    }
}
