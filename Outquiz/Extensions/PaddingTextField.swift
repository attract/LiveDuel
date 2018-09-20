//
//  PaddedTextField.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 17.04.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class PaddingTextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16);
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }

}
