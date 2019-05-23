//
//  ClusterAnnotationView.swift
//  parkit
//
//  Created by Arthur Péligry on 22/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import MapKit
import Cluster
import ChameleonFramework

class BikeClusterAnnotationView: ClusterAnnotationView {
    
    override func configure() {
        super.configure()
        
        guard let annotation = annotation as? ClusterAnnotation else { return }
        let count = annotation.annotations.count
        let diameter = radius(for: count) * 2
        let bgColor = color(for: count)
        
        self.frame.size = CGSize(width: diameter, height: diameter)
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
        self.layer.backgroundColor = bgColor
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.5
    }
    
    func color(for count: Int) -> CGColor {
        if count < 5 {
            return UIColor(hexString: "#78e08f")!.cgColor
        } else if count < 10 {
            return UIColor(hexString: "#fad390")!.cgColor
        } else {
            return UIColor(hexString: "#E68364")!.cgColor
        }
    }
    
    func radius(for count: Int) -> CGFloat {
        if count < 5 {
            return 12
        } else if count < 10 {
            return 16
        } else {
            return 20
        }
    }
}
