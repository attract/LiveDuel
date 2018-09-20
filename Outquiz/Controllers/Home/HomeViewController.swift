//
//  HomeViewController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 16.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class HomeViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var faqButton: UIButton!
    @IBOutlet weak var nextGameInfoLabel: UILabel!
    @IBOutlet weak var liveButton: UIButton!
    
    @IBOutlet weak var userCardView: UIView!
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var rankLabel: UILabel!
    
    @IBOutlet weak var balanceValueLabel: UILabel!
    @IBOutlet weak var balanceTitleLabel: UILabel!
    @IBOutlet weak var livesValueLabel: UILabel!
    @IBOutlet weak var livesTitleLabel: UILabel!
    @IBOutlet weak var livesImageView: UIImageView!
    
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var getMoreLivesButton: UIButton!
    
    @IBOutlet weak var lbView: UIView!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbSelector: UISegmentedControl!
    @IBOutlet weak var lbList: UITableView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    // MARK: - Properties
    var showsTimer: Timer?
    var show: Show?
    var lbWeekly: NSArray?
    var lbTotal: NSArray?
    var autoLaunchShow: Bool = true
    var playerStats: NSDictionary?
    
    // MARK: - Button Taps
    
    @IBAction func getMoreLivesButtonTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "GetLives") as! LivesViewController
        
        let navigationController = UINavigationController(rootViewController: controller)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func menuButtonTap(_ sender: Any) {
        showMenu()
    }
    
    @IBAction func liveButtonTap(_ sender: Any) {
        launchShow()
    }
    
    @IBAction func faqButtonTap(_ sender: Any) {
        showFaqMenu()
    }
    
    @objc func showCashout()
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Cashout") as! CashoutViewController
        controller.balance = playerStats?["balance"] as? Int ?? 0
        
        let navigationController = UINavigationController(rootViewController: controller)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - FAQ Menu
    
    @objc func showFaqMenu()
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_rules", comment: ""), style: .default, handler: { (action) in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "WebView") as! WebViewController
            controller.docTitle = NSLocalizedString("tr_rules", comment: "")
            controller.docUrl = URL(string: Misc.docUrl("rules"))
            
            let navigationController = UINavigationController(rootViewController: controller)
            self.present(navigationController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_faq", comment: ""), style: .default, handler: { (action) in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "WebView") as! WebViewController
            controller.docTitle = NSLocalizedString("tr_faq", comment: "")
            controller.docUrl = URL(string: Misc.docUrl("faq"))
            
            let navigationController = UINavigationController(rootViewController: controller)
            self.present(navigationController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_cancel", comment: ""), style: .cancel, handler: { (action) in
            // do nothing, it's cancelled
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Menu
    
    @objc func showMenu()
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_invite", comment: ""), style: .default, handler: { (action) in
            let shareText = String(format:NSLocalizedString("tr_share_text", comment: ""),
                                Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String,
                                Misc.currentPlayer!.referral!,
                                Config.shared.data["app.host"]!)
            
            let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            self.present(activityController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_apply_referral_code", comment: ""), style: .default, handler: { (action) in
            
            let codeAlert = UIAlertController(title: nil, message: NSLocalizedString("tr_apply_referral_code", comment: ""), preferredStyle: .alert)
            codeAlert.addTextField(configurationHandler: {(textField) in
                textField.placeholder = NSLocalizedString("tr_referral_code", comment: "")
            })
            codeAlert.addAction(UIAlertAction(title: NSLocalizedString("tr_apply", comment: ""), style: .default, handler: {(action) in
                let textField = codeAlert.textFields![0] as UITextField
                self.applyReferralCode(code: textField.text!)
                
            }))
            codeAlert.addAction(UIAlertAction(title: NSLocalizedString("tr_cancel", comment: ""), style: .cancel, handler: {(action) in
                // do nothing
            }))
            self.present(codeAlert, animated: true, completion: nil)
            
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_logout", comment: ""), style: .destructive, handler: { (action) in
            Misc.logout()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_cancel", comment: ""), style: .cancel, handler: { (action) in
            // do nothing, it's cancelled
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Referral Code
    
    func applyReferralCode(code: String)
    {
        API.referral(code, referralSuccess, failure)
    }
    
    func referralSuccess(_ data: NSDictionary)
    {
        let alert = UIAlertController(title: NSLocalizedString("tr_referral_code", comment: ""), message: NSLocalizedString("tr_referral_code_success", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_ok", comment: ""), style: .default, handler: {(alert: UIAlertAction!) in
            // close
        }))
        self.present(alert, animated: true)
    }
    
    // MARK: - Avatar
    
    @objc func showAvatarMenu()
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_new_photo", comment: ""), style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_camera_roll", comment: ""), style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        
        if(Misc.currentPlayer?.avatar != nil)
        {
            alert.addAction(UIAlertAction(title: NSLocalizedString("tr_delete_avatar", comment: ""), style: .default, handler: { (action) in
                API.avatar(nil, self.uploadSuccess, self.failure)
            }))
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_cancel", comment: ""), style: .cancel, handler: { (action) in
            // do nothing, it's cancelled
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // show loading indicator
        let center = avatarImageView.frame.width / 2 - 10
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: center, y: center, width: 20, height: 20))
        activityIndicator.activityIndicatorViewStyle = .white
        activityIndicator.tag = 99
        avatarImageView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // upload image
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        API.avatar(imageData!, uploadSuccess, failure)
        dismiss(animated:true, completion: nil)
    }
    
    func uploadSuccess(_ data: NSDictionary)
    {
        // remove loading indicator
        avatarImageView.viewWithTag(99)?.removeFromSuperview()
        
        // update player info
        var player = Misc.currentPlayer!
        player.token = data["token"] as? String
        player.avatar = data["avatar"] as? String
        // save as current player
        Misc.currentPlayer = player
        // update preview
        Misc.currentPlayer?.setAvatar(avatarImageView, refresh: true)
    }
    
    override func failure(_ status: Int, _ errors: [String]) {
        // remove loading indicator
        avatarImageView.viewWithTag(99)?.removeFromSuperview()
        super.failure(status, errors)
    }
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        // stop timer when app goes in background
        NotificationCenter.default.addObserver(self, selector: #selector(appClosed), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appOpened), name:NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        // enable auto show live show
        autoLaunchShow = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disappear()
    }
    
    @objc func appClosed()
    {
        disappear()
    }
    
    @objc func appOpened()
    {
        appear()
    }
    
    func appear()
    {
        if(showsTimer == nil)
        {
            showsTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(loadShow), userInfo: nil, repeats: true)
        }
        loadPlayer()
        loadLb()
    }
    
    func disappear()
    {
        showsTimer?.invalidate()
        showsTimer = nil
    }
    
    func configureView()
    {
        // design
        let textColor = UIColor(cfgName: "colors.text")
        faqButton.tintColor = textColor
        liveButton.backgroundColor = UIColor(cfgName: "colors.home.watch.background")
        liveButton.setTitleColor(UIColor(cfgName: "colors.home.watch.text"), for: .normal)
        userCardView.backgroundColor = textColor.withAlphaComponent(0.1)
        userCardView.layer.cornerRadius = 16.0
        usernameLabel.textColor = textColor
        menuButton.tintColor = textColor
        rankLabel.textColor = textColor.withAlphaComponent(0.5)
        balanceValueLabel.textColor = textColor
        balanceTitleLabel.textColor = textColor.withAlphaComponent(0.5)
        livesValueLabel.textColor = textColor
        livesTitleLabel.textColor = textColor.withAlphaComponent(0.5)
        livesImageView.tintColor = UIColor(cfgName: "colors.home.heart")
        getMoreLivesButton.backgroundColor = textColor
        getMoreLivesButton.setTitleColor(UIColor(cfgName: "colors.background"), for: .normal)
        lbView.backgroundColor = textColor.withAlphaComponent(0.1)
        lbView.layer.cornerRadius = 16.0
        lbSelector.tintColor = textColor
        lbTitle.textColor = textColor
        separatorView.backgroundColor = textColor.withAlphaComponent(0.2)
        
        // fill in labels and available data, such as avatar
        nextGameInfoLabel.attributedText = NSAttributedString(string: "")
        Misc.currentPlayer?.setAvatar(avatarImageView)
        usernameLabel.text = Misc.currentPlayer?.username
        rankLabel.text = ""
        balanceValueLabel.text = ""
        balanceTitleLabel.text = NSLocalizedString("tr_balance", comment: "")
        livesValueLabel.text = "0"
        livesTitleLabel.text = NSLocalizedString("tr_lives", comment: "")
        liveButton.setTitle(NSLocalizedString("tr_live_watch_now", comment: ""), for: .normal)
        
        // enable tap on avatar to show menu
        avatarImageView.isUserInteractionEnabled = true
        let avatarTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showAvatarMenu))
        avatarImageView.addGestureRecognizer(avatarTap)
        
        // enable tap on balance to show cashout screen
        balanceValueLabel.isUserInteractionEnabled = true
        let balanceTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showCashout))
        balanceValueLabel.addGestureRecognizer(balanceTap)
        
        // leaderboard
        lbSelector.addTarget(self, action: #selector(lbChanged), for: .valueChanged)
        lbSelector.setTitle(NSLocalizedString("tr_this_week", comment: ""), forSegmentAt: 0)
        lbSelector.setTitle(NSLocalizedString("tr_all_time", comment: ""), forSegmentAt: 1)
        lbSelector.selectedSegmentIndex = 0
        lbList.dataSource = self
        lbList.delegate = self
        // remove empty cells from tableview
        lbList.tableFooterView = UIView()
        // hide before the data loads
        lbList.isHidden = true
    }
    
    // MARK: - Show
    
    @objc func loadShow()
    {
        API.home(showSuccess, failure)
    }

    func showSuccess(_ data: NSDictionary)
    {
        let obj = data["show"] as? NSDictionary
        if(obj != nil)
        {
            let id = obj!["id"] as! Int
            let schedule = obj!["schedule"] as! String
            let amount = obj!["amount"] as! Int
            let live = obj!["live"] as! Int
            self.show = Show(id, schedule, amount, live)
        } else {
            self.show = nil
        }
        updateShow()
    }
    
    func updateShow()
    {
        var msg = NSMutableAttributedString(string: "")
        
        if(show == nil)
        {
            msg = NSMutableAttributedString(string: NSLocalizedString("tr_no_upcoming_show", comment: "").uppercased())
            msg.setFont(msg.string, UIFont.systemFont(ofSize: 20.0))
            nextGameInfoLabel.isHidden = false
            liveButton.isHidden = true
        }
        else if(show!.live == 0)
        {
            let strNextGameTitle = NSLocalizedString("tr_next_game", comment: "").uppercased()
            let strSchedule = self.show!.scheduleFormatted()
            let strPrizeTitle = NSLocalizedString("tr_prize", comment: "").uppercased()
            let strPrize = self.show!.amountFormatted()
            
            msg = NSMutableAttributedString(string: strNextGameTitle)
            msg.append(NSAttributedString(string: "\n"))
            msg.append(NSMutableAttributedString(string: strSchedule))
            msg.append(NSAttributedString(string: "\n"))
            msg.append(NSAttributedString(string: strPrizeTitle))
            msg.append(NSAttributedString(string: "\n"))
            msg.append(NSMutableAttributedString(string: strPrize))
            
            msg.setFont(strNextGameTitle, UIFont.systemFont(ofSize: 20.0))
            msg.setFont(strSchedule, UIFont.boldSystemFont(ofSize: strSchedule.count < 10 ? 35.0 : 30.0))
            msg.setFont(strPrizeTitle, UIFont.systemFont(ofSize: 20.0))
            msg.setFont(strPrize, UIFont.boldSystemFont(ofSize: 35.0))
            
            nextGameInfoLabel.isHidden = false
            liveButton.isHidden = true
        }
        else if(show!.live == 1)
        {
            nextGameInfoLabel.isHidden = true
            liveButton.isHidden = false
            if autoLaunchShow
            {
                launchShow()
            }
        }
        
        if(msg.length > 0)
        {
            let range = NSRange(location: 0, length: msg.length)
            msg.setCentered()
            msg.addAttribute(.foregroundColor, value: UIColor(cfgName: "colors.text"), range: range)
        }
        nextGameInfoLabel.attributedText = msg
    }
    
    func launchShow()
    {
        performSegue(withIdentifier: "HomeToShow", sender: self)
        autoLaunchShow = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "HomeToShow")
        {
            let dist = segue.destination as! ShowViewController
            dist.lives = playerStats?["lives"] as? Int ?? 0
            dist.show = self.show
        }
    }
    
    // MARK: - Player Stats
    
    func loadPlayer()
    {
        API.player(playerSuccess, failure)
    }
    
    func playerSuccess(_ data: NSDictionary)
    {
        playerStats = data
        
        let rank_total = data["rank_total"] as? Int
        let rank_weekly = data["rank_weekly"] as? Int
        let balance = data["balance"] as! Int
        let lives = data["lives"] as! Int
        
        let rank_weekly_str = rank_weekly == nil ? "-" : String(format:"%d", rank_weekly!)
        let rank_total_str = rank_total == nil ? "-" : String(format:"%d", rank_total!)
        
        rankLabel.text = String(format: NSLocalizedString("tr_rank_this_week", comment: ""), rank_weekly_str, rank_total_str)
        balanceValueLabel.text = Misc.moneyFormat(balance)
        livesValueLabel.text = String(format:"%d", lives)
        
        loadShow()
    }
    
    // MARK: - Leaderboard
    
    func loadLb()
    {
        API.leaderboard(lbSucces, failure)
    }
    
    func lbSucces(_ data: NSDictionary)
    {
        lbWeekly = data["weekly"] as? NSArray
        lbTotal = data["total"] as? NSArray
        lbChanged()
    }
    
    @objc func lbChanged()
    {
        lbList.reloadData()
        // show the list
        lbList.isHidden = false
        // list height is a height of a row multiplied by the number of rows
        let listHeight = tableView(lbList, heightForRowAt: IndexPath(row: 0, section: 0)) * CGFloat(tableView(lbList, numberOfRowsInSection: 0))
        // leaderboard section height equals to top position of the list plus it's height
        let lbHeight = lbList.frame.origin.y + listHeight
        // content view height equals to top position of leaderboard view plus it's height plus margin
        contentViewHeight.constant = lbView.frame.origin.y + lbHeight + 16.0 * 2
        // layout content view
        contentView.layoutIfNeeded()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 44.0;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let src = lbSelector.selectedSegmentIndex == 0 ? lbWeekly : lbTotal
        return src == nil ? 0 : src!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath) as! LeaderboardCell
        
        let src = lbSelector.selectedSegmentIndex == 0 ? lbWeekly : lbTotal
        let item = src![indexPath.row] as! NSDictionary
        let player = Player(data: item)
        
        let amount = item["total"] as! Int
        let amountFloat = Float(amount) / Float(100)
        let format = amountFloat.truncatingRemainder(dividingBy: 1.0) > 0 ? "%@%.2f" : "%@%.0f"
        
        cell.rankLabel.text = String(format: "%d", indexPath.row+1)
        cell.usernameLabel.text = player.username
        cell.amountLabel.text = String(format: format, Config.shared.data["app.currencySymbol"]!, amountFloat)
        
        player.setAvatar(cell.avatarImageView, cache: false)
        
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
            cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0);
        } else {
            cell.separatorInset = UIEdgeInsets.zero
        }
    }
        
}
