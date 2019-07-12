//
//  BikeView.swift
//  parkit
//
//  Created by Arthur Péligry on 16/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import MapKit

class BikeMarkerView: MKMarkerAnnotationView {

    override var annotation: MKAnnotation? {

        willSet {
    
            guard let bikeAnnotation = newValue as? BikeAnnotation else { return }
            
            markerTintColor = bikeAnnotation.markerTintColor
            
            if let imageName = bikeAnnotation.imageName {
                glyphImage = UIImage(named: imageName)
            } else {
                glyphImage = nil
            }
            
        }
    }
}
