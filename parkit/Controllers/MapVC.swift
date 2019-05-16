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

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
 
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
        
        let url = "https://opendata.paris.fr/api/records/1.0/search/?dataset=stationnement-voie-publique-emplacements&rows=50&facet=regpri&facet=regpar&facet=typsta&facet=arrond&refine.regpri=2+ROUES"
        
        
        Alamofire.request(url).responseJSON { (responseData) -> Void in
            if let response = responseData.result.value {
                self.placeSpots(spots: JSON(response))
            } else {
                print("Error retrieving token")
            }
            
        }
        
    }
    
    func placeSpots(spots: JSON) {
        
        for (_, subJson) in spots["records"] {
            
            var pinAnnotationView:MKPinAnnotationView!
            
            let coordinates = subJson["geometry"]["coordinates"]
            let type = subJson["fields"]["regpar"].string!
            let hello = MKPointAnnotation()
            hello.coordinate = CLLocationCoordinate2D(latitude: coordinates[1].double!, longitude: coordinates[0].double!)
            
            if type == "Motos" {
                pinAnnotationView = MKPinAnnotationView(annotation: hello, reuseIdentifier: "pinMotos")
            } else if type == "Vélos" {
                pinAnnotationView = MKPinAnnotationView(annotation: hello, reuseIdentifier: "pinVelos")
            } else {
                pinAnnotationView = MKPinAnnotationView(annotation: hello, reuseIdentifier: "pinMixte")
            }
            
            

            carte.addAnnotation(pinAnnotationView.annotation!)
            
        }
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        
//        
//        
//        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pinVelos")
//
//        annotationView.pinTintColor = UIColor.green
//
//        return annotationView
//    }

}
