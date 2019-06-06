//
//  BikeAnnotation.swift
//  parkit
//
//  Created by Arthur Péligry on 16/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import MapKit
import ChameleonFramework

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
             colorous = UIColor(hexString:"#00cec9")
        } else if type == "moto" {
            colorous = UIColor(hexString:"#6c5ce7")
        } else if type == "mix" {
            colorous = UIColor(hexString:"#0984e3")
        } else if type == "Target" {
            colorous = UIColor(hexString:"#F5C042")
        } else {
            colorous = UIColor(hexString: "#FFFFFF")
        }
        
        if (park == true) {
            colorous = UIColor(hexString: "#EB3637")
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
