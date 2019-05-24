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
import SnapKit
import FontAwesome_swift

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
    @IBOutlet weak var locationButtonView: UIView!
    @IBOutlet weak var locationButton: UIButton!
    @IBAction func locationButtonPressed(_ sender: Any) {
        setCenter()
    }
    
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
        
        setViewsAtBottom(vues: [self.locationButtonView])
        
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
        
        setRoundView(vue: tooltipItinerary, radius: 8)
        tooltipItinerary.dropShadow()
        setRoundView(vue: loadingView, radius: 8)
        setRoundView(vue: tooltipSizeView, radius: 4)
        setRoundView(vue: tooltipTransportView, radius: 8)
        setRoundView(vue: tooltipItineraryView, radius: 4)
        locationButtonView.layer.cornerRadius = 8
        locationButtonView.layer.masksToBounds = true
        locationButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 15, style: FontAwesomeStyle.solid)
        locationButton.setTitle(String.fontAwesomeIcon(name: .locationArrow), for: .normal)
        
        getUserLocation()
        
        
        
        locationButtonView.snp.makeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-8)
        }

        
    }
    
    func setViewsAtBottom(vues: [UIView]) {
        for vue in vues {
            vue.snp.remakeConstraints { (make) -> Void in
                let superview = self.view
                make.bottom.equalTo(superview!).offset(-8)
            }
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
            }
        } else {
            print("Location services are not enabled")
        }
        
    }
    
    func setRoundView(vue: UIView, radius: Int) {
        vue.isHidden = true
        vue.layer.cornerRadius = CGFloat(integerLiteral: radius)
        vue.layer.masksToBounds = true
    }

    func setCenter() {
        
        let initialLocation = locationManager.location!
        let regionRadius: CLLocationDistance = 500
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        carte.setRegion(coordinateRegion, animated: true)
        
        carte.showsUserLocation = true
        carte.register(BikeMarkerView.self, forAnnotationViewWithReuseIdentifier: "bike")
        carte.register(BikeClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")
        
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
    
    func getSpots(coord: CLLocationCoordinate2D, distance: Int) {
        
        spotVelos.removeAll()
        spotMixte.removeAll()
        spotMotos.removeAll()
        
        let coordinates = "\(coord.latitude),\(coord.longitude),\(distance)"
        
        let url = "https://parkit-server.herokuapp.com/getParks"
        
        self.toogleActivityIndicator(status: "on")
        
        Alamofire.request(url).responseJSON { (responseData) -> Void in
            if let response = responseData.result.value {
            
                self.sortSpots(spots: JSON(response))
            } else {
                print("Error retrieving token")
            }
            
            self.toogleActivityIndicator(status: "off")
        }
        
    }
    
    func sortSpots(spots: JSON) {
        
        for (_, subJson) in spots {
            
            let field = subJson["type"].string!
            
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
        clusterManager.removeAll()
        clusterManager.reload(mapView: carte)
        
        if mode == "bike" {
            loopSpots(coll: self.spotVelos)
        } else if mode == "motorbike" {
            loopSpots(coll: self.spotMotos)
        }
        
        loopSpots(coll: self.spotMixte)
    }
    
    func loopSpots(coll: [JSON]) {
        
        for subJson in coll {
            
            let type = subJson["type"].string!
            let address = subJson["address"].string!
            let size = subJson["size"].double!
            let lat = Double(subJson["coordinates"]["lat"].string!)!
            let long = Double(subJson["coordinates"]["lon"].string!)!
            
           
            
            let annotation = BikeAnnotation(title: "test", type: type, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long), size: size, address: address)
            clusterManager.add(annotation)
            clusterManager.reload(mapView: carte)
            
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
//            let rect = route.polyline.boundingMapRect
//            let recta = rect.insetBy(dx: -1200, dy: -1200)
//            let rectb = recta.offsetBy(dx: 0, dy: 400)
//            self.carte.setRegion(MKCoordinateRegion(rectb), animated: true)
        }
    }
    
    func deleteRoute() {
        let overlays = self.carte.overlays
        carte.removeOverlays(overlays)
        self.tooltipItinerary.isHidden = true
        
    }
    
    func showTooltip(annotation: BikeAnnotation) {

        locationButtonView.snp.remakeConstraints { (make) -> Void in
            let superview = self.view
            make.bottom.equalTo(superview!).offset(-140)
        }
        
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
        } else if size > 10 && size < 50 {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#ED9070")
            self.tooltipSize.text = "Moyen"
        } else {
            self.tooltipSizeView.backgroundColor = UIColor(hexString: "#A6D58A")
            self.tooltipSize.text = "Grande"
        }
        
        self.tooltipSizeView.isHidden = false
        
    }
    
    // Map View
    
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
    }
    
    // Location manager
    
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


