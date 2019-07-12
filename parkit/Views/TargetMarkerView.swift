//
//  TargetMarkerView.swift
//  parkit
//
//  Created by Arthur Péligry on 12/07/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import MapKit

class TargetMarkerView: MKMarkerAnnotationView {
    
    override var annotation: MKAnnotation? {
        
        willSet {
            
            guard let target = newValue as? TargetAnnotation else { return }
            
            markerTintColor = target.markerTintColor
            
            if let imageName = target.imageName {
                glyphImage = UIImage(named: imageName)
            } else {
                glyphImage = nil
            }
            
        }
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh

    }

}
