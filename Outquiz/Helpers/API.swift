//
//  API.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 09.03.2018.
//  Copyright © 2018 UniProgy s.r.o. All rights reserved.
//

import Foundation
import Alamofire

struct APIRequest
{
    let path: String
    let method: HTTPMethod
    let parameters: Parameters?
    let autheticate: Bool
    let success: (_ data: NSDictionary) -> Void
    let failure: (_ code: Int, _ errors: [String]) -> Void
    
    init(_ path: String, _ method: HTTPMethod, _ parameters: Parameters?, _ autheticate: Bool, _ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void)
    {
        self.path = path
        self.method = method
        self.parameters = parameters
        self.autheticate = autheticate
        self.success = success
        self.failure = failure
    }
}

class API
{
    static private var _isRefreshing = false
    static private var _queue: [APIRequest] = [APIRequest]()
    
    // MARK: - Helpers
    
    class private func _host() -> String
    {
        return Config.shared.data["app.host"]! + "/api"
    }
    
    class private func _headers(_ withAuth: Bool) -> HTTPHeaders
    {
        var hs: HTTPHeaders = [
            "Accept": "application/json"
        ]
        if(withAuth && Misc.currentPlayer?.token != nil)
        {
            hs["Authorization"] = "Bearer " + Misc.currentPlayer!.token!
        }
        return hs
    }
    
    class private func _runQueue()
    {
        _queue.forEach { self._run($0) }
        _queue.removeAll()
    }
    
    class private func _run(_ request: APIRequest)
    {
        if(self._isRefreshing)
        {
            _queue.append(request)
            return
        }
        
        Alamofire.request(self._host() + request.path, method: request.method, parameters: request.parameters, encoding: URLEncoding(destination: .methodDependent), headers: self._headers(request.autheticate)).responseJSON { response in
            
            let statusCode = response.response?.statusCode
            // Unauthenticated
            if(statusCode == 401)
            {
                _queue.append(request)
                // try to refresh token
                if(!self._isRefreshing)
                {
                    self._refresh()
                }
            } else {
                self._handle(response, request.success, request.failure)
            }
        }
    }
    
    class private func _handle(_ response: DataResponse<Any>, _ success: (_ data: NSDictionary) -> Void, _ failure: (_ code: Int, _ errors: [String]) -> Void)
    {
        print("Request: \(String(describing: response.request))")   // original url request
        print("Response: \(String(describing: response.response))") // http url response
        
        if let info = response.data, let utf8Text = String(data: info, encoding: .utf8) {
            print("Data: \(utf8Text)") // original server data as UTF8 string
        }
        
        let statusCode = response.response?.statusCode
        
        var data = NSDictionary()
        if let result = response.result.value {
            data = result as! NSDictionary
        }
        
        if(statusCode == 200)
        {
            success(data)
        } else {
            var errors = [String]()
            if(data["errors"] != nil)
            {
                // array
                if data["errors"] is [String]
                {
                    errors = data["errors"] as! [String]
                // or dictionary
                } else {
                    for(_,errs) in data["errors"] as! NSDictionary
                    {
                        for err in errs as! [String]
                        {
                            errors.append(err)
                        }
                    }
                }
            }
            failure(statusCode ?? 500, errors)
        }
    }
    
    // MARK: - Methods
    
    class private func _refresh()
    {
        self._refresh(nil)
    }
    
    class private func _refresh(_ success: (() -> Void)?)
    {
        self._isRefreshing = true
        
        let path = "/refresh"
        
        Alamofire.request(self._host() + path, method: .get, headers: self._headers(true)).responseJSON { response in
            
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            
            if let info = response.data, let utf8Text = String(data: info, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
            
            self._isRefreshing = false
            
            let statusCode = response.response?.statusCode
            // token refresh has failed
            if statusCode == 401 {
                // empty queue
                _queue.removeAll()
                // do complete logout
                Misc.logout()
            } else {
                var data = NSDictionary()
                if let result = response.result.value {
                    data = result as! NSDictionary
                }
                // update player info
                var player = Misc.currentPlayer!
                player.token = data["token"] as? String
                // save as current player
                Misc.currentPlayer = player
                if(success != nil)
                {
                    success!()
                } else {
                    self._runQueue()
                }
            }
        }
    }
    
    class func verify(_ country: String, _ number: String, _ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void)
    {
        let path = "/verify"
        let params: Parameters = [
            "number": number,
            "country": country
        ]
        
        let request = APIRequest(path, .get, params, false, success, failure)
        self._run(request)
    }
    
    class func login(_ type: String, _ id: String, _ verification: String, _ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void )
    {
        let path = "/login"
        let params: Parameters = [
            "channel_type": type,
            "channel_id": id,
            "channel_verification": verification,
            "push_token": Misc.getToken() ?? "",
            "push_type": "ios",
            "country": NSLocale.current.regionCode ?? "",
            "language": NSLocale.current.languageCode ?? ""
        ]
        
        let request = APIRequest(path, .post, params, false, success, failure)
        self._run(request)
        
    }
    
    class func avatar(_ data: Data?, _ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void ) {
        let path = "/avatar"
        
        // uploading an avatar
        if(data != nil)
        {
            Alamofire.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(data!, withName: "avatar", fileName: "avatar.jpeg", mimeType: "image/jpeg")
                },
                to: self._host() + path,
                headers: self._headers(true),
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        
                        // we have to handle token refresh here seperately
                        // because this is a special upload request
                        upload.responseJSON { response in
                            
                            let statusCode = response.response?.statusCode
                            // Unauthenticated
                            if(statusCode == 401)
                            {
                                // try to refresh token
                                self._refresh({() -> Void in
                                    self.avatar(data, success, failure)
                                })
                            } else {
                                self._handle(response, success, failure)
                            }
                        }
                        
                        
                    case .failure(let encodingError):
                        failure(500, [encodingError.localizedDescription])
                    }
                }
            )
        // removing avatar
        } else {
            let request = APIRequest(path, .post, nil, true, success, failure)
            self._run(request)
        }
    }
    
    class func profile(_ username: String, _ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void )
    {
        let path = "/profile"
        let params: Parameters = [
            "username": username
        ]
        
        let request = APIRequest(path, .post, params, true, success, failure)
        self._run(request)
    }
    
    class func home(_ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void )
    {
        let path = "/home"
        let request = APIRequest(path, .get, nil, true, success, failure)
        self._run(request)
    }
    
    class func leaderboard(_ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void )
    {
        let path = "/leaderboard"
        let request = APIRequest(path, .get, nil, true, success, failure)
        self._run(request)
    }
    
    class func player(_ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void )
    {
        let path = "/player"
        let request = APIRequest(path, .get, nil, true, success, failure)
        self._run(request)
    }
    
    class func referral(_ code: String, _ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void)
    {
        let path = "/referral"
        let params: Parameters = [
            "code": code
        ]
        
        let request = APIRequest(path, .get, params, true, success, failure)
        self._run(request)
    }
    
    class func cashout(_ paypal: String, _ success: @escaping (_ data: NSDictionary) -> Void, _ failure: @escaping (_ code: Int, _ errors: [String]) -> Void)
    {
        let path = "/cashout"
        let params: Parameters = [
            "paypal": paypal
        ]
        
        let request = APIRequest(path, .post, params, true, success, failure)
        self._run(request)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
