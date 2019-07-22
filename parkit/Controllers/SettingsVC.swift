//
//  SettingsVC.swift
//  parkit
//
//  Created by Arthur Péligry on 25/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import CoreData
import FontAwesome_swift
import Analytics

class SettingsVC: UIViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func didChangeMode(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex{
        case 0:
            UserDefaults.standard.set("bike", forKey: "mode")
            SEGAnalytics.shared().track("Mode changed", properties: [
                "mode": "bike"
                ])
        case 1:
            UserDefaults.standard.set("moto", forKey: "mode")
            SEGAnalytics.shared().track("Mode changed", properties: [
                "mode": "moto"
                ])
        default:
            UserDefaults.standard.set("bike", forKey: "mode")
            SEGAnalytics.shared().track("Mode changed", properties: [
                "mode": "bike"
                ])
        }
        
        resetAllRecords(in: "Spot")
        
    }
    @IBOutlet weak var modeSelector: UISegmentedControl!
    
    @IBAction func closeSettings(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBOutlet weak var closeSettings: UIButton!
    @IBAction func resetData(_ sender: Any) {
        resetAllRecords(in: "Spot")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setButtonsIcons()
        
        if let mode = UserDefaults.standard.value(forKey: "mode") as? String {
            if mode == "bike" {
                modeSelector.selectedSegmentIndex = 0
            } else {
                modeSelector.selectedSegmentIndex = 1
            }
        }
        
        
    }
    
    func setButtonsIcons() {
        
        closeSettings.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: FontAwesomeStyle.regular)
        closeSettings.setTitle(String.fontAwesomeIcon(name: .timesCircle), for: .normal)
    }
    
    func resetAllRecords(in entity : String) {
        
        let context = ( UIApplication.shared.delegate as! AppDelegate ).persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do
            {
                try context.execute(deleteRequest)
                try context.save()
                SEGAnalytics.shared().track("Core Data reset", properties: [
                    "mode": UserDefaults.standard.string(forKey: "mode")
                    ])
            }
        catch
            {
                print ("There was an error")
            }
    }
    
}
