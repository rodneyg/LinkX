//
//  ActivityTableViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/1/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

class ActivityTableViewController: UITableViewController {
    
    let activities = [LXConstants.REFERRAL, LXConstants.CONTRIBUTE_INVESTOR]
    
    var activitySelected: ((Activity) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ActivityTableViewCell", bundle: nil), forCellReuseIdentifier: "ActivityTableViewCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 77.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
            tableView.dequeueReusableCell(withIdentifier: "ActivityTableViewCell", for: indexPath) as? ActivityTableViewCell else {
                return UITableViewCell()
        }
        
        cell.configure(activity: activities[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < activities.count else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        activitySelected?(activities[indexPath.row])
    }

}
