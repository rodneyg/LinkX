//
//  ViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 3/22/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var emailsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var topBarButton: UIButton!
    @IBOutlet var filterSegment: UISegmentedControl!
    
    var investors = [Investor]()
    var filteredInvestors = [Investor]()
    var filteredFunds = [Fund]()
    var selectedInvestor: Investor?
    var selectedFund: Fund?
    var tableButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "InvestorTableViewCell", bundle: nil), forCellReuseIdentifier: "InvestorTableViewCell")
        tableView.register(UINib(nibName: "FundTableViewCell", bundle: nil), forCellReuseIdentifier: "FundTableViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        tableButton.setBackgroundImage(UIImage(named: "link-icon")!, for: .normal)
        tableView.backgroundView = tableButton//UIImageView(image: UIImage(named: "link-icon")!)
        tableButton.addTarget(self, action: #selector(ViewController.tableButtonTouched), for: .touchUpInside)
        updateBackground()
        
        // Setup the Search Controller
        searchBar.delegate = self
        searchBar.isHidden = false
        
        AppStore.shared.showReview()
        
//        fetchAllFunds(completion: { (funds) in
//            print("got funds: \(funds.count)")
//        }) { (error) in
//            print(error.localizedDescription)
//        }
        
        self.filterContentForSearchText("")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableButton.frame = tableView.frame
    }
    
    @IBAction func topBarTouched(_ sender: Any) {
        Analytics.logEvent("top_bar_touched", parameters: [:])

        if searchBar.text == nil || searchBar.text!.isEmpty {
            searchBar.resignFirstResponder() //if no search text, and the user is tapping the top bar, dismiss
        }
    }
    
    @IBAction func filterChanged(_ sender: Any) {
        searchBar.placeholder = filterSegment.selectedSegmentIndex == 0 ? "Search investors by name" : "Search funds by name"
        self.filterContentForSearchText("")
    }
    
    @objc
    public func tableButtonTouched() {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Private instance methods
    
    func fetchFunds(text: String, completion: @escaping ([Fund]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("funds")
        
        Analytics.logEvent("fetch_funds", parameters: ["text" : text])
        
        //.queryEnding(atValue: text.lowercased() + "\u{f8ff}")
        ref.queryOrdered(byChild: "name_search").queryStarting(atValue: text.lowercased()).queryEnding(atValue: text.lowercased() + "\u{f8ff}").queryLimited(toFirst: 10)
            .observeSingleEvent(of: .value, with: { snapshot in
                guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                    completion([])
                    return
                }
                
                var newFunds = [Fund]()
                
                for child in children {
                    if var value = child.value as? [String : Any] {
                        print(value)
                        value["key"] = child.key
                        newFunds.append(Fund(data: value))
                    }
                }
                
                Analytics.logEvent("fetch_funds_success", parameters: ["text" : text, "result_count" : newFunds.count])
                completion(newFunds)
                return
            }){ (err) in
                Analytics.logEvent("fetch_funds_error", parameters: ["description" : err.localizedDescription])
                
                print("Failed to fetch funds:", err)
                cancel?(err)
        }
    }
    
    func fetchInvestors(text: String, completion: @escaping ([Investor]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("investors")
        
        Analytics.logEvent("fetch_investors", parameters: ["text" : text])

        //.queryEnding(atValue: text.lowercased() + "\u{f8ff}")
        ref.queryOrdered(byChild: "name_search").queryStarting(atValue: text.lowercased()).queryEnding(atValue: text.lowercased() + "\u{f8ff}").queryLimited(toFirst: 10)
            .observeSingleEvent(of: .value, with: { snapshot in
                guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                    completion([])
                    return
                }

                var newInvestors = [Investor]()
                
                for child in children {
                    if var value = child.value as? [String : Any] {
                        print(value)
                        value["key"] = child.key
                        newInvestors.append(Investor(data: value))
                    }
                }
                
                Analytics.logEvent("fetch_investors_success", parameters: ["text" : text, "result_count" : newInvestors.count])
                completion(newInvestors)
                return
            }){ (err) in
                Analytics.logEvent("fetch_investors_error", parameters: ["description" : err.localizedDescription])

                print("Failed to fetch investors:", err)
                cancel?(err)
        }
    }
    
    func fetchAllFunds(completion: @escaping ([Fund]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("funds")
        
        Analytics.logEvent("fetch_all_funds", parameters: [:])
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                completion([])
                return
            }
            
            var newFunds = [Fund]()
            for child in children {
                if var value = child.value as? [String : Any] {
                    if  value["sector_search"] == nil {
                        guard let sectors = value["sectors"] as? [String] else {
                            return //sectors doesn't exist
                        }
                        
                        var sectorSearch = ""
                        sectors.forEach { sector in
                            if sector != sectors.first {
                                sectorSearch.append(" ")
                            }
                            
                            sectorSearch.append(sector.lowercased())
                        }
                        value["sector_search"] = sectorSearch
                        Database.database().reference().child("funds").child(child.key).setValue(value)
                    }
                    
                    if  value["stage_search"] != nil {
                        guard let stages = value["stage"] as? [String] else {
                            return
                        }
                        
                        var stageSearch = ""
                        stages.forEach { stage in
                            if stage != stages.first {
                                stageSearch.append(" ")
                            }
                            
                            stageSearch.append(stage.lowercased())
                        }
                        
                        value["stage_search"] = stageSearch
                        Database.database().reference().child("funds").child(child.key).setValue(value)
                    }
                    
                    if value["name_search"] == nil {
                        if let name = value["name"] as? String {
                            value["name_search"] = name.lowercased()
                            Database.database().reference().child("funds").child(child.key).setValue(value)
                        }
                    }
                    
                    newFunds.append(Fund(data: value))
                    //newInvestors.append(Investor(data: value))
                }
            }
            
            Analytics.logEvent("fetch_all_investors_success", parameters: [:])
            
            completion(newFunds)
        }) { (err) in
            Analytics.logEvent("fetch_all_investors_error", parameters: ["description" : err.localizedDescription])
            
            print("Failed to fetch funds:", err)
            cancel?(err)
        }
    }
    
    func updateBackground() {
        if filteredInvestors.count < 1 {
            tableView.backgroundView = tableButton//UIImageView(image: UIImage(named: "link-icon")!)
        } else {
            tableView.backgroundView = nil
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        if filterSegment.selectedSegmentIndex == 0 {
            fetchInvestors(text: searchText, completion: { (investors) in
                DispatchQueue.main.async {
                    self.filteredInvestors = investors
                    
                    self.updateBackground()
                    self.tableView.reloadData()
                }
            }) { error in
                //TODO: handle error
            }
        } else if filterSegment.selectedSegmentIndex == 1 {
            fetchFunds(text: searchText, completion: { (funds) in
                DispatchQueue.main.async {
                    self.filteredFunds = funds
                    
                    self.updateBackground()
                    self.tableView.reloadData()
                }
            }) { error in
                //TODO: handle error
            }
        }
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchBar.selectedScopeButtonIndex != 0
        return searchBar.isFocused && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if filterSegment.selectedSegmentIndex == 0 {
            guard let investor = selectedInvestor else {
                return
            }
            
            if segue.identifier == "ShowEmailFromDiscover" {
                let evc = segue.destination as! EmailViewController
                evc.investor = investor
                evc.onSigninTouched = { vc in
                    self.tabBarController?.selectedIndex = 2
                    vc.dismiss(animated: true, completion: nil)
                }
            }
        } else if filterSegment.selectedSegmentIndex == 1 {
            guard let fund = selectedFund else {
                return
            }
            
            if segue.identifier == "ShowFundFromDiscover" {
                let evc = segue.destination as! FundViewController
                evc.fund = fund
                evc.onSigninTouched = { vc in
                    self.tabBarController?.selectedIndex = 2
                    vc.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension ViewController {
    // MARK: - Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return filterSegment.selectedSegmentIndex == 0 ? 104.0 : 100.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterSegment.selectedSegmentIndex == 0 ? filteredInvestors.count : filteredFunds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if filterSegment.selectedSegmentIndex == 0 {
            guard let cell =
                tableView.dequeueReusableCell(withIdentifier: "InvestorTableViewCell", for: indexPath) as? InvestorTableViewCell else {
                    return UITableViewCell()
            }
            
            cell.configure(investor: filteredInvestors[indexPath.row])
            return cell
        } else {
            guard let cell =
                tableView.dequeueReusableCell(withIdentifier: "FundTableViewCell", for: indexPath) as? FundTableViewCell else {
                    return UITableViewCell()
            }
            
            cell.configure(fund: filteredFunds[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if filterSegment.selectedSegmentIndex == 0 {
            guard indexPath.row < filteredInvestors.count else {
                return
            }
            
            selectedInvestor = filteredInvestors[indexPath.row]
            
            Analytics.logEvent("selected_investor", parameters: ["id" : selectedInvestor?.id ?? "", "name" : selectedInvestor?.fullName() ?? "", "firm" : selectedInvestor?.firm ?? ""])
            
            performSegue(withIdentifier: "ShowEmailFromDiscover", sender: self)
        } else {
            guard indexPath.row < filteredFunds.count else {
                return
            }
            
            selectedFund = filteredFunds[indexPath.row]
            
            Analytics.logEvent("selected_investor", parameters: ["id" : selectedFund?.id ?? "", "name" : selectedFund?.name ?? ""])
            performSegue(withIdentifier: "ShowFundFromDiscover", sender: self)
        }
    }
}

extension ViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension ViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

//    var allInvestorData = [[String : Any]]()
//    for investor in newInvestors {
//    allInvestorData.append(self.investorInfo(investor: investor))
//    }
//    self.printInvestors(investors: allInvestorData)
//
//    func investorInfo(investor: Investor) -> [String : Any] {
//        var metadata = investor.metadata
//        let contactInfo = [
//            "email": metadata["Email"] ?? "",
//            "city": metadata["City"] ?? "",
//            "state": metadata["State"] ?? ""
//        ]
//
//        let investorInfo: [String : Any] = [
//            "first": metadata["First"] ?? "",
//            "last": metadata["Last"] ?? "",
//            "title": metadata["Title"] ?? "",
//            "firm": metadata["Firm"] ?? "",
//            "contact_info": contactInfo
//        ]
//
//        return investorInfo
//    }
//
//    func printInvestors(investors: [[String : Any]]) {
//        let metadata = ["investors" : investors]
//
//        // Serialize to JSON
//        let jsonData = try! JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted])
//
//        // Convert to a string and print
//        if let JSONString = String(data: jsonData, encoding: String.Encoding.ascii) {
//            print(JSONString)
//        }
//    }

