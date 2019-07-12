//
//  TargetAnnotation.swift
//  parkit
//
//  Created by Arthur Péligry on 12/07/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import MapKit

class TargetAnnotation: NSObject, MKAnnotation {
    
    var type: String
    var coordinate: CLLocationCoordinate2D
    
    init(_ type: String, _ coordinate: CLLocationCoordinate2D) {
        self.type = type
        self.coordinate = coordinate
        super.init()
    }    
    
    var markerTintColor: UIColor  {
        return UIColor(named: "appMainColor")!
    }
    
    var imageName: String? {
        return "pin"
    }
    
    
}
