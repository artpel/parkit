//
//  MapVC.swift
//  parkit
//
//  Created by Arthur Péligry on 16/04/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
//import IntentsUI
//import Intents
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView
import Cluster
import SnapKit
import FontAwesome_swift
import Spring
import GestureRecognizerClosures
import BLTNBoard
import Mapbox

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var addToSiriButton: UIView!
    @IBOutlet weak var resultView: UIVisualEffectView!
    @IBOutlet weak var carte: MKMapView!
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var tooltipItinerary: SpringView!
    @IBOutlet weak var tooltipTitle: UILabel!
    @IBOutlet weak var tooltipAddress: UILabel!
    @IBOutlet weak var tooltipTravelTime: UILabel!
    @IBOutlet weak var tooltipTransportModeView: UIView!
    @IBOutlet weak var tooltipTransportIcon: UIImageView!
    @IBOutlet weak var tooltipSize: UILabel!
    @IBOutlet weak var tooltipItineraryView: UIView!
    @IBOutlet weak var tooltipSizeView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: NVActivityIndicatorView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var legendView: SpringView!
    @IBOutlet weak var legendDot1View: UIView!
    @IBOutlet weak var legendDot2View: UIView!
    @IBOutlet weak var legendLabel1: UILabel!
    @IBOutlet weak var legendLabel2: UILabel!
    @IBOutlet weak var locationButtonView: SpringView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var findMyRideView: SpringView!
    @IBOutlet weak var searchIcon: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var parkedBtn: UIButton!
    @IBOutlet weak var addToSiriView: UIView!
    @IBOutlet weak var searchResultsView: UIVisualEffectView!
    @IBOutlet weak var searchResultsTableView: UITableView!
    
    @IBAction func findMyRide(_ sender: Any) {
        
        let parkedSpot = getSpotsFromCoreData(mode!, true) as! [NSManagedObject]
        
        if parkedSpot != [] {
            
            let type = parkedSpot[0].value(forKeyPath: "type") as? String
            let address = parkedSpot[0].value(forKeyPath: "address") as? String
            let size = parkedSpot[0].value(forKeyPath: "size") as? Double
            let lat = parkedSpot[0].value(forKeyPath: "lat")! as? Double
            let long = parkedSpot[0].value(forKeyPath: "lon") as? Double
            let objectId = parkedSpot[0].value(forKeyPath: "objectId") as? String
            let parked = parkedSpot[0].value(forKeyPath: "park") as? Bool
            
            let annotation = BikeAnnotation(type!, CLLocationCoordinate2D(latitude: lat!, longitude: long!), size!, address!, objectId!, parked!)
            showTooltip(annotation: annotation)
            let myLocation = CLLocation(latitude: lat!, longitude: long!)
            calculateInterary(destination: myLocation.coordinate)
        } else {
            let alert = UIAlertController(title: "Aucun emplacement enregistré", message: "Vous devez d'abord garer votre deux-roues pour pouvoir le retrouver !", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    
    }
    
    @IBAction func textFieldEditingDidChange(_ sender: Any) {
        self.resultView.isHidden = false
        searchCompleter.queryFragment = searchField.text!
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        if self.targetAnnotation != nil {
            self.carte.removeAnnotation(self.targetAnnotation!)
        }
        
        return true
    }
    
    @IBAction func locationButtonPressed(_ sender: Any) {
        setCenter()
    }
    
    @IBAction func parkedButton(_ sender: UIButton) {
        if sender.title(for: .normal) == "Je suis parti" {
            self.parkMyRide(false)
        } else {
            self.parkMyRide(true)
        }
    }
    
    @IBAction func openInMapsButton(_ sender: Any) {
        let mode = UserDefaults.standard.string(forKey: "mode") ?? "bike"
        openInMaps(annotation: selectedAnnotation!, mode: mode)
        
    }

    let locationManager = CLLocationManager()
    var selectedAnnotation: BikeAnnotation?
    var targetAnnotation: TargetAnnotation?
    
    var clusterManager = ClusterManager()
    
    lazy var bulletinManager: BLTNItemManager = {
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
            item.manager?.displayActivityIndicator()
            UserDefaults.standard.set("bike", forKey: "mode")
            self.mode = UserDefaults.standard.string(forKey: "mode")
            self.getSpots()
            item.manager?.displayNextItem()
        }
        
        modeSelector.alternativeHandler = { (item: BLTNActionItem) in
            item.manager?.displayActivityIndicator()
            UserDefaults.standard.set("moto", forKey: "mode")
            self.mode = UserDefaults.standard.string(forKey: "mode")
            self.getSpots()
            item.manager?.displayNextItem()
        }
        
        loc.actionHandler = { (item: BLTNActionItem) in
            item.manager?.displayActivityIndicator()
            self.getUserLocation()
            self.setLegend()
            item.manager?.dismissBulletin(animated: true)
            UserDefaults.standard.set(true, forKey: "onboarded")
        }
        
        loc.alternativeHandler = { (item: BLTNActionItem) in
            item.manager?.dismissBulletin(animated: true)
            self.setLegend()
            UserDefaults.standard.set(true, forKey: "onboarded")
        }
        
        let rootItem: BLTNItem = modeSelector
        
        return BLTNItemManager(rootItem: rootItem)
    }()
    
    var mode: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Views
        
        setButtonsIcons()
        addToSiriView.roundView(8, true)
        tooltipItinerary.roundView(8, true)
        loadingView.roundView(8, true)
        tooltipSizeView.roundView(4, false)
        tooltipItineraryView.roundView(4, false)
        tooltipTransportModeView.roundView(4, false)
        locationButtonView.roundView(8, true)
        searchView.roundView(8, true)
        settingsView.roundView(8, true)
        findMyRideView.roundView(8, true)
        legendView.roundView(8, true)
        
        loadingView.isHidden = true
        tooltipItinerary.isHidden = true
        resultView.isHidden = true
        addToSiriView.isHidden = true
        
        // Delegates & Actions
        
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(textFieldEditingDidChange), for: UIControl.Event.editingChanged)
        searchCompleter.delegate = self
        
        tooltipItinerary.onSwipeDown { _ in
            
            self.deleteRoute(self.carte)
            self.tooltipItinerary.isHidden = true
            self.setViewsAtBottom(vues: [self.locationButtonView, self.legendView, self.findMyRideView])
        }
        
        // Constraintes
        
        setViewsAtBottom(vues: [locationButtonView, legendView, findMyRideView])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if UserDefaults.standard.string(forKey: "onboarded") != nil {
            mode = UserDefaults.standard.string(forKey: "mode")
            setLegend()
            self.setCenter()
            if isCoreDataEmpty() {
                getSpots()
            } else {
                setSpots(getSpotsFromCoreData(mode!))
            }
        } else {
            if UserDefaults.standard.string(forKey: "onboarded") == nil {
                bulletinManager.backgroundViewStyle = .blurredDark
                bulletinManager.showBulletin(above: self)
                print("coucou")
            }
        }
    }
    
    func setButtonsIcons() {
        locationButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 15, style: FontAwesomeStyle.solid)
        locationButton.setTitle(String.fontAwesomeIcon(name: .locationArrow), for: .normal)
        settingsButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 15, style: FontAwesomeStyle.solid)
        settingsButton.setTitle(String.fontAwesomeIcon(name: .cog), for: .normal)
        searchIcon.titleLabel?.font = UIFont.fontAwesome(ofSize: 15, style: FontAwesomeStyle.solid)
        searchIcon.setTitle(String.fontAwesomeIcon(name: .search), for: .normal)
    }

    func setViewsAtBottom(vues: [UIView]) {
        for vue in vues {
            vue.snp.remakeConstraints { (make) -> Void in
                let superview = self.view
                make.bottom.equalTo(superview!.safeAreaLayoutGuide.snp.bottom).offset(-15)
            }
        }
    }
    
    func setLegend() {
        
        if self.mode == "bike" {
            legendDot1View.backgroundColor = UIColor(named: "bikeColor")
            legendLabel1.text = "Vélos"
        } else {
            legendDot1View.backgroundColor = UIColor(named: "motoColor")
            legendLabel1.text = "Motos"
        }
        legendDot1View.roundView(4, false)
        legendDot2View.roundView(4, false)
        legendDot2View.backgroundColor = UIColor(named: "mixColor")!
        legendLabel2.text = "Mixte"
        
    }
    
    func toogleActivityIndicator(status: String) {
        
        switch status {
        case "on":
            loadingView.isHidden = false
            loadingIndicator.startAnimating()
        case "off":
            loadingView.isHidden = true
            loadingIndicator.stopAnimating()
        default:
            break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.resultView.isHidden = true
        self.view.endEditing(true)
    }
    
    // Core Data
    
    func getSpotsFromCoreData(_ mode: String, _ park: Bool = false) -> [Any] {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Spot")
        var predicates: [NSPredicate] = []
        
        if park {
            predicates.append(NSPredicate(format: "park = %@", NSNumber(value: park)))
        }

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        fetchRequest.predicate = andPredicate
        
        do {
            let result = try managedContext.fetch(fetchRequest)

            return result
        } catch {
            return []
        }
        
    }
    
    func deleteSpotsFromCoreData(_ all: Bool = false, _ id : String = "0") {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Park")
        
        if all != true {
            let predicate = NSPredicate(format: "objectId = %@", id)
            fetchRequest.predicate = predicate
        }
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            for result in results as! [NSManagedObject] {
                managedContext.delete(result)
            }
            do {
                try managedContext.save()
            } catch { }
        } catch { }
        
    }
    
    func saveInCoreData(data: JSON) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.newBackgroundContext()
        let entity = NSEntityDescription.entity(forEntityName: "Spot", in: managedContext)!
        
        for (_, subJson) in data {
            
            let park = NSManagedObject(entity: entity, insertInto: managedContext)
            
            let type = subJson["type"].string!
            let address = subJson["address"].string!
            let size = subJson["size"].double!
            let lat = Double(subJson["coordinates"]["lat"].string!)!
            let long = Double(subJson["coordinates"]["lon"].string!)!
            let recordId = subJson["recordid"].string!
            
            park.setValue(type, forKey: "type")
            park.setValue(address, forKey: "address")
            park.setValue(size, forKey: "size")
            park.setValue(lat, forKey: "lat")
            park.setValue(long, forKey: "lon")
            park.setValue(recordId, forKey: "objectId")
            park.setValue(false, forKey: "park")
            
        }
        
        do {
            try managedContext.save()
        } catch  { }
        
        
        setSpots(getSpotsFromCoreData(self.mode!))
        
    }
    
    func isCoreDataEmpty () -> Bool {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return true }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Spot")
        
        do {
            let spots = try managedContext.fetch(fetchRequest)
            if spots.count == 0 {
                return true
            } else {
                return false
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return true
        }
    }
    
    // Annotations
    
    func getSpots() {
        
        let url = "https://parkit-server.herokuapp.com/getParks?mode=\(mode!)"
        
        self.toogleActivityIndicator(status: "on")
        
        Alamofire.request(url).responseJSON { (responseData) -> Void in
            if let response = responseData.result.value {
                self.saveInCoreData(data: JSON(response))
            } else { }

            self.setSpots(self.getSpotsFromCoreData(self.mode!))
            self.toogleActivityIndicator(status: "off")
        }
        
    }

    func setSpots(_ spots: [Any]) {
        
        clusterManager.removeAll()
        
        for park in spots as! [NSManagedObject] {
            
            let type = park.value(forKeyPath: "type") as? String
            let address = park.value(forKeyPath: "address") as? String
            let size = park.value(forKeyPath: "size") as? Double
            let lat = park.value(forKeyPath: "lat")! as? Double
            let long = park.value(forKeyPath: "lon") as? Double
            let objectId = park.value(forKeyPath: "objectId") as? String
            let park = park.value(forKeyPath: "park") as? Bool
            
            if mode == "bike" && type! == "bike" || type! == "mix" {
                let annotation = BikeAnnotation(type!, CLLocationCoordinate2D(latitude: lat!, longitude: long!), size!, address!, objectId!, park!)
                clusterManager.add(annotation)
                clusterManager.reload(mapView: carte)
            } else if mode == "moto" && type! == "moto" || type! == "mix" {
                let annotation = BikeAnnotation(type!, CLLocationCoordinate2D(latitude: lat!, longitude: long!), size!, address!, objectId!, park!)
                clusterManager.add(annotation)
                clusterManager.reload(mapView: carte)
            }
        }

    }

    // Park Ride

    func parkMyRide(_ on: Bool) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let coreDataValue = getSpotsFromCoreData(mode!, true)
        
        if coreDataValue.count != 0 {
            let objectToUpdate = coreDataValue[0] as! NSManagedObject
            objectToUpdate.setValue(false, forKey: "park")
            do {
                try managedContext.save()
            } catch { }
        }
        
        if on {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Spot")
            fetchRequest.predicate = NSPredicate(format: "objectId = %@", selectedAnnotation!.indexPark)
            
            do {
                let results = try managedContext.fetch(fetchRequest)
                let resultat = results[0]
                resultat.setValue(true, forKey: "park")
                
                do {
                    try managedContext.save()
                } catch { }
            } catch { }
        }
        
        setSpots(getSpotsFromCoreData(self.mode!))
        
        self.deleteRoute(self.carte)
        self.tooltipItinerary.isHidden = true
        self.setViewsAtBottom(vues: [self.locationButtonView, self.legendView, self.findMyRideView])
    }
    
    // Itinerary
    
    func calculateInterary(destination: CLLocationCoordinate2D) {
        
        var modeString = ""
        
        let sourceLocation = locationManager.location!.coordinate
        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        if mode == "bike" {
            directionRequest.transportType = .walking
            modeString = "vélo"
        }
        else {
            directionRequest.transportType = .automobile
            modeString = "moto/scooter"
        }
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResonse = response else {
                if let error = error {
                    print("we have error getting directions==\(error.localizedDescription)")
                }
                return
            }
  
            //get route and assign to our route variable
            let route = directionResonse.routes[0]
            var travelTime = (route.expectedTravelTime / 60)
            if self.mode == "bike" {
                travelTime = travelTime / 2.4
            }
            self.tooltipTravelTime.text = "Situé à \(self.formatTime(travelTime)) en \(modeString)"
            self.carte.addOverlay(route.polyline, level: .aboveRoads)
            
//            setting rect of our mapview to fit the two locations
//             let rect = route.polyline.boundingMapRect
//             let recta = rect.insetBy(dx: -1200, dy: -1200)
//             let rectb = recta.offsetBy(dx: 0, dy: 400)
//             self.carte.setRegion(MKCoordinateRegion(rectb), animated: true)
        }
    }
    
    func formatTime(_ time: Double) -> String {
        var travelTime = Int(time.roundToDecimal(0))
        
        if travelTime < 60 {
            return "\(String(describing: travelTime)) minutes"
        } else {
            travelTime = travelTime / 60
            return "\(String(describing: travelTime)) heures"
        }
        
        
    }

    func deleteRoute(_ carte: MKMapView) {
        let overlays = carte.overlays
        carte.removeOverlays(overlays)
    }
    
    // Tooltip
    
    func showTooltip(annotation: BikeAnnotation) {
        
        if self.tooltipItinerary.isHidden {
            let views = [locationButtonView, legendView, findMyRideView]
 
            for vue in views as! [SpringView] {
                vue.isHidden = true
                vue.snp.remakeConstraints { (make) -> Void in
                    let superview = self.tooltipItinerary
                    make.bottom.equalTo(superview!.snp.top).offset(-8)
                }
                self.squeeze(vue: vue)
            }
        
            self.squeeze(vue: self.tooltipItinerary)
        }
        
        if annotation.park {
            self.parkedBtn.setTitle("Je suis parti", for: .normal)
            self.parkedBtn.setTitleColor(UIColor(named: "parkColor")!, for: .normal)
        } else {
            self.parkedBtn.setTitle("Je suis garé", for: .normal)
            self.parkedBtn.setTitleColor(UIColor(named: "appMainColor")!, for: .normal)
        }
        
        self.deleteRoute(self.carte)
        let coordinates = annotation.coordinate
        self.calculateInterary(destination: coordinates)
        self.tooltipAddress.text = annotation.address
        self.calculateSizeOfPark(size: annotation.size)
        self.setIconForTooltip(type: annotation.type, color: annotation.markerTintColor)
        self.setTooltipTitle(type: annotation.type)
        
    }
    
    func setTooltipTitle(type: String) {
        
        switch type {
        case "bike":
            return self.tooltipTitle.text = "Parking à vélo"
        case "moto":
            return self.tooltipTitle.text = "Parking deux-roues"
        default:
            return self.tooltipTitle.text = "Parking mixte"
        }
        
    }
    
    func setIconForTooltip(type: String, color: UIColor) {
        
        var image = "mix"
        
        if type == "bike" { image = "bike" }
        if type == "moto" { image = "moto" }
        
        self.tooltipTransportModeView.isHidden = false
        self.tooltipTransportIcon.image = UIImage(named: image)
        self.tooltipTransportModeView.backgroundColor = color
    }
    
    func calculateSizeOfPark(size: Double) {
        
        if size <= 30 {
            self.tooltipSizeView.backgroundColor = UIColor(named: "sizeSmallColor")!
            self.tooltipSize.text = "Petit"
        } else if size > 30 && size < 60 {
            self.tooltipSizeView.backgroundColor = UIColor(named: "sizeMediumColor")!
            self.tooltipSize.text = "Moyen"
        } else {
            self.tooltipSizeView.backgroundColor = UIColor(named: "sizeBigColor")!
            self.tooltipSize.text = "Grande"
        }
        
        self.tooltipSizeView.isHidden = false
        
    }
    
    func openInMaps(annotation: BikeAnnotation, mode: String) {
        
        let coordinate = CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        let latlon = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
        
        let mapsProvider: UIAlertController = UIAlertController(title: "Quel service de navigation souhaitez-vous utiliser ?", message: "Votre sélection sera sauvegardée sur votre iPhone", preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Apple Maps", style: .default) { _ in
            openInAppMaps()
            UserDefaults.standard.set("apple", forKey: "mapsProvider")
        }
        
        mapsProvider.addAction(cancelActionButton)
        
        let saveActionButton = UIAlertAction(title: "Google Maps", style: .default)
        { _ in
            openInGMaps()
            UserDefaults.standard.set("google", forKey: "mapsProvider")
        }
        
        mapsProvider.addAction(saveActionButton)
        
        func openInAppMaps() {
            mapItem.name = annotation.address
            if mode == "bike" {
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking])
            } else {
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
            }
        }
        
        func openInGMaps() {
            
            let urlApi = "https://www.google.com/maps/dir/?api=1"
            
            let destination = "&destination="
            let travelModeString = "&travelmode=bicycling"
            
            let fullUrl = "\(urlApi)\(destination)\(latlon)\(travelModeString)"
            
            UIApplication.shared.open(URL(string:fullUrl)!)
            
        }
        
        if let name = UserDefaults.standard.string(forKey: "mapsProvider") {
            if name == "google" {
                openInGMaps()
            } else {
                openInAppMaps()
            }
        } else {
            self.present(mapsProvider, animated: true, completion: nil)
        }
  
    }
    
    // Map View
//
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//
//        if let annot = view.annotation as? BikeAnnotation {
//            selectedAnnotation = annot
//            self.showTooltip(annotation: annot)
//
//
//        }
//
//
//    }
//
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        let renderer = MKPolylineRenderer(overlay: overlay)
//        renderer.strokeColor = UIColor(named: "appMainColor")!
//        renderer.lineWidth = 4.0
//        return renderer
//    }
//
//    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//
//        clusterManager.reload(mapView: carte)
//    }
//
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//
//        // Don't want to show a custom image if the annotation is the user's location.
//        guard !(annotation is MKUserLocation) else {
//            return nil
//        }
//
//        if let annotation = annotation as? TargetAnnotation {
//            return TargetMarkerView(annotation: annotation, reuseIdentifier: "bike")
//        } else if let annotation = annotation as? ClusterAnnotation {
//            return BikeClusterAnnotationView(annotation: annotation, reuseIdentifier: "cluster")
//        } else {
//            return BikeMarkerView(annotation: annotation, reuseIdentifier: "bike")
//        }
//    }
//
    // Mapbox View
    
    
    
    // Location manager
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//         manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            
        } else if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            setCenter()
        }
    }
    
    func getUserLocation() {
        
            locationManager.delegate = self
            //        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted:
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestWhenInUseAuthorization()
            case .denied:
                print("Location services denied")
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            @unknown default:
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestWhenInUseAuthorization()
            }
        
    }
    
    func setCenter() {
        
        if let initialLocation = locationManager.location {
            let regionRadius: CLLocationDistance = 350
            let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
            carte.setRegion(coordinateRegion, animated: true)
            
            carte.showsUserLocation = true
            carte.register(BikeMarkerView.self, forAnnotationViewWithReuseIdentifier: "bike")
            carte.register(BikeClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")
        } else {
            self.getUserLocation()
        }
        
    }
    
    // Results Table View
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // handle error
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.targetAnnotation != nil {
            self.carte.removeAnnotation(self.targetAnnotation!)
        }

        let completion = searchResults[indexPath.row]
        
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            let coordinate = response?.mapItems[0].placemark.coordinate
            self.searchField.text = response?.mapItems[0].name
            let myLocation = CLLocation(latitude: coordinate!.latitude, longitude: coordinate!.longitude)
            let regionRadius: CLLocationDistance = 350
            let coordinateRegion = MKCoordinateRegion(center: myLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
            self.carte.setRegion(coordinateRegion, animated: true)
            self.resultView.isHidden = true
            self.view.endEditing(true)
            let annotation = TargetAnnotation("Target", myLocation.coordinate)
            self.targetAnnotation = annotation
            self.carte.addAnnotation(annotation)
            self.carte.selectAnnotation(annotation, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let searchResult = searchResults[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell") as! ResultCell
        
        cell.selectionStyle = .none
        tableView.rowHeight = 57
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        
        cell.searchResultAddress.text = searchResult.title
        cell.searchResultAddress2.text = searchResult.subtitle
        return cell
        
    }
    
    // Animations
    
    func squeeze(_ mode: String = "in", vue: SpringView) {
        
        vue.isHidden = false
        vue.animation = "squeezeUp"
        vue.curve = "easeIn"
        vue.duration = 0.8
        vue.animate()
 
    }
}

extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}

extension UIView {
    
    func roundView(_ radius: Int,_ shadow: Bool) {
        self.layer.cornerRadius = CGFloat(exactly: radius)!
        self.layer.masksToBounds = true
        
        if shadow {
            self.layer.masksToBounds = false
            self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
            self.layer.shadowRadius = 3
            self.layer.shadowOffset = .zero
            self.layer.shadowOpacity = 0.15
            self.layer.shadowColor = UIColor.black.cgColor
        }
    }
}

extension MKMapView {
    
    func topCenterCoordinate() -> CLLocationCoordinate2D {
        return self.convert(CGPoint(x: self.frame.size.width / 2.0, y: 0), toCoordinateFrom: self)
    }
    
    func currentRadius() -> Double {
        let centerLocation = CLLocation(latitude: self.centerCoordinate.latitude, longitude: self.centerCoordinate.longitude)
        let topCenterCoordinate = self.topCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        return centerLocation.distance(from: topCenterLocation)
    }
    
}

//extension MapVC: UIGestureRecognizerDelegate {
//    
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        // This will only get called for the custom double tap gesture,
//        // that should always be recognized simultaneously.
//        return true
//    }
//    
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        // This will only get called for the custom double tap gesture.
//        return firstCluster(with: gestureRecognizer) != nil
//    }
//}
