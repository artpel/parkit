//
//  FirstViewController.swift
//  parkit
//
//  Created by Arthur Péligry on 16/04/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import CoreLocation

class FirstViewController: UIViewController, MKMapViewDelegate {

    
    @IBOutlet weak var carte: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCenter()
        getSpots()
        
    }

    func setCenter() {
        
        let initialLocation = CLLocation(latitude: 48.851942, longitude: 2.389628)
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        carte.setRegion(coordinateRegion, animated: true)
        carte.showsUserLocation = true
      
    }
    
    func getSpots() {
        
        let url = "https://opendata.paris.fr/api/records/1.0/search/?dataset=stationnement-voie-publique-emplacements&rows=1000&facet=regpri&facet=regpar&facet=typsta&facet=arrond&refine.regpri=2+ROUES"
        
        Alamofire.request(url).responseJSON { (responseData) -> Void in
            if let response = responseData.result.value {
                self.placeSpots(spots: JSON(response))
            } else {
                print("Error retrieving token")
            }
            
        }
        
    }
    
    func placeSpots(spots: JSON) {
        
        for (key, subJson) in spots["records"] {
            
            let coordinates = subJson["geometry"]["coordinates"]
            print(coordinates[1].double!)
            let hello = MKPointAnnotation()
            hello.coordinate = CLLocationCoordinate2D(latitude: coordinates[1].double!, longitude: coordinates[0].double!)
            carte.addAnnotation(hello)
            
        }
    }
//    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard annotation is MKPointAnnotation else { return nil }
//        
//        let identifier = "Annotation"
//        var annotationView = carte.dequeueReusableAnnotationView(withIdentifier: identifier)
//        
//        if annotationView == nil {
//            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//            annotationView!.canShowCallout = true
//        } else {
//            annotationView!.annotation = annotation
//        }
//        
//        return annotationView
//    }
//    
}
