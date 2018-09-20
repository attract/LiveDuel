//
//  PhoneViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 10.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit
import MRCountryPicker

class PhoneViewController: BaseTableViewController, MRCountryPickerDelegate
{
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countryPicker: MRCountryPicker!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var numberField: UITextField!
    
    var country: String = ""
    var phone: String = ""

    // MARK: - Navigation Bar
    
    @IBAction func cancelTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func verifyTap(_ sender: Any) {
        API.verify(self.country, self.numberField.text!, phoneSuccess, failure)
    }
    
    // MARK: - Phone Request Result
    
    func phoneSuccess(_ data: NSDictionary)
    {
        self.phone = data["phone"] as! String
        self.performSegue(withIdentifier: "PhoneToCode", sender: self)
    }
    
    // MARK: - View
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // open keyboard on view load
        numberField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView()
    {
        // setup colors
        tableView.backgroundColor = UIColor(cfgName: "colors.system.background")
        
        // fill in labels
        self.title = NSLocalizedString("tr_phone_number", comment: "")
        countryLabel.text = NSLocalizedString("tr_country", comment: "")
        numberLabel.text = NSLocalizedString("tr_number", comment: "")
        numberField.placeholder = NSLocalizedString("tr_phone_number", comment: "")
        
        // setup country picker
        countryPicker.countryPickerDelegate = self
        countryPicker.showPhoneNumbers = true
        
        // set country to current locale's country
        countryPicker.setCountry(NSLocale.current.regionCode ?? "US")
        
        // remove empty cells from tableview
        tableView.tableFooterView = UIView()
        
        // add "close on tap" functionality
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // enable/disable continue button based on phone entered or not
        numberField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    // MARK: - Events
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        navigationItem.rightBarButtonItem?.isEnabled = textField.text != "" ? true : false
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func countryPhoneCodePicker(_ picker: MRCountryPicker, didSelectCountryWithName name: String, countryCode: String, phoneCode: String, flag: UIImage) {
        self.country = countryCode
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "PhoneToCode")
        {
            let dist = segue.destination as! PhoneCodeViewController
            dist.phone = self.phone
            dist.number = self.numberField.text
            dist.country = self.country
        }
    }
    
    
}
