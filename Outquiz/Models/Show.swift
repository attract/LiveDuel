//
//  Show.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 21.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import Foundation

struct Show {
    
    let id: Int
    let schedule: Date
    let amount: Int
    let live: Int
    
    init(_ id: Int, _ scheduleISO8601: String, _ amount: Int, _ live: Int)
    {
        self.id = id
        self.amount = amount
        self.live = live
        
        let formatter = ISO8601DateFormatter()
        self.schedule = formatter.date(from: scheduleISO8601)!
    }
    
    func scheduleFormatted() -> String
    {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        
        if(Calendar.current.isDateInToday(self.schedule))
        {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: self.schedule)
        } else if (Calendar.current.isDateInTomorrow(self.schedule)) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return String(format: "%@, %@", NSLocalizedString("tr_tomorrow", comment: ""), formatter.string(from: self.schedule))
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: self.schedule)
        }
        
        
    }
    
    func amountFormatted() -> String
    {
        return String(format:"%@%d", Config.shared.data["app.currencySymbol"]!, self.amount)
    }
    
}
