//
//  SettingsVC.swift
//  parkit
//
//  Created by Arthur Péligry on 25/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import CoreData

class SettingsVC: UIViewController {

    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func resetData(_ sender: Any) {
        resetAllRecords(in: "Park")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set("bike", forKey: "mode")
    }
    
    func resetAllRecords(in entity : String) {
        
        
        
        let context = ( UIApplication.shared.delegate as! AppDelegate ).persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do
        {
            try context.execute(deleteRequest)
            try context.save()
        }
        catch
        {
            print ("There was an error")
        }
    }
    
}
