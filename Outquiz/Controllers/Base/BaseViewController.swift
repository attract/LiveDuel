//
//  BaseViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 10.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // move view when keyboard opens
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // colorize background
        view.viewWithTag(999)?.backgroundColor = UIColor(cfgName: "colors.background")
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let current = view.getSelectedTextField()
        
        // is it not visible?
        if(current != nil)
        {
            let frame = self.view.convert(current!.frame, from: current!.superview)
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let space = CGFloat(16.0)
                let diff = ((self.view.frame.height - keyboardSize.height - space) - (frame.origin.y + frame.height))
                if(diff < 0)
                {
                    self.view.frame.origin.y = diff
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    func failure(_ status: Int, _ errors: [String])
    {
        self.showErrors(errors: errors)
    }
    
    func showErrors(errors: [String])
    {
        if(!errors.isEmpty)
        {
            let error = errors[0]
            let alert = UIAlertController(title: NSLocalizedString("tr_error", comment: ""), message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("tr_ok", comment: ""), style: .default, handler: {(alert: UIAlertAction!) in
                var copyerrors = errors
                copyerrors.remove(at: 0)
                self.showErrors(errors: copyerrors)
            }))
            self.present(alert, animated: true)
        }
        
    }
    
}
