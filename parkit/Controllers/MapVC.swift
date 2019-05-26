//
//  FirstViewController.swift
//  parkit
//
//  Created by Arthur Péligry on 16/04/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import IntentsUI
import Intents
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView
import ChameleonFramework
import Cluster
import SnapKit
import FontAwesome_swift
import Motion
import GestureRecognizerClosures

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var addToSiriButton: UIView!
    @IBOutlet weak var resultView: UIVisualEffectView!
    @IBOutlet weak var carte: MKMapView!
    @IBOutlet weak var tooltipItinerary: UIView!
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
    @IBOutlet weak var legendView: UIView!
    @IBOutlet weak var legendDot1View: UIView!
    @IBOutlet weak var legendDot2View: UIView!
    @IBOutlet weak var legendLabel1: UILabel!
    @IBOutlet weak var legendLabel2: UILabel!
    @IBOutlet weak var locationButtonView: UIView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var findMyRideView: UIView!
    @IBOutlet weak var searchIcon: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var addToSiriView: UIView!
    @IBOutlet weak var searchResultsTableView: UITableView!
    @IBAction func findMyRide(_ sender: Any) {
        
        if park.count != 0 {
            
            let type = park[0].value(forKeyPath: "type") as? String
            let address = park[0].value(forKeyPath: "address") as? String
            let size = park[0].value(forKeyPath: "size") as? Double
            let lat = park[0].value(forKeyPath: "lat")! as? Double
            let long = park[0].value(forKeyPath: "lon") as? Double
            let objectId = park[0].value(forKeyPath: "objectId") as? String
            let parked = park[0].value(forKeyPath: "park") as? Bool
            
            let annotation = BikeAnnotation(type: type!, coordinate: CLLocationCoordinate2D(latitude: lat!, longitude: long!), size: size!, address: address!, indexPark: objectId!, park: parked!)
            showTooltip(annotation: annotation)
            let myLocation = CLLocation(latitude: lat!, longitude: long!)
            calculateInterary(destination: myLocation.coordinate)
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
    @IBAction func parkedButton(_ sender: Any) {
//        self.parkMyRide()
        setUpSiri(to: self.addToSiriButton)
    }
    
    var spots: [NSManagedObject] = []
    var park: [NSManagedObject] = []
    
    var managedContext = NSManagedObjectContext()
    var entity = NSEntityDescription()
    
    @IBAction func openInMapsButton(_ sender: Any) {
        let mode = UserDefaults.standard.string(forKey: "mode") ?? "bike"
        openInMaps(annotation: selectedAnnotation!, mode: mode)
        
    }

    let locationManager = CLLocationManager()
    var selectedAnnotation: BikeAnnotation?
    var targetAnnotation: BikeAnnotation?
    
    var clusterManager = ClusterManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Authorizations
        
        getUserLocation()
        donateSiriInteraction()
        
        // Views
        
        setButtonsIcons()
        setLegend()
        addToSiriView.roundView(8, true)
        tooltipItinerary.roundView(8, true)
        loadingView.roundView(8, true)
        tooltipSizeView.roundView(4, false)
        tooltipItineraryView.roundView(4, false)
        tooltipTransportModeView.roundView(4, false)
        locationButtonView.roundView(8, true)
        settingsView.roundView(8, true)
        findMyRideView.roundView(8, true)
        legendView.roundView(8, true)
        searchView.roundView(8, true)
        
        loadingView.isHidden = true
        tooltipItinerary.isHidden = true
        resultView.isHidden = true
        addToSiriView.isHidden = true
        
        // Delegates & Actions
        
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(textFieldEditingDidChange), for: UIControl.Event.editingChanged)
        searchCompleter.delegate = self
        
        tooltipItinerary.onSwipeDown { _ in
            self.tooltipItinerary.isHidden = true
            self.deleteRoute()
            self.setViewsAtBottom(vues: [self.locationButtonView, self.legendView, self.findMyRideView])
        }
        
        // Constraintes
        
        locationButtonView.snp.makeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-8)
        }
        
        legendView.snp.makeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-8)
        }
        
        findMyRideView.snp.makeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-8)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isCoreDataEmpty() {
            getSpots()
        } else {
            getParksInCoreData()
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
                make.bottom.equalTo(superview!).offset(-8)
            }
        }
    }
    
    func setLegend() {
        let mode = UserDefaults.standard.string(forKey: "mode") ?? "bike"
        
        if mode == "bike" {
            legendDot1View.backgroundColor = UIColor(hexString: "#00cec9")
            legendLabel1.text = "Vélos"
        } else {
            legendDot1View.backgroundColor = UIColor(hexString: "#6c5ce7")
            legendLabel1.text = "Motos"
        }
        legendDot1View.layer.cornerRadius = 4
        legendDot1View.layer.masksToBounds = true
        legendDot2View.layer.cornerRadius = 4
        legendDot2View.layer.masksToBounds = true
        legendDot2View.backgroundColor = UIColor(hexString: "#0984e3")
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
    
    // Annotations
    
    func getSpots() {
        
        let url = "https://parkit-server.herokuapp.com/getParks"
        
        self.toogleActivityIndicator(status: "on")
        
        Alamofire.request(url).responseJSON { (responseData) -> Void in
            if let response = responseData.result.value {
                self.saveInCoreData(data: JSON(response))
            } else {
            }
            
            self.getParksInCoreData()
            self.toogleActivityIndicator(status: "off")
        }
        
    }
    
    func saveInCoreData(data: JSON) {
        
        
        entity = NSEntityDescription.entity(forEntityName: "Park", in: managedContext)!
        
        for (_, subJson) in data {
            
            let park = NSManagedObject(entity: self.entity, insertInto: managedContext)
            
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

            do {
                try managedContext.save()
                spots.append(park)
            } catch  {
                
            }
            
        }
        
        
    }
    
    func getParksInCoreData() {
     
        for park in spots {
            
            let mode = UserDefaults.standard.string(forKey: "mode") ?? "bike"
            
            let type = park.value(forKeyPath: "type") as? String
            let address = park.value(forKeyPath: "address") as? String
            let size = park.value(forKeyPath: "size") as? Double
            let lat = park.value(forKeyPath: "lat")! as? Double
            let long = park.value(forKeyPath: "lon") as? Double
            let objectId = park.value(forKeyPath: "objectId") as? String
            let park = park.value(forKeyPath: "park") as? Bool
        
            if mode == "bike" && type! == "Vélos" || type! == "Mixte" {
                let annotation = BikeAnnotation(type: type!, coordinate: CLLocationCoordinate2D(latitude: lat!, longitude: long!), size: size!, address: address!, indexPark: objectId!, park: park!)
                clusterManager.add(annotation)
                clusterManager.reload(mapView: carte)
            } else if mode == "moto" && type! == "Motos" || type! == "Mixte" {
                let annotation = BikeAnnotation(type: type!, coordinate: CLLocationCoordinate2D(latitude: lat!, longitude: long!), size: size!, address: address!, indexPark: objectId!, park: park!)
                clusterManager.add(annotation)
                clusterManager.reload(mapView: carte)
            }
        }


    }
    
    func isCoreDataEmpty () -> Bool {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return true }
        managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Park")

        do {
            spots = try managedContext.fetch(fetchRequest)
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
    
//    // Park Ride

//    func parkMyRide() {
//
//        let mode = UserDefaults.standard.string(forKey: "mode") ?? "bike"
//
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//
//        let deleteRequest = NSFetchRequest<NSManagedObject>(entityName: "Park")
//        deleteRequest.predicate = NSPredicate(format: "park = %@", NSNumber(value: true))
//        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Park")
//        fetchRequest.predicate = NSPredicate(format: "objectId = %@", selectedAnnotation!.indexPark)
//
//        do {
//            park = try managedContext.fetch(deleteRequest)
//
//            park[0].setValue(false, forKeyPath: "park")
//            do {
//                try managedContext.save()
//
//            } catch {
//
//            }
//            clusterManager.reload(mapView: self.carte)
//        } catch {
//
//        }
//
//        do {
//            park = try managedContext.fetch(fetchRequest)
//            park.setValue(true, forKey: "park")
//            clusterManager.remove(selectedAnnotation!)
//
//            let type = parks[0].value(forKeyPath: "type") as? String
//            let address = parks[0].value(forKeyPath: "address") as? String
//            let size = parks[0].value(forKeyPath: "size") as? Double
//            let lat = parks[0].value(forKeyPath: "lat")! as? Double
//            let long = parks[0].value(forKeyPath: "lon") as? Double
//            let objectId = parks[0].value(forKeyPath: "objectId") as? String
//            let park = parks[0].value(forKeyPath: "park") as? Bool
//
//            do {
//                try managedContext.save()
//
//            } catch {
//
//            }
//
//            if mode == "bike" && type! == "Vélos" || type! == "Mixte" {
//                let annotation = BikeAnnotation(type: type!, coordinate: CLLocationCoordinate2D(latitude: lat!, longitude: long!), size: size!, address: address!, indexPark: objectId!, park: park!)
//                clusterManager.add(annotation)
//                clusterManager.reload(mapView: carte)
//            } else if mode == "moto" && type! == "Motos" || type! == "Mixte" {
//                let annotation = BikeAnnotation(type: type!, coordinate: CLLocationCoordinate2D(latitude: lat!, longitude: long!), size: size!, address: address!, indexPark: objectId!, park: park!)
//                clusterManager.add(annotation)
//                clusterManager.reload(mapView: self.carte)
//            }
//
//        } catch {
//
//        }

//    }
    
    // Itinerary
    
    func calculateInterary(destination: CLLocationCoordinate2D) {
        
        let mode = UserDefaults.standard.string(forKey: "mode") ?? "bike"
        
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
            let travelTime = (route.expectedTravelTime / 60).roundToDecimal(1)
            self.tooltipTravelTime.text = "Situé à \(travelTime) minute(s) en \(modeString)"
            self.carte.addOverlay(route.polyline, level: .aboveRoads)
            
            //setting rect of our mapview to fit the two locations
            // let rect = route.polyline.boundingMapRect
            // let recta = rect.insetBy(dx: -1200, dy: -1200)
            // let rectb = recta.offsetBy(dx: 0, dy: 400)
            // self.carte.setRegion(MKCoordinateRegion(rectb), animated: true)
        }
    }
    
    func deleteRoute() {
        let overlays = self.carte.overlays
        carte.removeOverlays(overlays)
        self.tooltipItinerary.isHidden = true
        
    }
    
    // Tooltip
    
    func showTooltip(annotation: BikeAnnotation) {
        
        locationButtonView.snp.remakeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-140)
        }
        
        legendView.snp.remakeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-140)
        }
        
        findMyRideView.snp.remakeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-140)
        }
        
        
        let coordinates = annotation.coordinate
        
        self.deleteRoute()

        self.tooltipItinerary.isHidden = false
        
        self.tooltipItinerary.animate(.fadeIn)
        self.calculateInterary(destination: coordinates)
        self.tooltipAddress.text = annotation.address
        self.calculateSizeOfPark(size: annotation.size)
        self.setIconForTooltip(type: annotation.type, color: annotation.markerTintColor)
        self.setTooltipTitle(type: annotation.type)
        
    }
    
    func setTooltipTitle(type: String) {
        
        switch type {
        case "Vélos":
            return self.tooltipTitle.text = "Parking à vélo"
        case "Motos":
            return self.tooltipTitle.text = "Parking deux-roues"
        default:
            return self.tooltipTitle.text = "Parking mixte"
        }
        
    }
    
    func setIconForTooltip(type: String, color: UIColor) {
        
        var image = "mix"
        
        if type == "Vélos" { image = "bike" }
        if type == "Motos" { image = "moto" }
        
        self.tooltipTransportModeView.isHidden = false
        self.tooltipTransportIcon.image = UIImage(named: image)
        self.tooltipTransportModeView.backgroundColor = color
    }
    
    func calculateSizeOfPark(size: Double) {
        
        if size <= 10 {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#ED7070")
            self.tooltipSize.text = "Petit"
        } else if size > 10 && size < 50 {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#ED9070")
            self.tooltipSize.text = "Moyen"
        } else {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#A6D58A")
            self.tooltipSize.text = "Grande"
        }
        
        self.tooltipSizeView.isHidden = false
        
    }
    
    func openInMaps(annotation: BikeAnnotation, mode: String) {
        
        let coordinate = CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = annotation.title
        let latlon = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
        
        let mapsProvider: UIAlertController = UIAlertController(title: "Quel service souhaitez-vous utiliser ?", message: "Votre sélection sera sauvegardée sur votre iPhone", preferredStyle: .actionSheet)
        
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
            
            UIApplication.shared.openURL(URL(string:fullUrl)!)
            
            
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annot = view.annotation as? BikeAnnotation {
            selectedAnnotation = annot
            if annot.type != "Target" {
                self.showTooltip(annotation: annot)
            }
         
        }
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(hexString: "#FFC107")
        renderer.lineWidth = 4.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

        clusterManager.reload(mapView: carte)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        if let annotation = annotation as? ClusterAnnotation {
            return BikeClusterAnnotationView(annotation: annotation, reuseIdentifier: "cluster")
        } else {
            return BikeMarkerView(annotation: annotation, reuseIdentifier: "bike")
        }
    }
    
    // Location manager
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//         manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            // The user denied authorization
        } else if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            setCenter()
        }
    }
    
    func getUserLocation() {
        
        locationManager.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            @unknown default:
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestWhenInUseAuthorization()
            }
        } else {
//            print("Location services are not enabled")
        }
        
    }
    
    func setCenter() {
        
        let initialLocation = locationManager.location!
        let regionRadius: CLLocationDistance = 350
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        carte.setRegion(coordinateRegion, animated: true)
        
        carte.showsUserLocation = true
        carte.register(BikeMarkerView.self, forAnnotationViewWithReuseIdentifier: "bike")
        carte.register(BikeClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")
        
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
            let annotation = BikeAnnotation(type: "Target", coordinate: myLocation.coordinate, size: 0, address: "", indexPark: "", park: false)
            self.targetAnnotation = annotation
            self.carte.addAnnotation(self.targetAnnotation!)
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
    
    // Siri
    
    func donateSiriInteraction() {
        let intent = WhereIsMyBikeIntent()
        let interaction = INInteraction(intent: intent, response: nil)
        
        interaction.donate { (error) in
            print("yeah")
            if error != nil {
                
            }
        }
    }
    
    func setUpSiri(to view: UIView) {
        
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        button.shortcut = INShortcut(intent: intent)
        let shot = INShortcut(intent: intent)
        if shot != nil {
            //            print("déjà")
        } else {
            self.addToSiriView.isHidden = false
            button.delegate = self
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
            view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        }
        
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
            self.layer.shadowRadius = 5
            self.layer.shadowOffset = .zero
            self.layer.shadowOpacity = 1
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

extension MapVC: INUIAddVoiceShortcutButtonDelegate {
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
    
}

extension MapVC: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

extension MapVC: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MapVC {
    public var intent: WhereIsMyBikeIntent {
        let intent = WhereIsMyBikeIntent()
        return intent
    }
}
