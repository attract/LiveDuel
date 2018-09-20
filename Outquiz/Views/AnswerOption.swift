//
//  AnswerOption.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 27.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

protocol AnswerOptionDelegate {
    func canSelectOption() -> Bool
    func optionSelected(_ id: Int) -> Bool
}

class AnswerOption: UIView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var scaleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var scaleWidth: NSLayoutConstraint!
    
    var delegate: AnswerOptionDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = frame.size.height / 2
        titleLabel.font = UIFont.systemFont(ofSize: frame.size.height / 2)
    }
    
    func commonInit()
    {
        self.backgroundColor = UIColor.clear
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapOption))
        addGestureRecognizer(tap)
    }
    
    func reset(_ title: String)
    {
        titleLabel.text = title
        titleLabel.textColor = UIColor.black
        backgroundView.backgroundColor = UIColor.white
        scaleWidth.constant = 0
        scaleView.backgroundColor = UIColor.clear
        scaleView.isHidden = true
        statsLabel.isHidden = true
    }
    
    func stats(_ votes: Int, _ total: Int, _ type: String)
    {
        titleLabel.textColor = UIColor.black
        backgroundView.backgroundColor = UIColor.white
        statsLabel.text = String(format: "%d", votes)
        scaleView.isHidden = false
        statsLabel.isHidden = false
        
        if type == "wrong" || type == "correct" || type == "neutral"
        {
            let color = "colors.answer." + type
            scaleView.backgroundColor = UIColor(cfgName: color)
        }
        
        let percent = total > 0 ? CGFloat(votes) / CGFloat(total) : 0
        scaleWidth.constant = self.frame.width * percent
        
        UIView.animate(withDuration: 1.0, delay: 0.5, options: [.curveEaseOut], animations: {
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func tapOption()
    {
        if(statsLabel.isHidden && delegate != nil && delegate!.canSelectOption())
        {
            if delegate!.optionSelected(tag) {
                UIView.animate(withDuration: 0.2, animations: {
                    self.backgroundView.backgroundColor = UIColor(cfgName: "colors.answer.highlight")
                    self.titleLabel.textColor = UIColor.white
                })
            }
        }
    }
}
