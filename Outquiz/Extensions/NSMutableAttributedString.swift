//
//  NSMutableAttributedString+Extension.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 09.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    
    public func setLink(_ textToFind:String, _ linkURL:String) {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
        }
    }
    
    public func setFont(_ textToFind:String, _ font:UIFont) {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.font, value: font, range: foundRange)
        }
    }
    
    public func setColor(_ textToFind:String, _ color:UIColor) {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.foregroundColor, value: color, range: foundRange)
        }
    }
    
    public func setCentered()
    {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        let range = NSRange(location: 0, length: self.mutableString.length)
        self.addAttribute(.paragraphStyle, value: style, range: range)
    }
    
}
