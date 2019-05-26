//
//  IntentViewController.swift
//  WhereIsMyBikeUI
//
//  Created by Arthur Péligry on 26/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import IntentsUI
import CoreData
import CoreLocation
import MapKit
import os.log

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling, MKMapViewDelegate, CLLocationManagerDelegate {
    
   
    @IBOutlet weak var carte: MKMapView!
    
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configureView(for parameters: Set<INParameter>,
                       of interaction: INInteraction,
                       interactiveBehavior: INUIInteractiveBehavior,
                       context: INUIHostedViewContext,
                       completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        
        guard interaction.intent is WhereIsMyBikeIntent else {
            completion(false, Set(), .zero)
            return
        }
        
        
    
        
        let width = self.extensionContext?.hostedViewMaximumAllowedSize.width ?? 320
        let desiredSize = CGSize(width: width, height: 300)
        
        self.someOtherFunction()
        
        completion(true, parameters, desiredSize)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         let ann = carte.annotations
        carte.removeAnnotations(ann)
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSCustomPersistentContainer(name: "WhereIsMyBike")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                NSLog("QQQ Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func someOtherFunction() {
        // get the managed context
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Park")
        fetchRequest.predicate = NSPredicate(format: "park = %@", NSNumber(value: true))
        
        do {
            
            let parks = try managedContext.fetch(fetchRequest)
            
            let lat = parks[0].value(forKeyPath: "lat")! as? Double
            let long = parks[0].value(forKeyPath: "lon") as? Double
            let address = parks[0].value(forKeyPath: "address")! as? String
            
            let london = MKPointAnnotation()
            
            london.title = address
            london.coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
            carte.addAnnotation(london)
            let regionRadius: CLLocationDistance = 250
            let coordinateRegion = MKCoordinateRegion(center: london.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
            carte.setRegion(coordinateRegion, animated: false)
//            carte.addAn
            
        } catch {
            NSLog("Error catching request")
        }
        // have fun
    }
    
    
   
    
}
