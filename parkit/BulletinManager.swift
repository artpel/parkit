//
//  BulletinManager.swift
//  parkit
//
//  Created by Arthur Péligry on 23/07/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import Foundation
import BLTNBoard

struct BulletinManager {
    
    static var bulletinManager: BLTNItemManager = {
        let modeSelector = BLTNPageItem(title: "Bienvenue dans ParkIt!")
        modeSelector.descriptionText = "Conduisez-vous un vélo où un scooter/moto ? Vous pourrez modifier ce choix par la suite"
        modeSelector.appearance.titleFontSize = 20
        modeSelector.appearance.descriptionFontSize = 16
        
        modeSelector.actionButtonTitle = "🚲 Un vélo"
        modeSelector.appearance.actionButtonColor = UIColor.clear
        modeSelector.appearance.actionButtonTitleColor = UIColor(named: "appMainColor")!
        modeSelector.appearance.actionButtonFontSize = 16
        
        modeSelector.alternativeButtonTitle = "🛵 Un scooter/moto"
        modeSelector.appearance.alternativeButtonTitleColor = UIColor(named: "appMainColor")!
        modeSelector.appearance.alternativeButtonFontSize = 16
        
        modeSelector.requiresCloseButton = false
        modeSelector.isDismissable = false
        
        let loc = BLTNPageItem(title: "Activer la localisation")
        loc.descriptionText = "Cliquez sur le bouton ci-dessous pour nous autoriser à vous localiser afin de trouver les spots de parking près de vous.\nCes données ne quittent pas votre iPhone."
        loc.appearance.titleFontSize = 20
        loc.appearance.descriptionFontSize = 14
        
        loc.actionButtonTitle = "Activer"
        loc.appearance.actionButtonColor = UIColor(named: "appMainColor")!
        
        loc.alternativeButtonTitle = "Non, merci"
        loc.appearance.alternativeButtonTitleColor = UIColor(named: "appMainColor")!
        
        loc.requiresCloseButton = false
        loc.isDismissable = false
        
        modeSelector.next = loc
      
        modeSelector.actionHandler = { (item: BLTNActionItem) in
            print("coucou")
            item.manager?.displayActivityIndicator()
            MapVC().modeSelected("bike")
            item.manager?.displayNextItem()
        }
        
        modeSelector.alternativeHandler = { (item: BLTNActionItem) in
            item.manager?.displayActivityIndicator()
            MapVC().modeSelected("moto")
            item.manager?.displayNextItem()
        }
        
        loc.actionHandler = { (item: BLTNActionItem) in
            item.manager?.displayActivityIndicator()
            MapVC().locActivated(true)
            item.manager?.dismissBulletin(animated: true)
        }
        
        loc.alternativeHandler = { (item: BLTNActionItem) in
            item.manager?.dismissBulletin(animated: true)
            MapVC().locActivated(true)

        }
        
        let rootItem: BLTNItem = modeSelector
        let bulletinItemManager = BLTNItemManager(rootItem: rootItem)
        bulletinItemManager.backgroundViewStyle = .blurredDark
        
        return bulletinItemManager
    }()
    
}
