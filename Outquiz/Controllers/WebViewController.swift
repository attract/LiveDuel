//
//  WebViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 09.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class WebViewController: BaseViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    // title of the page to display
    var docTitle: String?
    
    // URL which WebView will need to show
    var docUrl: URL?
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView()
    {
        self.title = docTitle!
        webView.loadRequest(URLRequest(url: docUrl!))
        webView.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closePopup))
    }
    
    @objc func closePopup()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView)
    {
        // hide loading indicator
        self.view.viewWithTag(15)?.isHidden = true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error)
    {
        // hide loading indicator
        self.view.viewWithTag(15)?.isHidden = true
    }
    
}
