//
//  RoundedButton.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 16.04.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
    }

}
