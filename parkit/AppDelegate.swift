//
//  AppDelegate.swift
//  parkit
//
//  Created by Arthur Péligry on 16/04/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import CoreData
import Analytics
import Sentry

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let env = Bundle.main.infoDictionary!["ENV"] as! String
        
        // Sentry
        
        do {
            Client.shared = try Client(options: [
                "dsn": "https://5c1df09a0cec45f6aed363e4d8077dd4@sentry.io/1468256",
                "environment": env])
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("\(error)")
        }
        
        // Segment
        
        var segmentKey: String
        
        switch env {
        case "prod":
            segmentKey = "qA1M0vzRM4NJDwVeIEsGPffAPb0oAXtc"
        case "debug":
            segmentKey = "VaXs1sh9PkWa4PqLyv11wyiirV2INFgg"
        default:
            segmentKey = "qA1M0vzRM4NJDwVeIEsGPffAPb0oAXtc"
        }
        
        let config = SEGAnalyticsConfiguration(writeKey: segmentKey)
        SEGAnalytics.setup(with: config)
        
        // Removing UIConstraits logs
        
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
       
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
       
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
       
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
       
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        self.saveContext()
       
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSCustomPersistentContainer(name: "WhereIsMyBike")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


}

