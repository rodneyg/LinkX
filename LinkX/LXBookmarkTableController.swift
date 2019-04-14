//
//  LXBookmarkTableController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 4/13/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//


import Foundation
import UIKit
import Firebase
import CoreData

class BookmarkTableController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var investors = [LXInvestor]()
    var filteredInvestors = [LXInvestor]()
    var selectedInvestor: LXInvestor?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "InvestorTableViewCell", bundle: nil), forCellReuseIdentifier: "InvestorTableViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundView = UIImageView(image: UIImage(named: "link-icon")!)
        updateBackground()
        
        // Setup the Search Controller
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchAllInvestors(completion: { investors in
            self.investors = investors
            self.tableView.reloadData()
            
            self.filterContentForSearchText("")
        })
    }
    
    // MARK: - Private instance methods
    
    public func fetchAllInvestors(completion: @escaping ([LXInvestor]) -> ()) {
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LXInvestor")
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            guard let investors = result as? [LXInvestor] else {
                return //TODO: handle no investors found
            }
            
            completion(investors)
        } catch {
            print("Failed to fetch investors") //TODO: handle this error
        }
    }

    func updateBackground() {
        if filteredInvestors.count < 1 {
            tableView.backgroundView = UIImageView(image: UIImage(named: "link-icon")!)
        } else {
            tableView.backgroundView = nil
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredInvestors = investors.filter({( investor: LXInvestor) -> Bool in
            return investor.fullName().lowercased().starts(with: searchText.lowercased())
        })
        
        updateBackground()
        tableView.reloadData()
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
        
        if segue.identifier == "ShowEmailFromBookmarks" {
            let emailVC = segue.destination as! EmailViewController
            emailVC.investor = convertStoredInvestor(stored: investor)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension BookmarkTableController {
    public func convertStoredInvestor(stored: LXInvestor) -> Investor? {
        guard let id = stored.id, let first = stored.first, let last = stored.last, let city = stored.city, let firm = stored.firm, let state = stored.state, let title = stored.title, let email = stored.email, let metadata = stored.metadata else {
            return nil
        }
        
        let contactInfo = ["email" : email, "city" : city, "state" : state]
        let investorData = ["first" : first, "last" : last, "firm" : firm, "title" : title, "contact_info" : contactInfo, "metadata" : metadata] as [String : Any]
        
        return Investor(id: id, data: investorData)
    }
}

extension BookmarkTableController {
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
        
        cell.configure(storedInvestor: filteredInvestors[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filteredInvestors.count else {
            return
        }
        
        selectedInvestor = filteredInvestors[indexPath.row]
        
        searchBar.resignFirstResponder()
        tableView.deselectRow(at: indexPath, animated: false)
        
        performSegue(withIdentifier: "ShowEmailFromBookmarks", sender: self)
    }
}

extension BookmarkTableController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension BookmarkTableController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
