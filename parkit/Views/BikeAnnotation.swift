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
    
    init(title: String, type: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.type = type
        self.coordinate = coordinate
        
        super.init()
    }
    
    var markerTintColor: UIColor  {
        switch type {
        case "Vélos":
            return UIColor(hexString:"#78e08f")
        case "Motos":
            return UIColor(hexString:"#e55039")
        case "Mixte":
            return UIColor(hexString:"#6a89cc")
        default:
            return .red
        }
    }

}
