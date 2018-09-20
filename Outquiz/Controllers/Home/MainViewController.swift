//
//  MainViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 16.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class MainViewController: BaseViewController {
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // not logged in
        if(Misc.currentPlayer == nil)
        {
            performSegue(withIdentifier: "MainToLogin", sender: self)
        } else {
            performSegue(withIdentifier: "MainToHome", sender: self)
        }
    }
}
