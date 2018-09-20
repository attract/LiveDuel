//
//  Player.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 10.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit
import Kingfisher

struct Player {
    
    let id: Int
    var token, username, avatar, referral: String?
    
    init(data: NSDictionary)
    {
        self.id = data["id"] as! Int
        
        let token = data["token"] as? String
        let username = data["username"] as? String
        let avatar = data["avatar"] as? String
        let referral = data["referral"] as? String
        
        self.token = (token ?? "").isEmpty ? nil : token
        self.username = (username ?? "").isEmpty ? nil : username
        self.avatar = (avatar ?? "").isEmpty ? nil : avatar
        self.referral = (referral ?? "").isEmpty ? nil : referral
    }
    
    init(id: Int, username: String?, avatar: String?)
    {
        self.id = id
        self.username = (username ?? "").isEmpty ? nil : username
        self.avatar = (avatar ?? "").isEmpty ? nil : avatar
    }
    
    func setAvatar(_ imageView: UIImageView, refresh: Bool = false, cache: Bool = true)
    {
        let anon = UIImage(named: "avatar")
        if(self.avatar != nil)
        {
            var options = refresh ? [KingfisherOptionsInfoItem.forceRefresh] : []
            if(!cache) {
                let cache = DummyCache(name: "default")
                options.append(KingfisherOptionsInfoItem.targetCache(cache))
            }
            imageView.kf.setImage(with: URL(string: self.avatar!), placeholder: anon, options: options)
        } else {
            imageView.image = anon
        }
    }
    
    func getDictionary() -> NSDictionary
    {
        let d: NSDictionary = [
            "id": id,
            "token": token ?? "",
            "username": username ?? "",
            "avatar": avatar ?? "",
            "referral": referral ?? "",
        ]
        
        return d
    }
}
