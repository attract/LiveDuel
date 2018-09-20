//
//  ShowController.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 26.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit
import SocketIO
import Kingfisher
import AVFoundation
import SRCountdownTimer

class ShowViewController: BaseViewController, AnswerOptionDelegate, SRCountdownTimerDelegate, VLCMediaPlayerDelegate {
    
    // video
    @IBOutlet weak var spinnerImageView: UIImageView!
    
    // header
    @IBOutlet weak var viewersCountLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var eyeIcon: UIImageView!
    @IBOutlet weak var appIcon: UIButton!
    
    // chat
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var chatList: UITableView!
    @IBOutlet weak var chatListBottom: NSLayoutConstraint!
    @IBOutlet weak var chatListLeft: NSLayoutConstraint!
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var messageInputArea: UIView!
    @IBOutlet weak var messageInputAreaLeft: NSLayoutConstraint!
    @IBOutlet weak var messageInputAreaBottom: NSLayoutConstraint!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var swipeInfoLabel: UILabel!
    
    // question
    @IBOutlet weak var questionCardView: UIView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var questionStatusImageView: UIImageView!
    @IBOutlet weak var questionCountdownTimer: SRCountdownTimer!
    @IBOutlet weak var questionOptionsView: UIView!
    
    // winners
    @IBOutlet weak var winnersView: UIView!
    @IBOutlet weak var winnersTitleLabel: UILabel!
    @IBOutlet weak var winnersUserView: UIView!
    @IBOutlet weak var winnersShareButton: UIButton!
    
    // MARK: - Properties
    var show: Show?
    var chat: Chat?
    var socket: SocketIOClient?
    var socketManager: SocketManager?
    var selectedOption: Int?
    var inTheGame: Bool = true
    var questionTimer: Timer?
    var lives = 0
    var isLastQuestion = false
    var player = VLCMediaPlayer()
    var reconnect = true
    var safeAreaMargin: CGFloat?
    var cachedImages: [Resource]?
    var bufferingTimer: Timer?
    let networkCache = 250
    let diskCache = 250
    
    // MARK: - Buttons
    
    @IBAction func appIconTap(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("tr_close", comment: ""), message: NSLocalizedString("tr_leave_game", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_yes", comment: ""), style: .default, handler: {(alert: UIAlertAction!) in
            self.showClose()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_cancel", comment: ""), style: .cancel, handler: {(alert: UIAlertAction!) in
            //do nothing
        }))
        self.present(alert, animated: true)
    }
    
    // MARK: - Keyboard
    
    @objc override func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // find out safe area margin
            let space = CGFloat(16.0)
            chatListBottom.constant = keyboardSize.height - (safeAreaMargin ?? 0) + space
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
                self.questionCardView.viewWithTag(55)?.alpha = 0.0
                self.winnersView.viewWithTag(55)?.alpha = 0.0
            })
            
        }
    }
    
    @objc override func keyboardWillHide(notification: NSNotification) {
        chatListBottom.constant = 16.0
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.questionCardView.viewWithTag(55)?.alpha = 1.0
            self.winnersView.viewWithTag(55)?.alpha = 1.0
        })
    }
    
    @objc func dismissKeyboard() {
        if(chatTextField.isFirstResponder)
        {
            view.endEditing(true)
            chatHideField()
        }
    }
    
    // MARK: - Video
    
    func videoInit()
    {
        if(player.delegate == nil)
        {
            player.delegate = self
            player.drawable = self.view.viewWithTag(999)!
            player.scaleFactor = self.videoScale()
        }
    }
    
    @objc func videoStart()
    {
        if(!player.isPlaying)
        {
            let url = URL(string: Misc.streamingUrl())
            let options = ["network-caching": self.networkCache, "file-caching": self.diskCache]
            let media = VLCMedia(url: url!)
            media.addOptions(options)
            player.media = media
            player.play()
        }
    }
    
    func videoStop()
    {
        if(player.isPlaying)
        {
            player.stop()
        }
    }
    
    func videoScale() -> Float
    {
        let deviceScale = UIScreen.main.scale
        let widthScale = Float(self.view.frame.size.width * deviceScale) / Float(Config.shared.data["video.width"]!)!
        let heightScale = Float(self.view.frame.size.height * deviceScale) / Float(Config.shared.data["video.height"]!)!
        
        return widthScale > heightScale ? widthScale : heightScale
    }
    
    func videoBuffering()
    {
        bufferingTimer?.invalidate()
        bufferingTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(videoBufferingEnded), userInfo: nil, repeats: false)
        
        if(spinnerImageView.isHidden)
        {
            spinnerImageView.isHidden = false
            videoSinnerRotate()
        }
    }
    
    @objc func videoBufferingEnded()
    {
        spinnerImageView.isHidden = true
    }
    
    func videoSinnerRotate()
    {
        if(!spinnerImageView.isHidden && spinnerImageView.layer.animationKeys() == nil)
        {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveLinear], animations: {
                self.spinnerImageView.transform = self.spinnerImageView.transform.rotated(by: .pi)
            }, completion: {_ in
                self.videoSinnerRotate()
            })
        }
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        print(VLCMediaPlayerStateToString(player.state))
        
        // buffering
        if player.state == .buffering
        {
            videoBuffering()
        }
        // lost connection - reconnect
        else if player.state == .stopped && reconnect
        {
            videoBuffering()
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(videoStart), userInfo: nil, repeats: false)
        }
    }
    
    // MARK: - Game
    
    func showQuestion(_ data: NSDictionary)
    {
        // nullify current selected option
        selectedOption = nil
        
        // extract data
        let question = data["question"] as! String
        let answers = data["answers"] as! NSArray
        self.isLastQuestion = data["islast"] as! Bool
        
        // fill in question
        questionLabel.text = question
        // create answer options
        genAnswers(answers)
        
        // countdown time to answer
        if(inTheGame)
        {
            questionTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Config.shared.data["settings.answer-time"]!)! + 0.3, target: self, selector: #selector(tooLate), userInfo: nil, repeats: false)
        }
        self.showQuestionCountdown()
        
        // show card
        showQuestionCard()
        // hide after answer time passes + 1 second
        Timer.scheduledTimer(timeInterval: TimeInterval(Config.shared.data["settings.answer-time"]!)! + 1.0, target: self, selector: #selector(hideQuestionCard), userInfo: nil, repeats: false)
    }
    
    func showQuestionCard()
    {
        questionOptionsView.subviews.forEach({ $0.alpha = 0.0 })
        questionCardView.isHidden = false
        questionCardView.alpha = 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.questionCardView.alpha = 1.0
        }, completion: {_ in
            for i in 0...self.questionOptionsView.subviews.count-1 {
                let view = self.questionOptionsView.subviews[i]
                let originalY = view.frame.origin.y
                view.frame.origin.y = originalY + 16.0
                UIView.animate(withDuration: 0.5, delay: 0.2*Double(i), options: [.curveEaseOut], animations: {
                    view.frame.origin.y = originalY
                    view.alpha = 1.0
                }, completion: nil)
            }
        })
    }
    
    func showQuestionCountdown()
    {
        questionCountdownTimer.start(beginingValue: Int(Config.shared.data["settings.answer-time"]!)!)
    }
    
    @objc func hideQuestionCard()
    {
        UIView.animate(withDuration: 0.3, animations: {
            self.questionCardView.alpha = 0.0
        }, completion: {_ in
            self.questionCardView.isHidden = true
            self.appIcon.isHidden = false
            self.questionStatusImageView.isHidden = true
        })
    }
    
    func genAnswers(_ answers: NSArray)
    {
        questionOptionsView.subviews.forEach({ $0.removeFromSuperview() })
        
        let space = CGFloat(48 / answers.count)
        var height = (self.questionOptionsView.frame.height - CGFloat(answers.count-1)*space) / CGFloat(answers.count)
        if(height > 54)
        {
            height = 54
        }
        
        let width = self.questionOptionsView.frame.width
        for i in 0...answers.count-1 {
            let a = answers[i] as! NSDictionary
            let tag = a["id"] as! Int
            
            let view = Bundle.main.loadNibNamed("AnswerOption", owner: self, options: nil)?.first as! AnswerOption
            view.tag = tag
            view.frame = CGRect(x: 0, y: CGFloat(i)*(height + space), width: width, height: height)
            view.delegate = self
            view.reset(a["answer"] as! String)
            questionOptionsView.addSubview(view)
        }
        
    }
    
    func showCorrect(_ correct: Int, _ stats: NSDictionary)
    {
        if(questionOptionsView.subviews.count <= 0)
        {
            return
        }
        
        // calculate total
        var total = 0
        for (_, value) in stats {
            let votes = value as! Int
            total = total + votes
        }
        
        // one more loop to update views
        for(key, value) in stats {
            let id = Int(key as! String) ?? 0
            let votes = value as! Int
            
            let view = questionOptionsView.viewWithTag(id) as? AnswerOption
            
            var type = ""
            // correct answer
            if(id == correct)
            {
                type = "correct"
                if(id == selectedOption && inTheGame)
                {
                    showQuestionStatus(true)
                }
            }
            // wrong answer
            else if(id == selectedOption) {
                type = "wrong"
                
                if(inTheGame)
                {
                    showQuestionStatus(false)
                }
                
                kickOut()
                
                // suggest to use life if there is one and this is not a last question
                if(self.lives > 0 && !self.isLastQuestion) {
                    suggestLife()
                }
            }
            else { type = "neutral" }
            
            view?.stats(votes, total, type)
        }
        
        // show question card
        showQuestionCard()
        // hide after 5 seconds
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideQuestionCard), userInfo: nil, repeats: false)
    }
    
    func showQuestionStatus(_ isCorrect: Bool)
    {
        if(isCorrect) {
            questionStatusImageView.image = UIImage(named: "checkmark")
        } else {
            questionStatusImageView.image = UIImage(named: "cross")
        }
        
        questionStatusImageView.alpha = 0.0
        questionStatusImageView.isHidden = false
        
        appIcon.isHidden = true
        
        UIView.animate(withDuration: 0.2, animations: {
            self.questionStatusImageView.alpha = 1.0
        })
        
    }
    
    func suggestLife()
    {
        let alert = UIAlertController(title: NSLocalizedString("tr_wrong_answer", comment: ""), message: NSLocalizedString("tr_suggest_life", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_yes", comment: ""), style: .default, handler: {(action) in
            self.socketSendLife()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("tr_no", comment: ""), style: .cancel, handler: {(action) in
            // do nothing
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showWinners(_ amount: Int, _ winners: NSArray)
    {
        // only show if there are winners to show
        if winners.count > 0 {
            var avatars = [URL]()
            let players = NSMutableArray()
            for i in 0...winners.count-1 {
                let data = winners[i] as! NSMutableDictionary
                data.setValue(amount, forKey: "prize")
                
                // current player is a winner - show only them
                if(data["id"] as! Int == Misc.currentPlayer!.id) {
                    showWinnersCard(winners: NSArray(object: data))
                    winnersShareButton.isHidden = false
                    winnersTitleLabel.text = NSLocalizedString("tr_you_won", comment: "")
                    return
                }
                
                players.add(data)
                if let avatar = data["avatar"]
                {
                    avatars.append(URL(string: avatar as! String)!)
                }
            }
            // prefetch avatars
            let prefetcher = ImagePrefetcher(urls: avatars) {
                skippedResources, failedResources, completedResources in
                print("These resources are prefetched: \(completedResources)")
                self.cachedImages = completedResources
            }
            prefetcher.start()
            // show winners card
            showWinnersCard(winners: players)
        }
    }
    
    func showWinnersCard(winners: NSArray)
    {
        winnersView.isHidden = false
        winnersView.alpha = 0.0
        winnersUserView.tag = 0
        winnersUserView.alpha = 0.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.winnersView.alpha = 1.0
        }, completion: {_ in
            self.showWinnerInfo(winners: winners)
        })
        
        // hide after required amount of time - 2 seconds to show host
        Timer.scheduledTimer(timeInterval: TimeInterval(Config.shared.data["settings.winners-time"]!)! - 2.0, target: self, selector: #selector(hideWinnersCard), userInfo: nil, repeats: false)
    }
    
    @objc func hideWinnersCard()
    {
        UIView.animate(withDuration: 0.3, animations: {
            self.winnersView.alpha = 0.0
        }, completion: {_ in
            self.winnersView.isHidden = true
            if(self.cachedImages != nil)
            {
                for r in self.cachedImages! {
                    ImageCache.default.removeImage(forKey: r.cacheKey)
                }
            }
        })
    }
    
    @objc func showWinnerInfo(winners: NSArray)
    {
        let ind = winnersUserView.tag
        if(ind < winners.count)
        {
            let data = winners[winnersUserView.tag] as! NSDictionary
            let player = Player(data: data)
            
            let avatarImageView = winnersUserView.viewWithTag(211) as! UIImageView
            let usernameLabel = winnersUserView.viewWithTag(212) as! UILabel
            let prizeLabel = winnersUserView.viewWithTag(213) as! UILabel
            
            player.setAvatar(avatarImageView)
            usernameLabel.text = player.username
            
            let prize = data["prize"] as! Int
            prizeLabel.text = Misc.moneyFormat(prize)
            
            var showTime = (Float(Config.shared.data["settings.winners-time"]!)! - Float(2.0)) / Float(winners.count) - 0.2
            if showTime < 0.2 { showTime = 0.2 }
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn], animations: {
                self.winnersUserView.alpha = 1.0
            }, completion: {_ in
                
                UIView.animate(withDuration: 0.2, delay: TimeInterval(showTime), options: [.curveEaseOut], animations: {
                    self.winnersUserView.alpha = 0.0
                }, completion: {_ in
                    if !self.winnersView.isHidden
                    {
                        self.winnersUserView.tag = self.winnersUserView.tag + 1
                        self.showWinnerInfo(winners: winners)
                    }
                })
                
            })
        }
    }
    
    @IBAction func winnersShareButtonTap(_ sender: Any) {
        let prizeLabel = winnersUserView.viewWithTag(213) as! UILabel
        let shareText = String(format:NSLocalizedString("tr_share_win_text", comment: ""),
                               Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String,
                               prizeLabel.text!,
                               Config.shared.data["app.host"]!)
        
        let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    func canSelectOption() -> Bool
    {
        return selectedOption == nil && questionCardView.viewWithTag(55)?.alpha == 1.0
    }
    
    func optionSelected(_ id: Int) -> Bool {
        if(inTheGame)
        {
            selectedOption = id
            socketSendAnswer()
            questionTimer?.invalidate()
            return true
        }
        showWarning(NSLocalizedString("tr_watching_only", comment: ""), true)
        return false
    }
    
    func showWarning(_ msg: String, _ autoRemove: Bool)
    {
        return showWarning(msg, autoRemove, nil)
    }
    
    func showWarning(_ msg: String, _ autoRemove: Bool, _ type: String?)
    {
        warningLabel.text = msg
        warningLabel.alpha = 0.0
        
        if(type == "success") { warningLabel.backgroundColor = UIColor(cfgName: "colors.show.success") }
        else { warningLabel.backgroundColor = UIColor(cfgName: "colors.show.warning") }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.warningLabel.alpha = 1.0
        })
        if(autoRemove)
        {
            Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(hideWarning), userInfo: nil, repeats: false)
        }
    }
    
    @objc func hideWarning()
    {
        UIView.animate(withDuration: 0.2, animations: {
            self.warningLabel.alpha = 0.0
        })
    }
    
    @objc func tooLate()
    {
        kickOut()
        showWarning(NSLocalizedString("tr_too_late", comment: ""), true)
    }
    
    @objc func watchOnly()
    {
        kickOut()
        showErrors(errors: [NSLocalizedString("tr_already_started", comment: "")])
    }
    
    func kickOut()
    {
        inTheGame = false
    }
    
    func kickIn()
    {
        inTheGame = true
    }
    
    @objc func showClose()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Chat
    
    @IBAction func openButtonTap(_ sender: Any) {
        chatShowField()
    }
    
    @IBAction func sendButtonTap(_ sender: Any) {
        let message = chatTextField.text!
        socketSendChat(message)
        chatTextField.text! = ""
    }
    
    func chatShowField()
    {
        openButton.isHidden = true
        sendButton.isHidden = false
        chatTextField.isHidden = false
        chatTextField.becomeFirstResponder()
    }
    
    func chatHideField()
    {
        openButton.isHidden = false
        sendButton.isHidden = true
        chatTextField.isHidden = true
    }
    
    @objc func chatGesture(gesture: UISwipeGestureRecognizer)
    {
        // do nothing if keyboard is open
        if(chatTextField.isFirstResponder)
        {
            return
        }
        
        // hide chat
        if(gesture.direction == .right && swipeInfoLabel.isHidden)
        {
            swipeInfoLabel.isHidden = false
            swipeInfoLabel.alpha = 0.0
            chatListLeft.constant = view.bounds.width
            messageInputAreaLeft.constant = view.bounds.width
            UIView.animate(withDuration: 0.3, animations: {
                self.swipeInfoLabel.alpha = 1.0
                self.view.layoutIfNeeded()
            })
        }
        // show chat
        else if(gesture.direction == .left && !swipeInfoLabel.isHidden)
        {
            chatListLeft.constant = 0
            messageInputAreaLeft.constant = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.swipeInfoLabel.alpha = 0.0
                self.view.layoutIfNeeded()
            }, completion: {_ in
                self.swipeInfoLabel.isHidden = true
            })
        }
    }
    
    func chatInit()
    {
        chat = Chat(tableView: self.chatList)
    }
    
    func chatReceived(_ message: ChatMessage)
    {
        chat!.add(message)
    }
    
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        NotificationCenter.default.addObserver(self, selector: #selector(appClosed), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disappear()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // gradient fade for chat
        let gradient = CAGradientLayer()
        gradient.frame = chatList.bounds
        gradient.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0.9, 1.0]
        chatList.layer.mask = gradient
        // warning label corners
        warningLabel.layer.cornerRadius = warningLabel.frame.size.height / 2
        // calculate safe area margin
        if(safeAreaMargin == nil)
        {
            safeAreaMargin = self.view.frame.size.height - (chatView.frame.origin.y + chatView.frame.size.height + 16.0)
        }
        
        // start video
        videoInit()
        videoStart()
        
    }
    
    @objc func appClosed()
    {
        self.dismiss(animated: false, completion: nil)
    }
    
    func appear()
    {
        // connect to socket
        socketConnect()
        // reconnect video
        reconnect = true
    }
    
    func disappear()
    {
        socketDisconnect()
        // stop reconnecting
        reconnect = false
        videoStop()
    }
    
    func configureView()
    {
        // setup design
        let textColor = UIColor(cfgName: "colors.text")
        // header
        eyeIcon.tintColor = textColor
        appIcon.imageView?.contentMode = .scaleAspectFit
        viewersCountLabel.textColor = textColor
        questionStatusImageView.layer.cornerRadius = questionStatusImageView.frame.size.height / 2
        questionStatusImageView.clipsToBounds = true
        questionStatusImageView.layer.borderColor = UIColor.white.cgColor
        questionStatusImageView.layer.borderWidth = 2.0
        
        // chat
        openButton.tintColor = textColor
        sendButton.tintColor = textColor
        chatTextField.layer.cornerRadius = chatTextField.frame.size.height / 2
        swipeInfoLabel.textColor = textColor.withAlphaComponent(0.5)
        // winners
        winnersTitleLabel.textColor = textColor
        let winnerUsername = winnersView.viewWithTag(212) as? UILabel
        winnerUsername?.textColor = textColor
        let winnerPrize = winnersView.viewWithTag(213) as? UILabel
        winnerPrize?.textColor = textColor
        winnersShareButton.backgroundColor = UIColor(cfgName: "colors.winners.share.background")
        winnersShareButton.setTitleColor(UIColor(cfgName: "colors.winners.share.text"), for: .normal)
        // question
        questionLabel.textColor = textColor
        
        // translates
        winnersTitleLabel.text = NSLocalizedString("tr_winners", comment: "")
        winnersShareButton.setTitle(NSLocalizedString("tr_share", comment: ""), for: .normal)
        
        // init chat data source and delegate
        chatInit()
        
        // add "close on tap" functionality
        let closeTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.viewWithTag(998)!.addGestureRecognizer(closeTap)
        chatView.addGestureRecognizer(closeTap)
        
        // add swipe gesture to chat
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(chatGesture))
        swipeLeft.direction = .left
        chatView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(chatGesture))
        swipeRight.direction = .right
        chatView.addGestureRecognizer(swipeRight)
        
        // warning label
        warningLabel.text = ""
        
        // backgrounds
        questionCardView.backgroundColor = UIColor(cfgName: "colors.show.overlay")
        winnersView.backgroundColor = UIColor(cfgName: "colors.show.overlay")
        
        // spinner
        spinnerImageView.tintColor = UIColor.white.withAlphaComponent(0.5)
        
        // hide items
        sendButton.isHidden = true
        chatTextField.isHidden = true
        swipeInfoLabel.isHidden = true
        viewersCountLabel.text = ""
        warningLabel.alpha = 0.0
        questionCardView.isHidden = true
        winnersView.isHidden = true
        winnersShareButton.isHidden = true
        
        // countdown timer
        questionCountdownTimer.lineColor = UIColor.white
        questionCountdownTimer.trailLineColor = UIColor(cfgName: "colors.background")
        questionCountdownTimer.labelTextColor = UIColor.white
        questionCountdownTimer.timerFinishingText = nil
        questionCountdownTimer.labelFont = UIFont.systemFont(ofSize: 20.0)
        questionCountdownTimer.delegate = self
        
    }
    
    // MARK: - SRCountdownTimerDelegate
    
    @objc func timerDidStart() {
        self.appIcon.isHidden = true
        questionCountdownTimer.alpha = 0.0
        questionCountdownTimer.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.questionCountdownTimer.alpha = 1.0
        })
    }
    
    @objc func timerDidEnd() {
        UIView.animate(withDuration: 0.2, animations: {
            self.questionCountdownTimer.alpha = 0.0
        }, completion: {_ in
            self.questionCountdownTimer.isHidden = true
            self.appIcon.isHidden = false
        })
    }
    
    // MARK: - Socket
    
    func socketConnect()
    {
        let connectString = String(format:"%@:%@", Config.shared.data["socket.host"]!, Config.shared.data["socket.port"]!)
        socketManager = SocketManager(socketURL: URL(string: connectString)!, config: [
            .log(true),
            .compress,
            .connectParams(["token": Misc.currentPlayer!.token!]),
            .reconnects(true),
            .reconnectWait(3),
            .reconnectAttempts(-1),
            .forceNew(true)
        ])
        socket = socketManager!.defaultSocket
        
        socket!.on(clientEvent: .connect) {data, ack in
            self.socketConnected()
        }
        
        socket!.on(clientEvent: .reconnectAttempt) {data, ack in
            self.socketReconnecting()
        }
        
        socket!.on("watch") {data, ack in
            self.watchOnly()
        }
        
        socket!.on("chat") {data, ack in
            let msg = data[0] as! String
            let user = data[1] as! NSDictionary
            let message = ChatMessage(msg, user)
            self.chatReceived(message)
        }
        
        socket!.on("stats") {data, ack in
            let count = data[0] as! Int
            self.viewersCountLabel.text = self.formatCounter(count)
        }
        
        socket!.on("question") {data, ack in
            let qdata = data[0] as! NSDictionary
            self.showQuestion(qdata)
        }
        
        socket!.on("correct") {data, ack in
            let correct = data[0] as! Int
            let stats = data[1] as! NSDictionary
            self.showCorrect(correct, stats)
        }
        
        socket!.on("winners") {data, ack in
            let amount = data[0] as! Int
            let winners = data[1] as! NSArray
            self.showWinners(amount, winners)
        }
        
        socket!.on("end") {data, ack in
            self.showClose()
        }
        
        socket!.connect()
    }
    
    func socketDisconnect()
    {
        if(socket != nil)
        {
            socket!.disconnect()
            socketManager!.disconnect()
            socket = nil
            socketManager = nil
        }
    }
    
    func socketConnected()
    {
        if(warningLabel.alpha > 0.0)
        {
            showWarning(NSLocalizedString("tr_connected", comment: ""), true, "success")
        }
    }
    
    func socketReconnecting()
    {
        if(warningLabel.alpha == 0.0)
        {
            showWarning(NSLocalizedString("tr_connection_lost", comment: ""), false)
        }
    }
    
    func socketOK() -> Bool
    {
        return socket != nil && socket!.status == .connected
    }
    
    func socketSendChat(_ message: String)
    {
        if(socketOK() && message != "")
        {
            socket!.emit("chat", message)
        }
    }
    
    func socketSendAnswer()
    {
        if socketOK()
        {
            socket!.emitWithAck("answer", self.selectedOption!).timingOut(after: 5) {data in
                let result = data[0] as? Bool ?? false
                // answer was not stored, only reason is out of time
                if(!result)
                {
                    self.tooLate()
                }
            }
        }
    }
    
    func socketSendLife()
    {
        if socketOK()
        {
            socket!.emitWithAck("life").timingOut(after: 5) {data in
                let result = data[0] as? Bool ?? false
                // life used ok
                if result {
                    self.kickIn()
                    self.lives = self.lives - 1
                    self.showWarning(NSLocalizedString("tr_life_used_success", comment: ""), true, "success")
                }
                // life usage failed
                else {
                    self.showWarning(NSLocalizedString("tr_life_used_failure", comment: ""), true)
                }
                
            }
        }
    }
    
    // MARK: - Helpers
    
    func formatCounter(_ count: Int) -> String
    {
        if count < 1000 { return String(format:"%d",count) }
        else if count < 100000 { return String(format:"%.1fK", Float(count)/Float(1000)) }
        else { return String(format:"%.0fK", Float(count)/Float(1000)) }
    }
    
}
