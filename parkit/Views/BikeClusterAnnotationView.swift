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
            return UIColor(hexString: "#9CDA85")!.cgColor
        } else if count < 10 {
            return UIColor(hexString: "#B0DA85")!.cgColor
        } else if count < 20 {
            return UIColor(hexString: "#BECF78")!.cgColor
        } else if count < 30 {
            return UIColor(hexString: "#C9D369")!.cgColor
        } else if count < 40 {
            return UIColor(hexString: "#D6E077")!.cgColor
        } else if count < 80 {
            return UIColor(hexString: "#D8C974")!.cgColor
        } else if count < 140 {
            return UIColor(hexString: "#D8AF74")!.cgColor
        } else if count < 300 {
            return UIColor(hexString: "#D89974")!.cgColor
        } else {
            return UIColor(hexString: "#D88674")!.cgColor
        }
    }
    
    func radius(for count: Int) -> CGFloat {
        if count < 5 {
            return 10
        } else if count < 10 {
            return 12
        } else if count < 20 {
            return 14
        } else if count < 30 {
            return 16
        } else if count < 40 {
            return 18
        } else if count < 140 {
            return 20
        } else if count < 300 {
            return 24
        } else {
            return 30
        }
    }
}
