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
import Kingfisher

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
 
    @IBOutlet weak var carte: MKMapView!
    @IBOutlet weak var tooltipItinerary: UIView!
    @IBOutlet weak var tooltipTravelTime: UILabel!
    @IBOutlet weak var tooltipSuperview: UIView!
    @IBOutlet weak var imageTooltipSuperview: UIImageView!
    
    @IBAction func modeSwitcged(_ sender: UISegmentedControl) {
        
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
    
    var selectedAnnotation = MKAnnotationView()
    
    var mode = "bike"
    
    var spotVelos = [JSON]()
    var spotMotos = [JSON]()
    var spotMixte = [JSON]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCenter()
        getSpots()
        
        setRoundView(vue: tooltipItinerary)
        setRoundView(vue: tooltipSuperview)
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.showTooltipSuperview))
        self.tooltipItinerary.addGestureRecognizer(gesture)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.closeSuperTooltip))
        swipeDown.direction = .down
        self.imageTooltipSuperview.addGestureRecognizer(swipeDown)
        
        
    }
    
    @objc func showTooltipSuperview(sender : UITapGestureRecognizer) {
        tooltipSuperview.isHidden = false
        getPhoto(coord: CLLocationCoordinate2D(latitude:(selectedAnnotation.annotation?.coordinate.latitude)!, longitude: (selectedAnnotation.annotation?.coordinate.longitude)!))
    }
    
    @objc func closeSuperTooltip() {
        tooltipSuperview.isHidden = true
    }
    
    func setRoundView(vue: UIView) {
        vue.isHidden = true
        vue.layer.cornerRadius = 8
        vue.layer.masksToBounds = true
    }

    func setCenter() {
        
        let initialLocation = CLLocation(latitude: 48.851942, longitude: 2.389628)
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        carte.setRegion(coordinateRegion, animated: true)
        
        carte.showsUserLocation = true
        carte.register(BikeMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }
    
    func getSpots() {
        
        let url = "https://opendata.paris.fr/api/records/1.0/search/?dataset=stationnement-voie-publique-emplacements&rows=1000&facet=regpri&facet=regpar&facet=typsta&facet=arrond&refine.regpri=2+ROUES"
        
        Alamofire.request(url).responseJSON { (responseData) -> Void in
            if let response = responseData.result.value {
                self.sortSpots(spots: JSON(response))
            } else {
                print("Error retrieving token")
            }
            
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
            
            let nom = subJson["fields"]["nomvoie"].string!
            let coordinates = subJson["geometry"]["coordinates"]
            let type = subJson["fields"]["regpar"].string!
            let annotation = BikeAnnotation(title: nom, type: type, coordinate: CLLocationCoordinate2D(latitude: coordinates[1].double!, longitude: coordinates[0].double!))
            
            carte.addAnnotation(annotation)
            
        }
    }
    
    func calculateInterary(destination: CLLocationCoordinate2D) {
        
        self.deleteRoute()
        
        let sourceLocation = CLLocationCoordinate2D(latitude:48.851942, longitude: 2.389628)
        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        directionRequest.transportType = .automobile
        
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
            self.showTooltip(travelTime: travelTime)
            
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
        self.tooltipSuperview.isHidden = true
    }
    
    func showTooltip(travelTime: Double) {
        
        self.tooltipItinerary.isHidden = false
        self.tooltipTravelTime.text = "Situé à \(travelTime) mn"
        
        
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotation = view.annotation?.coordinate {
            calculateInterary(destination: annotation)
        }
        
        selectedAnnotation = view
        
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(hexString: "#FFC107")
        renderer.lineWidth = 4.0
        return renderer
    }
    
    func getPhoto(coord: CLLocationCoordinate2D) {
        
        let location = "\(coord.latitude),\(coord.longitude)"
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/streetview?size=720x480&location=\(location)&fov=&heading=&pitch=-10&key=AIzaSyAYwYTtSyZwFCpdlHXuddfwstTnA3MVz6s")
        
        imageTooltipSuperview.kf.indicatorType = .activity
        imageTooltipSuperview.kf.setImage(with: url)

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let location = touch?.location(in: self.view) else { return }
        
        if !tooltipItinerary.frame.contains(location) {
            tooltipItinerary.isHidden = true
        }
        
        if !tooltipSuperview.frame.contains(location) {
            tooltipSuperview.isHidden = true
        }
    }

    
   
}

extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}
