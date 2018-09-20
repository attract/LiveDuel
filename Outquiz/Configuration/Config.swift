//
//  Config.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 09.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class Config: NSObject {
    fileprivate var config: Config?
    var data = [String: String]()
    
    // MARK: - Init
    
    class var shared : Config {
        struct Static {
            static let instance : Config = Config()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
            data = dict
        } else {
            print("Error: Config.plist is missing.")
        }
    }
}
