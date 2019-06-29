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
    
    var investors = [Investor]()
    var filteredInvestors = [Investor]()
    var selectedInvestor: Investor?
    var tableButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "InvestorTableViewCell", bundle: nil), forCellReuseIdentifier: "InvestorTableViewCell")
        
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
        
//        fetchAllInvestors(completion: { investors in
//            self.investors = investors
//            self.filterContentForSearchText("")
//            self.searchBar.isHidden = false
//        }) { error in
//            print(error.localizedDescription)
//        }
//
        self.filterContentForSearchText("")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableButton.frame = tableView.frame
    }
    
    @IBAction func topBarTouched(_ sender: Any) {
        if searchBar.text == nil || searchBar.text!.isEmpty {
            searchBar.resignFirstResponder() //if no search text, and the user is tapping the top bar, dismiss
        }
    }
    
    @objc
    public func tableButtonTouched() {
        searchBar.resignFirstResponder()
    }
    
    func checkEmails() {
        if IAPHandler.shared.shouldReset() {
            IAPHandler.shared.setEmails(0)
        }
        
        let emails = IAPHandler.shared.getEmailCount()
        if emails > 4 {
            emailsLabel.text = "0 Emails Available"
        } else {
            emailsLabel.text =  "\(5 - emails) Emails Available"
        }
    }
    
    // MARK: - Private instance methods
    
    func fetchInvestors(text: String, completion: @escaping ([Investor]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("investors")

        //.queryEnding(atValue: text.lowercased() + "\u{f8ff}")
        ref.queryOrdered(byChild: "name_search").queryStarting(atValue: text.lowercased()).queryEnding(atValue: text.lowercased() + "\u{f8ff}").queryLimited(toFirst: 25)
            .observeSingleEvent(of: .value, with: { snapshot in
                guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                    completion([])
                    return
                }

                var newInvestors = [Investor]()
                
                for child in children {
                    if var value = child.value as? [String : Any] {
                        print(value)
                        newInvestors.append(Investor(data: value))
                    }
                }
                
                completion(newInvestors)
                return
            }){ (err) in
                print("Failed to fetch investors:", err)
                cancel?(err)
        }
    }
    
    func fetchAllInvestors(completion: @escaping ([Investor]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("investors")
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                completion([])
                return
            }
            
            var newInvestors = [Investor]()
            for child in children {
                if var value = child.value as? [String : Any] {
                    if  value["name_search"] == nil { //let nameSearch = value["name_search"] as? [String] {
                        guard let first = value["first"] as? String, let last = value["last"] as? String else {
                            return //first and last name don't exist
                        }

                        value["name_search"] = "\(first.lowercased()) \(last.lowercased())"
                        Database.database().reference().child("investors").child(child.key).setValue(value)
                    }
                    
                    //newInvestors.append(Investor(data: value))
                }
            }
            
            completion(newInvestors)
        }) { (err) in
            print("Failed to fetch investors:", err)
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
        fetchInvestors(text: searchText, completion: { (investors) in
            DispatchQueue.main.async {
                self.filteredInvestors = investors
                
                self.updateBackground()
                self.tableView.reloadData()
            }
        }) { error in
            //TODO: handle error
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
        return 104.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredInvestors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
            tableView.dequeueReusableCell(withIdentifier: "InvestorTableViewCell", for: indexPath) as? InvestorTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(investor: filteredInvestors[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filteredInvestors.count else {
            return
        }
        
        selectedInvestor = filteredInvestors[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        performSegue(withIdentifier: "ShowEmailFromDiscover", sender: self)
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

