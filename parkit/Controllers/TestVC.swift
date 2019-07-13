//
//  TestVC.swift
//  parkit
//
//  Created by Arthur Péligry on 29/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData

class TestVC: UIViewController {
    
    var mode = "bike"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        createGeoJSON(getSpotsFromCoreData(mode))

    }
    
    func createGeoJSON(_ spots: [Any]) {
        
        var parks = [[String: Any]]()
        
        for park in spots as! [NSManagedObject] {
            
            let type = park.value(forKeyPath: "type") as? String
            let address = park.value(forKeyPath: "address") as? String
            let size = park.value(forKeyPath: "size") as? Double
            let lat = park.value(forKeyPath: "lat")! as? Double
            let long = park.value(forKeyPath: "lon") as? Double
            let objectId = park.value(forKeyPath: "objectId") as? String
            let park = park.value(forKeyPath: "park") as? Bool
            
            let singlePark = [
                "type": "Feature",
                "properties": [
                    "recordid": objectId!,
                    "size": size!,
                    "address": address!,
                    "type": type!,
                    "coordinates": [
                        "latitude": lat!,
                        "longitude": long!
                    ],
                    "latitude": lat!,
                    "longitude": long!,
                    "park": park!
                ],
                "geometry": [
                    "type": "Point",
                    "coordinates": [
                        lat!,
                        long!
                    ]
                ]
                ] as [String : Any]
            
            parks.append(singlePark)
            
            
            if mode == "bike" && type! == "bike" || type! == "mix" {
                
            } else if mode == "moto" && type! == "moto" || type! == "mix" {
                
            }
        }
        
        var jsonArray: JSON = [
            "type": "FeatureCollection",
            "features": parks
        ]
        
        print(jsonArray)
        
        
    }
    
    
    func getSpotsFromCoreData(_ mode: String, _ park: Bool = false) -> [Any] {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Spot")
        var predicates: [NSPredicate] = []
        
        if park {
            predicates.append(NSPredicate(format: "park = %@", NSNumber(value: false)))
        }
        
        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        fetchRequest.predicate = andPredicate
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            
            return result
        } catch {
            return []
        }
        
    }

}
