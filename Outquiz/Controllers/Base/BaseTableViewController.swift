//
//  BaseTableViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 10.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {
    
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
