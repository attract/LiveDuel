//
//  PhoneCodeViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 12.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class PhoneCodeViewController: BaseViewController, CodeInputViewDelegate {
    
    @IBOutlet weak var infoText: UITextView!
    @IBOutlet weak var resendLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var codeView: UIView!
    
    // MARK: - Properties
    // resend timer
    let defaultResendTime = 30
    var resendTime = 30
    var timer: Timer?
    // phone in proper format
    var phone: String?
    // original input - for resend function
    var country: String?
    var number: String?
    // code input widget
    var codeInputView: CodeInputView?
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        codeInputView?.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if codeView.viewWithTag(77) == nil
        {
            // generate code input field
            codeInputView = CodeInputView(frame: CGRect(x: 0, y: 0, width: codeView.frame.width, height: codeView.frame.height))
            codeInputView!.tag = 77
            codeInputView!.delegate = self
            codeView.addSubview(codeInputView!)
            codeInputView!.becomeFirstResponder()
        }
    }
    
    func configureView()
    {
        // setup colors
        view.backgroundColor = UIColor(cfgName: "colors.system.background")
        infoText.textColor = UIColor(cfgName: "colors.system.text")
        resendLabel.textColor = UIColor(cfgName: "colors.system.text")
        resendButton.setTitleColor(UIColor(cfgName: "colors.system.button.text"), for: .normal)
        resendButton.backgroundColor = UIColor(cfgName: "colors.system.button.background")
        
        // fill in labels
        self.title = NSLocalizedString("tr_verify", comment: "")
        let info = NSMutableAttributedString(string: NSLocalizedString("tr_phone_code_info", comment: ""))
        info.append(NSAttributedString(string: "\n"))
        info.append(NSAttributedString(string: self.phone!))
        info.setCentered()
        info.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0), range: NSRange(location: 0, length: info.length))
        infoText.attributedText = info
        resendButton.setTitle(NSLocalizedString("tr_resend_code", comment: ""), for: .normal)
        
        // start resend countdown
        startTimer()
    }
    
    // MARK: - Timer
    
    func startTimer() {
        resendButton.isHidden = true
        resendLabel.isHidden = false
        resendTime = defaultResendTime
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimer), userInfo: nil, repeats: true)
        runTimer()
    }
    
    func stopTimer() {
        timer?.invalidate()
        resendLabel.isHidden = true
        resendButton.isHidden = false
    }
    
    @objc func runTimer() {
        let minutes = floor(Double(resendTime)/60.0)
        let seconds = resendTime%60
        let time = String(format:"%02d:", minutes) + String(format:"%02d", seconds)
        resendLabel.text = String(format:NSLocalizedString("tr_resend_code_time", comment: ""), time)
        
        if(resendTime <= 0)
        {
            stopTimer()
        }
        resendTime = resendTime - 1
    }
    
    // MARK: - Code Verification
    
    func codeInputView(_ codeInputView: CodeInputView, didFinishWithCode code: String) {
        
        // show loading indicator
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.activityIndicatorViewStyle = .gray
        let barButton = UIBarButtonItem(customView: activityIndicator)
        navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
        
        API.login("phone", phone!, code, codeSuccess, failure)
    }
    
    func codeSuccess(_ data: NSDictionary)
    {
        // hide loading indicator
        navigationItem.setRightBarButton(nil, animated: true)
        
        let player = Player(data: data)
        Misc.currentPlayer = player
        
        // this is a new player - edit profile
        if(Misc.currentPlayer?.username == nil)
        {
            self.performSegue(withIdentifier: "CodeToProfile", sender: self)
        }
        // show home otherwise
        else {
            self.presentingViewController?.presentingViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    override func failure(_ status: Int, _ errors: [String]) {
        super.failure(status, errors)
        // hide loading indicator
        navigationItem.setRightBarButton(nil, animated: true)
    }
    
    // MARK: - Resend Code
    
    @IBAction func resendButtonTap(_ sender: Any) {
        API.verify(country!, number!, phoneSuccess, failure)
    }
    
    func phoneSuccess(_ data: NSDictionary)
    {
        startTimer()
    }
    
    
}
