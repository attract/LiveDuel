//
//  MessagesDataSource.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 26.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import UIKit

class Chat: NSObject, UITableViewDelegate, UITableViewDataSource
{
    // MARK: - Properties
    var tableView: UITableView?
    var messages: [ChatMessage] = []
    
    // MARK: - Init
    
    convenience init(tableView: UITableView)
    {
        self.init()
        self.tableView = tableView
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        self.tableView!.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
    }
    
    // MARK: - Messages
    
    func add(_ message: ChatMessage)
    {
        messages.insert(message, at: 0)
        tableView?.insertRows(at: [IndexPath(row:0, section:0)], with: .right)
        
        if(messages.count == 21)
        {
            messages.remove(at: 20)
            tableView?.deleteRows(at: [IndexPath(row:20, section:0)], with: .none)
        }
    }
    
    // MARK: - UITableViewDatasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        
        let msg = messages[indexPath.row]
        cell.update(msg)
        
        return cell
    }
}
