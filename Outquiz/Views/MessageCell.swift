//
//  MessageCell.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 26.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var avatarImage: RoundedImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func update(_ message: ChatMessage)
    {
        message.setAvatar(avatarImage)
        messageLabel.attributedText = message.getAttributedString()
    }

}
