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

    var title: String?
    var type: String
    var coordinate: CLLocationCoordinate2D
    var size: Double
    var address: String
    
    init(type: String, coordinate: CLLocationCoordinate2D, size: Double, address: String) {
//        self.title = title
        self.type = type
        self.coordinate = coordinate
        self.size = size
        self.address = address
        
        super.init()
    }
    
    var markerTintColor: UIColor  {
        switch type {
        case "Vélos":
            return UIColor(hexString:"#00cec9")
        case "Motos":
            return UIColor(hexString:"#6c5ce7")
        case "Mixte":
            return UIColor(hexString:"#0984e3")
        default:
            return .red
        }
    }
    
    var imageName: String? {
        if type == "Vélos" { return "bike" }
        if type == "Motos" { return "moto" }
        return "mix"
    }


}
