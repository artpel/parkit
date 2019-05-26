//
//  WhereIsMyBikeHandler.swift
//  parkit
//
//  Created by Arthur Péligry on 26/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation

class WhereIsMyBikeIntentHandler: NSObject, WhereIsMyBikeIntentHandling {
    
    func confirm(intent: WhereIsMyBikeIntent, completion: @escaping (WhereIsMyBikeIntentResponse) -> Void) {
//        let mapIntent = MapIntentController()
//
        completion(WhereIsMyBikeIntentResponse(code: .ready, userActivity: nil))
        

    }
    
    func handle(intent: WhereIsMyBikeIntent, completion: @escaping (WhereIsMyBikeIntentResponse) -> Void) {

        completion(WhereIsMyBikeIntentResponse(code: .success, userActivity: nil))
        
    }
}
