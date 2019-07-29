//
//  PostTableViewCell.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol PostCellDelegate {
    func shareTouched(post: Post, image: UIImage)
    func skepticalTouched(post: Post)
    func shockedTouched(post: Post)
    func clapTouched(post: Post)
    func bookmarkTouched(post: Post)
    func optionsTouched(post: Post)
    func profileTouched(user: User)
}

class PostTableViewCell: UITableViewCell {

    @IBOutlet var profileImage: CustomImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var postImage: CustomImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var sourceLabel: UILabel!
    @IBOutlet var iconImage: CustomImageView!
    @IBOutlet var iconWidth: NSLayoutConstraint!
    
    @IBOutlet var postImageHeight: NSLayoutConstraint!
    @IBOutlet var clapButton: UIButton!
    @IBOutlet var shockedButton: UIButton!
    @IBOutlet var skepticalButton: UIButton!
    @IBOutlet var bookmarkButton: UIButton!
    @IBOutlet var shareButton: UIButton!
    @IBOutlet var optionsButton: UIButton!
    
    @IBOutlet var cardView: UIView!
    
    @IBOutlet var reactionView: UIView!
    
    var delegate: PostCellDelegate?
    var post: Post?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func sharedInit() {
        clapButton.addTarget(self, action: #selector(handleClap), for: .touchUpInside)
        shockedButton.addTarget(self, action: #selector(handleShocked), for: .touchUpInside)
        skepticalButton.addTarget(self, action: #selector(handleSkeptical), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        optionsButton.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfile))
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(tapGesture)
        
        usernameLabel.addGestureRecognizer(tapGesture)
        usernameLabel.isUserInteractionEnabled = true
        
        profileImage.addGestureRecognizer(tapGesture)
        profileImage.isUserInteractionEnabled = true
    }
    
    @objc func handleProfile() {
        guard let post = post, let user = post.user else { return }
        delegate?.profileTouched(user: user)
    }
    
    @objc func handleOptions() {
        guard let post = post else { return }
        delegate?.optionsTouched(post: post)
    }
    
    @objc func handleShocked() {
        guard let post = post else { return }
        delegate?.shockedTouched(post: post)
    }
    
    @objc func handleBookmark() {
        guard let post = post else { return }
        delegate?.bookmarkTouched(post: post)
    }
    
    @objc func handleSkeptical() {
        guard let post = post else { return }
        delegate?.skepticalTouched(post: post)
    }
    
    @objc func handleShare() {
        guard let post = post, let background = self.contentView.superview else { return }
        delegate?.shareTouched(post: post, image: background.asImage())
    }
    
    @objc func handleClap() {
        guard let post = post else { return }
        delegate?.clapTouched(post: post)
    }
    
    public func configure(postId: String) {
        Database.database().fetchPost(postId: postId, completion: { (post) in
            self.configure(post: post)
        })
    }
    
    public func configure(post: Post) {
        sharedInit()

        self.post = post
        
        shareButton.isHidden = post.publicUrl == nil
        
        if let user = post.user {
            usernameLabel.text = "\(user.firstName) \(user.lastName)"
        }
        
        clapButton.setTitle("👏 \(post.claps)", for: .normal)
        shockedButton.setTitle("🤯 \(post.shocked)", for: .normal)
        skepticalButton.setTitle("🤔 \(post.skeptical)", for: .normal)
        
        if let createdAt = post.createdAt {
            let timeAgo = Date(timeIntervalSince1970: createdAt).timeAgoDisplay()
            timeLabel.text = "\(timeAgo)"
        }
        
        if let user = post.user, let profileImageUrl = user.profileImageUrl {
            profileImage.loadImage(urlString: profileImageUrl)
        }
        
        if let image = post.image, !image.isEmpty {
            DispatchQueue.main.async {
                self.postImage.loadImage(urlString: image)
            }
        } else {
            postImageHeight.constant = 0
        }
        
        if let title = post.title {
            titleLabel.text = title
        }
        
        if let canonical = post.canonicalUrl {
            sourceLabel.text = canonical
        }
        
        if let icon = post.icon, !icon.isEmpty {
            DispatchQueue.main.async {
                self.iconImage.loadImage(urlString: icon)
            }
        } else {
            iconWidth.constant = 0
        }
        
        setProfileImage()
        setCardView()
    }
    
    func setProfileImage() {
        profileImage.contentMode = .scaleAspectFill
        profileImage.clipsToBounds = true
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        profileImage.layer.cornerRadius = 32 / 2.0
        profileImage.isUserInteractionEnabled = true
    }
    
    func setCardView() {
        cardView.layer.cornerRadius = 15.0
        cardView.layer.shadowColor = UIColor.darkGray.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        cardView.layer.shadowRadius = 10.0
        cardView.layer.shadowOpacity = 0.7
        cardView.layer.masksToBounds = true
    }
}
