//
//  ChatMessage.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 26.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit
import Kingfisher

struct ChatMessage {
    
    let userId: Int
    let username: String
    let avatar: String?
    let message: String
    
    init(_ message: String, _ user: NSDictionary)
    {
        userId = user["id"] as! Int
        username = user["username"] as! String
        avatar = user["avatar"] as? String
        self.message = message
    }
    
    func setAvatar(_ imageView: UIImageView)
    {
        let anon = UIImage(named: "avatar")
        if(self.avatar != nil)
        {
            let cache = DummyCache(name: "default")
            let options = [KingfisherOptionsInfoItem.targetCache(cache), KingfisherOptionsInfoItem.forceRefresh]
            imageView.kf.setImage(with: URL(string: self.avatar!), placeholder: anon, options: options)
        } else {
            imageView.image = anon
        }
    }
    
    func getAttributedString() -> NSAttributedString
    {
        let msg = NSMutableAttributedString(string: self.message)
        msg.setFont(self.message, UIFont.systemFont(ofSize: 18.0))
        msg.setColor(self.message, UIColor(cfgName: "colors.chat.text"))
        
        let res = NSMutableAttributedString(string: self.username)
        res.setFont(self.username, UIFont.boldSystemFont(ofSize: 18.0))
        res.setColor(self.username, UIColor(cfgName: "colors.chat.username"))
        res.append(NSAttributedString(string: " "))
        res.append(msg)
        
        return res
    }
    
}
