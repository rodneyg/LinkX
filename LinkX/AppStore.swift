//
//  AppStore.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/9/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//


import Foundation
import StoreKit

class AppStore {
    
    init() {
        if let ud = UserDefaults(suiteName: "com.ios.codesigned.LinkX") {
            defaults = ud
        } else {
            defaults = UserDefaults.standard
        }
    }
    
    var defaults: UserDefaults!
    
    static let shared = AppStore()
    
    let runIncrementerSetting = "numberOfRuns"  // UserDefauls dictionary key where we store number of runs
    let minimumRunCount = 5                     // Minimum number of runs that we should have until we ask for review
    
    func incrementAppRuns() { // counter for number of runs for the app. You can call this from App Delegate
        setAppRuns(getRunCounts() + 1)
    }

    func setAppRuns(_ runs: Int) {
        defaults.setValuesForKeys([runIncrementerSetting: runs])
        defaults.synchronize()
    }
    
    func getRunCounts() -> Int { // Reads number of runs from UserDefaults and returns it.
        let savedRuns = defaults.value(forKey: runIncrementerSetting)
        
        var runs = 0
        if (savedRuns != nil) {
            runs = savedRuns as! Int
        }
        
        print("Run Counts are \(runs)")
        return runs
    }
    
    func showReview() {
        let runs = getRunCounts()
        print("Show Review")
        
        if (runs > minimumRunCount) {
            setAppRuns(0)
            if #available(iOS 10.3, *) {
                print("Review Requested")
                SKStoreReviewController.requestReview()
            } else {
                // Fallback on earlier versions
            }
        } else {
            print("Runs are not enough to request review!")
        }
    }
}
