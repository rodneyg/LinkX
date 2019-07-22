//
//  AddPostViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import SwiftLinkPreview
import PKHUD
import Firebase
import FirebaseDatabase

class AddPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var postButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    
    @IBOutlet var titleField: UITextField!
    @IBOutlet var websiteField: UITextField!
    
    @IBOutlet var tableView: UITableView!
    
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    let slp = SwiftLinkPreview(session:  URLSession.shared,
                               workQueue:  SwiftLinkPreview.defaultWorkQueue,
                               responseQueue: DispatchQueue.main,
                               cache: DisabledCache.instance)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "PostTableViewCell")
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func postTouched(_ sender: Any) {
        if posts.count > 0 {
            submitPost()
            return
        }
        
        view.endEditing(true)
        HUD.show(.progress)
        
        slp.previewLink(websiteField.text!, onSuccess: { data in
            var post = Post(data: data)
            post.url = self.websiteField.text
            post.createdAt = Date().timeIntervalSince1970
            post.finalUrl = data["finalUrl"] as? String
            post.canonicalUrl = data["canonicalUrl"] as? String
            post.uid = Auth.auth().currentUser?.uid
            self.posts = [post]
            
            self.submitPost()
        }) { error in
            HUD.flash(.labeledError(title: "Error Generating", subtitle: error.localizedDescription))
            print(error)
        }
    }
    
    func submitPost() {
        guard let post = posts.first else {
            return
        }
        
        Database.database().createPost(withPost: post) { error in
            if let error = error {
                HUD.flash(.labeledError(title: "Error Posting", subtitle: error.localizedDescription), delay: 3.5)
                return
            }
                        
            HUD.hide()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func generateTouched(_ sender: Any) {
        view.endEditing(true)
        HUD.show(.progress)
        
        slp.previewLink(websiteField.text!, onSuccess: { data in
            HUD.hide()
            var post = Post(data: data)
            post.url = self.websiteField.text
            post.createdAt = Date().timeIntervalSince1970
            post.finalUrl = data["finalUrl"] as? String
            post.canonicalUrl = data["canonicalUrl"] as? String
            post.uid = Auth.auth().currentUser?.uid
            self.posts = [post]
        }) { error in
            HUD.flash(.labeledError(title: "Error Generating", subtitle: error.localizedDescription))
            print(error)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 301.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
            tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as? PostTableViewCell else {
                return UITableViewCell()
        }
        
        cell.configure(post: posts[indexPath.row])
        return cell
    }
}
