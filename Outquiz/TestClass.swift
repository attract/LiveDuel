//
//  TestClass.swift
//  Outquiz
//
//  Created by Stanislav on 9/20/18.
//  Copyright © 2018 Vasily Evreinov. All rights reserved.
//

import Foundation

open class TestClass: NSObject {
    public static let shared = TestClass()
    
    public func echoLine(_ text: String) {
        print("Echo: \(text)")
    }
    
    public override init() {
        super.init()
    }
}
