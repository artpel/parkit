//
//  File.swift
//  parkit
//
//  Created by Arthur Péligry on 26/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class NSCustomPersistentContainer: NSPersistentContainer {
    
    override open class func defaultDirectoryURL() -> URL {
        var storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.WhereIsMyBike")
        storeURL = storeURL?.appendingPathComponent("WhereIsMyBike.sqlite")
        return storeURL!
    }
    
}
