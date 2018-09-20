//
//  ProfileViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 12.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class ProfileViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var avatarImageView: RoundedImageView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var rulesLabel: UILabel!
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView()
    {
        // setup colors
        view.backgroundColor = UIColor(cfgName: "colors.system.background")
        infoLabel.textColor = UIColor(cfgName: "colors.system.text")
        rulesLabel.textColor = UIColor(cfgName: "colors.system.text")
        
        // fill in labels
        self.title = NSLocalizedString("tr_profile", comment: "")
        infoLabel.text = NSLocalizedString("tr_profile_info", comment: "")
        usernameField.placeholder = NSLocalizedString("tr_choose_username", comment: "")
        rulesLabel.text = NSLocalizedString("tr_username_rules", comment: "")
        
        // load avatar
        Misc.currentPlayer?.setAvatar(avatarImageView)
        
        // enable tap on avatar to show menu
        avatarImageView.isUserInteractionEnabled = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showAvatarMenu))
        avatarImageView.addGestureRecognizer(tap)
        
        // navigation buttons
        navigationItem.setHidesBackButton(true, animated: false)
        swithNavButton("done")
        
        // add "close on tap" functionality
        let closeTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(closeTap)
    }
    
    // MARK: - Profile
    
    @objc func saveProfile()
    {
        dismissKeyboard()
        swithNavButton("loading")
        API.profile(self.usernameField.text!, profileSuccess, failure)
    }
    
    @objc func profileSuccess(_ data: NSDictionary)
    {
        swithNavButton("done")
        // update player info
        var player = Misc.currentPlayer!
        player.token = data["token"] as? String
        player.username = data["username"] as? String
        // save as current player
        Misc.currentPlayer = player
        // switch to main screen
        self.presentingViewController?.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
    func swithNavButton(_ to: String)
    {
        if(to == "loading")
        {
            let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            activityIndicator.activityIndicatorViewStyle = .gray
            let barButton = UIBarButtonItem(customView: activityIndicator)
            navigationItem.setRightBarButton(barButton, animated: true)
            activityIndicator.startAnimating()
        } else if (to == "done") {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveProfile))
        }
    }
    
    // MARK: - Avatar
    
    @objc func showAvatarMenu()
    {
        dismissKeyboard()
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_new_photo", comment: ""), style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_camera_roll", comment: ""), style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        
        if(Misc.currentPlayer?.avatar != nil)
        {
            alert.addAction(UIAlertAction(title: NSLocalizedString("tr_delete_avatar", comment: ""), style: .default, handler: { (action) in
                API.avatar(nil, self.uploadSuccess, self.failure)
            }))
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_cancel", comment: ""), style: .cancel, handler: { (action) in
            // do nothing, it's cancelled
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // show loading indicator
        let center = avatarImageView.frame.width / 2 - 10
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: center, y: center, width: 20, height: 20))
        activityIndicator.activityIndicatorViewStyle = .white
        activityIndicator.tag = 99
        avatarImageView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // upload image
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        API.avatar(imageData!, uploadSuccess, failure)
        dismiss(animated:true, completion: nil)
    }
    
    func uploadSuccess(_ data: NSDictionary)
    {
        // remove loading indicator
        avatarImageView.viewWithTag(99)?.removeFromSuperview()
        
        // update player info
        var player = Misc.currentPlayer!
        player.token = data["token"] as? String
        player.avatar = data["avatar"] as? String
        // save as current player
        Misc.currentPlayer = player
        // update preview
        Misc.currentPlayer?.setAvatar(avatarImageView, refresh: true)
    }
    
    override func failure(_ status: Int, _ errors: [String]) {
        // remove loading indicator
        avatarImageView.viewWithTag(99)?.removeFromSuperview()
        swithNavButton("done")
        
        super.failure(status, errors)
    }
    
    // MARK: - Events
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
