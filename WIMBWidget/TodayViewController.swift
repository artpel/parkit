//
//  TodayViewController.swift
//  WIMBWidget
//
//  Created by Arthur Péligry on 26/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import NotificationCenter
import MapKit
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding, MKMapViewDelegate {
    
    @IBOutlet weak var imageCarte: UIImageView!
    
    
    @IBOutlet weak var carte: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSize(width:self.view.frame.size.width, height:210)
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded

        
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        let latlon = self.someOtherFunction()
        let lat = latlon.0
        let lon = latlon.1
        
        // Set the region of the map that is rendered.
        let location = CLLocationCoordinate2DMake(lat!, lon!) // Apple HQ
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
        mapSnapshotOptions.region = region

        
        mapSnapshotOptions.scale = UIScreen.main.scale
        
        // Set the size of the image output.
        mapSnapshotOptions.size = self.preferredContentSize
        
        let rect = self.imageCarte.bounds
        
        let snapshot = MKMapSnapshotter(options: mapSnapshotOptions)
        snapshot.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                print("\(error)")
                return
            }
            
            UIGraphicsBeginImageContextWithOptions(mapSnapshotOptions.size, true, 0)
            snapshot.image.draw(at: .zero)
            
            let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            let pinImage = pinView.image
            
            var point = snapshot.point(for: mapSnapshotOptions.region.center)
            
            if rect.contains(point) {
                let pinCenterOffset = pinView.centerOffset
                point.x -= pinView.bounds.size.width / 2
                point.y -= pinView.bounds.size.height / 2
                point.x += pinCenterOffset.x
                point.y += pinCenterOffset.y
                pinImage?.draw(at: point)
            }
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            // do whatever you want with this image, e.g.
            
            DispatchQueue.main.async {
                self.imageCarte.image = image
            }
        }
        
        

    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        
        
        completionHandler(NCUpdateResult.newData)
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
    
    func someOtherFunction() -> (Double?, Double?) {
        // get the managed context
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Park")
        fetchRequest.predicate = NSPredicate(format: "park = %@", NSNumber(value: true))
        
        do {
            
            let parks = try managedContext.fetch(fetchRequest)
            
            let lat = parks[0].value(forKeyPath: "lat")! as? Double
            let long = parks[0].value(forKeyPath: "lon") as? Double
            return (lat!, long!)
            
        } catch {
            return (0,0)
        }
        // have fun
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: 210)
        }else if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 350)
        }
    }

    
}
