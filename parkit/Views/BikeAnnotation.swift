//
//  BikeAnnotation.swift
//  parkit
//
//  Created by Arthur Péligry on 16/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import MapKit

class BikeAnnotation: NSObject, MKAnnotation {

    var type: String
    var coordinate: CLLocationCoordinate2D
    var size: Double
    var address: String
    var indexPark: String
    var park:Bool = false
    
    init(_ type: String, _ coordinate: CLLocationCoordinate2D, _ size: Double, _ address: String, _ indexPark: String, _ park: Bool) {
        self.type = type
        self.coordinate = coordinate
        self.size = size
        self.address = address
        self.indexPark = indexPark
        self.park = park
        super.init()
    }
    

    var markerTintColor: UIColor  {
        
        var colorous: UIColor
        
        if type == "bike" {
            colorous = UIColor(named: "bikeColor")!
        } else if type == "moto" {
            colorous = UIColor(named: "motoColor")!
        } else if type == "mix" {
            colorous = UIColor(named: "mixColor")!
        } else if type == "Target" {
            colorous = UIColor(named: "appMainColor")!
        } else {
            colorous = UIColor.white
        }
        
        if (park == true) {
            colorous = UIColor(named: "parkColor")!
        }

        return colorous
    }
    
    var imageName: String? {
        if type == "Target" { return "pin" }
        if type == "bike" { return "bike" }
        if type == "moto" { return "moto" }
        return "mix"
    }


}
