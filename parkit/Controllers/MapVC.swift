//
//  FirstViewController.swift
//  parkit
//
//  Created by Arthur Péligry on 16/04/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import CoreLocation
import NVActivityIndicatorView
import ChameleonFramework
import Cluster

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
 
    @IBOutlet weak var carte: MKMapView!
    @IBOutlet weak var tooltipItinerary: UIView!
    @IBOutlet weak var tooltipTitle: UILabel!
    @IBOutlet weak var tooltipAddress: UILabel!
    @IBOutlet weak var tooltipTravelTime: UILabel!
    @IBOutlet weak var tooltipTransportView: UIView!
    @IBOutlet weak var tooltipTransportIcon: UIImageView!
    @IBOutlet weak var tooltipSize: UILabel!
    @IBOutlet weak var tooltipItineraryView: UIView!
    @IBOutlet weak var tooltipSizeView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: NVActivityIndicatorView!
    
    @IBAction func modeSwitched(_ sender: UISegmentedControl) {
        
        self.deleteRoute()
        
        switch sender.selectedSegmentIndex {
        case 0:
            mode = "bike"
            placeSpots()
        case 1:
            mode = "motorbike"
            placeSpots()
        default:
            break
        }
        
    }
    
    @IBAction func openInMapsButton(_ sender: Any) {
        
        openInMaps(annotation: selectedAnnotation!, mode: mode)
        
    }
    
    var mode = "bike"
    let locationManager = CLLocationManager()
    var selectedAnnotation: BikeAnnotation?
    
    var spotVelos = [JSON]()
    var spotMotos = [JSON]()
    var spotMixte = [JSON]()
    
    let clusterManager = ClusterManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setRoundView(vue: tooltipItinerary)
        tooltipItinerary.dropShadow()
        setRoundView(vue: loadingView)
        setRoundView(vue: tooltipSizeView)
        setRoundView(vue: tooltipTransportView)
        setRoundView(vue: tooltipItineraryView)
        
        getUserLocation()
        
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
            }
        } else {
            print("Location services are not enabled")
        }
        
    }
    
    func setRoundView(vue: UIView) {
        vue.isHidden = true
        vue.layer.cornerRadius = 8
        vue.layer.masksToBounds = true
    }

    func setCenter() {
        
        let initialLocation = locationManager.location!
        let regionRadius: CLLocationDistance = 500
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        carte.setRegion(coordinateRegion, animated: true)
        
        carte.showsUserLocation = true
        carte.register(BikeMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    
    }
    
    func getSpots(coord: CLLocationCoordinate2D, distance: Int) {
        
        spotVelos.removeAll()
        spotMixte.removeAll()
        spotMotos.removeAll()
        
        let coordinates = "\(coord.latitude),\(coord.longitude),\(distance)"
        
        let url = "https://opendata.paris.fr/api/records/1.0/search/?dataset=stationnement-voie-publique-emplacements&rows=1000&facet=regpri&facet=regpar&facet=typsta&facet=arrond&refine.regpri=2+ROUES&geofilter.distance=\(coordinates)"
        
        self.toogleActivityIndicator(status: "on")
        
        Alamofire.request(url).responseJSON { (responseData) -> Void in
            if let response = responseData.result.value {
                
                let res = JSON(response)
//                let rsu = res["records"][0]
                
//                print(res["nbhits"].double!)
                self.sortSpots(spots: JSON(response))
            } else {
                print("Error retrieving token")
            }
            
            self.toogleActivityIndicator(status: "off")
        }
        
    }
    
    func sortSpots(spots: JSON) {
        
        for (_, subJson) in spots["records"] {
            
            let field = subJson["fields"]["regpar"].string!
            
            if field == "Vélos" { self.spotVelos.append(subJson) }
            else if field == "Motos" { self.spotMotos.append(subJson) }
            else { self.spotMixte.append(subJson) }
            
        }
        
        placeSpots()
        
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
    
    func placeSpots() {
        
        let allAnnotations = self.carte.annotations
        carte.removeAnnotations(allAnnotations)
        
        if mode == "bike" {
            loopSpots(coll: self.spotVelos)
        } else if mode == "motorbike" {
            loopSpots(coll: self.spotMotos)
        }
        
        loopSpots(coll: self.spotMixte)
    }
    
    func loopSpots(coll: [JSON]) {
        
        for subJson in coll {
            
            let fields = subJson["fields"]
            
//            let nom = fields["nomvoie"].string
            let coordinates = subJson["geometry"]["coordinates"]
            let type = fields["regpar"].string!
            let size = fields["longueur_calculee"].double!.roundToDecimal(0)
            let typeVoie = fields["typevoie"].string
            let numVoie = fields["numvoie"]
//            var address = ""
//            if String(describing: numVoie) != "null" {
//                address = "\(String(describing: numVoie)) \(typeVoie) \(nom)"
//            } else {
//                address = "\(typeVoie) \(nom)"
//            }
            
            
            let annotation = BikeAnnotation(title: "test", type: type, coordinate: CLLocationCoordinate2D(latitude: coordinates[1].double!, longitude: coordinates[0].double!), size: size)
            clusterManager.add(annotation)
            carte.addAnnotation(annotation)
            
        }
    }
    
    func openInMaps(annotation: BikeAnnotation, mode: String) {
        
        let coordinate = CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = annotation.title
        
        if mode == "bike" {
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking])
        } else {
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        }
        
    }
    
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
            modeString = "deux roues motorisé"
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
            
            
            //add rout to our mapview
            self.carte.addOverlay(route.polyline, level: .aboveRoads)
            
            //setting rect of our mapview to fit the two locations
//            let rect = route.polyline.boundingMapRect
//            self.carte.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func deleteRoute() {
        let overlays = self.carte.overlays
        carte.removeOverlays(overlays)
        self.tooltipItinerary.isHidden = true
    }
    
    func showTooltip(annotation: BikeAnnotation) {
        
        let coordinates = annotation.coordinate
        
        self.deleteRoute()
        self.tooltipItinerary.isHidden = false
        self.tooltipItineraryView.isHidden = false
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
        
        self.tooltipTransportView.isHidden = false
        self.tooltipTransportIcon.image = UIImage(named: image)
        self.tooltipTransportView.backgroundColor = color
    }
    
    func calculateSizeOfPark(size: Double) {
        
        if size <= 10 {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#ED7070")
            self.tooltipSize.text = "Petit"
        } else if size > 10 && size < 100 {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#ED9070")
            self.tooltipSize.text = "Moyen"
        } else {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#A6D58A")
            self.tooltipSize.text = "Grande"
        }
        
        self.tooltipSizeView.isHidden = false
        
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touch = touches.first
//        guard let location = touch?.location(in: self.view) else { return }
//
//        if !tooltipItinerary.frame.contains(location) {
//            tooltipItinerary.isHidden = true
//        }
//
//    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annot = view.annotation as? BikeAnnotation {
            selectedAnnotation = annot
            self.showTooltip(annotation: annot)
        }
        
    }
    
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(hexString: "#FFC107")
        renderer.lineWidth = 4.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        getSpots(coord: carte.centerCoordinate, distance: Int(carte.currentRadius()))
//        clusterManager.reload(mapView: mapView) { finished in
//            print(finished)
//        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
         manager.stopUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            // The user denied authorization
        } else if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            setCenter()
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
    
    func dropShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.layer.shadowRadius = 5
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
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

class CountClusterAnnotationView: ClusterAnnotationView {
    override func configure() {
        super.configure()
        
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.5
    }
}
