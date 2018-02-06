//
//  LocationManager.swift
//  ChickenVoiceRecognition
//
//  Created by Phineas.Huang on 05/02/2018.
//  Copyright © 2018 SunXiaoShan. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationManager: NSObject {
    let locationManager = CLLocationManager()
    var mapView: MKMapView = MKMapView()
    var lastLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(25.099, 121.3799)
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .denied {
            
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        
        setupData()
    }
    
    func setupData() {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let title = ""
            let coordinate = CLLocationCoordinate2DMake(25.099, 121.3799)
            let regionRadius:CLLocationDistance = 200.0
            
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                         longitude: coordinate.longitude), radius: regionRadius, identifier: title)
            
            
            
            moveToCurrentLocation()
            
            locationManager.startMonitoring(for: region)
            
            // addAnnotation(coordinate, "")
            // addCircle(coordinate, regionRadius)
        } else {
            print("System can't track regions")
        }
    }
    
    open func getMapView(_ size: CGSize) -> MKMapView {
        mapView.frame.size = size
        return mapView
    }
    
    private func getLocationSpan() -> MKCoordinateSpan {
        let latDelta = 0.005
        let longDelta = 0.005
        let currentLocationSpan:MKCoordinateSpan =
            MKCoordinateSpanMake(latDelta, longDelta)
        return currentLocationSpan
    }
    
    open func moveToLocation(_ location : CLLocationCoordinate2D) {
        let currentRegion:MKCoordinateRegion =
            MKCoordinateRegion(
                center: location,
                span: getLocationSpan())
        mapView.setRegion(currentRegion, animated: true)
    }
    
    open func addAnnotation(_ location : CLLocationCoordinate2D, _ title : String) {
        let restaurantAnnotation = MKPointAnnotation()
        restaurantAnnotation.coordinate = location;
        restaurantAnnotation.title = "\(title)";
        mapView.addAnnotation(restaurantAnnotation)
    }
    
    open func addCircle(_ location : CLLocationCoordinate2D, _ regionRadius:CLLocationDistance) {
        let circle = MKCircle(center: location, radius: regionRadius)
        mapView.add(circle)
    }
    
    open func moveToCurrentLocation() {
        moveToLocation(lastLocation)
    }
}

extension LocationManager : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currLocation:CLLocation = locations.last!
        let latitude = currLocation.coordinate.latitude
        let longitude = currLocation.coordinate.longitude
        
        lastLocation = currLocation.coordinate
    }
}

extension LocationManager : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = UIColor.red
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
}
