//
//  Animations.swift
//  parkit
//
//  Created by Arthur Péligry on 23/07/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import Spring

struct Animations {
    static func squeeze(_ mode: String = "in", vue: SpringView) {
        
        vue.isHidden = false
        vue.animation = "squeezeUp"
        vue.curve = "easeIn"
        vue.duration = 0.8
        vue.animate()
        
    }
}
