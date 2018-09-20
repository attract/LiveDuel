//
//  LoginViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 07.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

class LoginViewController: BaseViewController, UITextViewDelegate {

    @IBOutlet weak var sloganLabel: UILabel!
    @IBOutlet weak var loginFacebookButton: UIButton!
    @IBOutlet weak var loginPhoneButton: UIButton!
    @IBOutlet weak var legalInfoTextView: UITextView!
    
    // MARK: - Buttons actions
    
    @IBAction func loginFacebookButtonTap(_ sender: Any) {
        FacebookCore.SDKSettings.appId = Config.shared.data["facebook.client_id"]!
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile], viewController: self, completion: { (loginResult) in
            switch loginResult {
            case .success(grantedPermissions: _, declinedPermissions: _, token: let token):
                self.login("facebook", token.userId!, token.authenticationToken)
                break;
            default:
                break;
            }
        })
    }
    
    @IBAction func loginPhoneButtonTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Phone") as! PhoneViewController
        let navigationController = UINavigationController(rootViewController: controller)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - Login
    
    func login(_ type: String, _ id: String, _ verification: String)
    {
        API.login(type, id, verification, loginSuccess, failure)
    }
    
    func loginSuccess(_ data: NSDictionary)
    {
        let player = Player(data: data)
        Misc.currentPlayer = player
        
        // if no username provided - show profile editor
        if(Misc.currentPlayer?.username == nil)
        {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "Profile") as! ProfileViewController
            let navigationController = UINavigationController(rootViewController: controller)
            self.present(navigationController, animated: true, completion: nil)
        }
        // show main screen otherwise
        else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "WebView") as! WebViewController
        
        if URL.absoluteString == Misc.docUrl("terms")
        {
            controller.docTitle = NSLocalizedString("tr_terms_of_use", comment: "")
        }
        else if URL.absoluteString == Misc.docUrl("privacy")
        {
            controller.docTitle = NSLocalizedString("tr_privacy_policy", comment: "")
        }
        else if URL.absoluteString == Misc.docUrl("rules")
        {
            controller.docTitle = NSLocalizedString("tr_rules", comment: "")
        }
        
        controller.docUrl = URL
        
        let navigationController = UINavigationController(rootViewController: controller)
        self.present(navigationController, animated: true, completion: nil)
        
        return false
    }
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView()
    {
        // handle all translations
        sloganLabel.text = NSLocalizedString("tr_slogan", comment: "")
        loginFacebookButton.setTitle(NSLocalizedString("tr_login_via_facebook", comment: ""), for: .normal)
        loginPhoneButton.setTitle(NSLocalizedString("tr_login_via_phone", comment: ""), for: .normal)
        
        // design
        sloganLabel.textColor = UIColor(cfgName: "colors.text")
        loginFacebookButton.backgroundColor = UIColor(cfgName: "colors.login.button.background")
        loginFacebookButton.setTitleColor(UIColor.white, for: .normal)
        loginPhoneButton.backgroundColor = UIColor(cfgName: "colors.login.button.background")
        loginPhoneButton.setTitleColor(UIColor(cfgName: "colors.login.button.text"), for: .normal)
        
        let termsOfUse = NSLocalizedString("tr_terms_of_use", comment: "")
        let privacyPolicy = NSLocalizedString("tr_privacy_policy", comment: "")
        let rules = NSLocalizedString("tr_rules", comment: "")
        let legalMsg = String(format: NSLocalizedString("tr_accept_terms", comment: ""), termsOfUse, privacyPolicy, rules)
        let legalMsgAttributed = NSMutableAttributedString(string: legalMsg)
        
        let range = NSRange(location: 0, length: legalMsgAttributed.length)
        
        let linkAttributes: [String : Any] = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor(cfgName: "colors.text").withAlphaComponent(0.5),
            NSAttributedStringKey.underlineColor.rawValue: UIColor(cfgName: "colors.text").withAlphaComponent(0.5),
            NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue
        ]
        
        legalMsgAttributed.setCentered()
        legalMsgAttributed.addAttribute(.foregroundColor, value: UIColor(cfgName: "colors.text"), range: range)
        legalMsgAttributed.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0), range: range)
        legalMsgAttributed.setLink(termsOfUse, Misc.docUrl("terms"))
        legalMsgAttributed.setLink(privacyPolicy, Misc.docUrl("privacy"))
        legalMsgAttributed.setLink(rules, Misc.docUrl("rules"))
        
        legalInfoTextView.linkTextAttributes = linkAttributes
        legalInfoTextView.attributedText = legalMsgAttributed
        legalInfoTextView.delegate = self
    }
    
    
}

