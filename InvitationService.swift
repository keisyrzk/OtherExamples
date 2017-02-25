//
//  InvitationService.swift


import Foundation
import SwiftyJSON
import Alamofire

struct InvitationService: RestAPI
{
    
    func get(_ completionHandler: @escaping (Result<InvitationResponse>) -> ())
    {
        let queryString = "GetMyFriendInvites"
        
        Alamofire.request(URL + queryString, method: .get, parameters: nil, encoding: URLEncoding.default, headers: header).responseJSON { (response:DataResponse<Any>) in

                if let result = response.result.value
                {
                    let json = JSON(result)
                    
                    guard let toMeInvitesArray = json["ToMeInvites"].array else {
                        let error = APIError()
                        error.message = "Can't get user invites"
                        let result = Result<InvitationResponse>.failure(error)
                        completionHandler(result)
                        return
                    }
                    
                    var toMeInvites: [User] = [User]()
                    toMeInvitesArray.forEach({ (json) in
                        toMeInvites.append(
                            User.parseJSON(json: json)
                        )
                    })
                    
                    guard let myInvitesArray = json["FromMeInvites"].array else {
                        let error = APIError()
                        error.message = "Can't get user invites"
                        let result = Result<InvitationResponse>.failure(error)
                        completionHandler(result)
                        return
                    }
                    
                    var myInvites: [User] = [User]()
                    myInvitesArray.forEach({ (json) in
                        myInvites.append(
                            User.parseJSON(json: json)
                        )
                    })
                    
                    var invitationResponse = InvitationResponse()
                    invitationResponse.toMeInvities = toMeInvites
                    invitationResponse.myInvities = myInvites
                    let result = Result.success(invitationResponse)
                    completionHandler(result)
                }
                else
                {
                    let error = APIError()
                    error.message = "Can't get user invites"
                    let result = Result<InvitationResponse>.failure(error)
                    completionHandler(result)
                }
        }
    }
    
    func create(params: FriendParam, completionHandler: @escaping (Result<EmptySuccessResponse>) -> ())
    {
        let queryString = "AddFriend"
        
        guard let facebookID = params.facebookFriendID else {
            let error = APIError()
            error.message = "FacebookFriendID can't be empty"
            let result = Result<EmptySuccessResponse>.failure(error)
            completionHandler(result)
            return
        }
        
        let params = [
            "UserName" : facebookID
        ]
        
        Alamofire.request(URL + queryString, method: .post, parameters: params, encoding: URLEncoding.default, headers: header).responseJSON { (response:DataResponse<Any>) in

                if let result = response.result.value
                {
                    let json = JSON(result)
                    
                    if self.isSuccess(json)
                    {
                        /// GOOGLE ANALYTICS ///
                        if let tracker = GAI.sharedInstance().defaultTracker
                        {
                            tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "type", action: "added", label: "Friend", value: nil).build() as [NSObject : AnyObject])
                        }
                        /// GOOGLE ANALYTICS ///
                        
                        let result = Result.success(EmptySuccessResponse())
                        completionHandler(result)
                    }
                    else
                    {
                        let error = APIError()
                        error.message = "Can't add friend"
                        let result = Result<EmptySuccessResponse>.failure(error)
                        completionHandler(result)
                    }
                }
                else
                {
                    let error = APIError()
                    error.message = "Can't add friend"
                    let result = Result<EmptySuccessResponse>.failure(error)
                    completionHandler(result)
                }
        }
    }
    
    func acceptFriend(params: FriendParam, completionHandler: @escaping (Result<EmptySuccessResponse>) -> ())
    {
        let queryString = "AcceptFriend"
        
        guard let user = params.user else {
            let error = APIError()
            error.message = "User can't be empty"
            let result = Result<EmptySuccessResponse>.failure(error)
            completionHandler(result)
            return
        }
        
        guard let userID = user.userId else {
            let error = APIError()
            error.message = "UserId can't be empty"
            let result = Result<EmptySuccessResponse>.failure(error)
            completionHandler(result)
            return
        }
        
        let params = [
            "UserId" : userID
        ]
        
        Alamofire.request(URL + queryString, method: .post, parameters: params, encoding: URLEncoding.default, headers: header).responseJSON { (response:DataResponse<Any>) in

                if let result = response.result.value
                {
                    let json = JSON(result)
                    
                    if self.isSuccess(json)
                    {
                        
                        /// GOOGLE ANALYTICS ///
                        if let tracker = GAI.sharedInstance().defaultTracker
                        {
                            tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "type", action: "accepted", label: "Friend", value: nil).build() as [NSObject : AnyObject])
                        }
                        /// GOOGLE ANALYTICS ///
                        
                        let result = Result.success(EmptySuccessResponse())
                        completionHandler(result)
                    }
                    else
                    {
                        let error = APIError()
                        error.message = "Can't accept invite"
                        let result = Result<EmptySuccessResponse>.failure(error)
                        completionHandler(result)
                    }
                }
                else
                {
                    let error = APIError()
                    error.message = "Can't accept invite"
                    let result = Result<EmptySuccessResponse>.failure(error)
                    completionHandler(result)
                }
        }
    }
}
