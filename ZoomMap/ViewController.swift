//
//  ViewController.swift
//  TiltMap
//
//  Created by warren on 6/14/17.
//  Copyright © 2017 Muse. All rights reserved.


import UIKit
import CoreLocation
import MapKit
import MobileCoreServices
import CoreMotion

extension UIView {
    
    func roundCorners(radius:CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 1
    }
}

class MapView:MKMapView {
    
    @_silgen_name("_setShowNightMode")
    func _setShowNightMode(_ yo: Bool)
}


class Annotation: MKPointAnnotation {
    var mapItem: MKMapItem!
}

class ViewController: UIViewController, CLLocationManagerDelegate, SearchTextDelegate, ZoomPickerDelegate, PoiPickerDelegate {
    
    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var searchText: SearchText!
    @IBOutlet weak var poiPicker: PoiPicker!
    @IBOutlet weak var zoomPicker: ZoomPicker!
    @IBOutlet weak var searchCrown: SearchCrown!

    
    var annotations = [Annotation]()
    var mapAnno = [Int:Annotation]()
    
    let distMin = Double(200)
    let distMax = Double(100000)
    
    let locationMgr = CLLocationManager()
    var distanceNow = Double(100)
    var locationNow = CLLocation(latitude: 37.75894397, longitude: -122.42139956)
    var locationSpan = MKCoordinateSpanMake(0.05, 0.05)
    
    let motionMgr = CMMotionManager()
    var motionAtt: CMAttitude!
    var headingNow = CLLocationDirection()
    var headingPrev = CLLocationDirection()
    var freePitch = false
    var zoomTimer = Timer()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
        updateFormat()
        
        searchText.searchDelegate = self
        zoomPicker.zoomDelegate = self
        poiPicker.poiDelegate = self
        
        locationMgr.delegate = self
        locationMgr.startUpdatingHeading()
        requestLocation()
        
        mapView.setRegion(MKCoordinateRegionMake(locationNow.coordinate,locationSpan), animated: true)
        mapView.isRotateEnabled = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        motionMgr.deviceMotionUpdateInterval  = 0.25
        motionMgr.startDeviceMotionUpdates(to: OperationQueue.current!) { motion, error in
            self.updateMotion(motion)
        }
        zoomTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: {_ in
            self.zoomPicker.setZoomNearestTo(distance:3000)
        })
    }
    
    func updateFormat() {
        
        let m = CGFloat(12) // margin
        let h = view.frame.size.height
        let w = view.frame.size.width
        
        // main view
        view.layer.cornerRadius = 16
        //view.layer.masksToBounds = true
        
        // map view as full length
        let mapRect = CGRect(x: 0, y: 0, width: w, height: h)
        mapView.frame = mapRect
        
        // map view
        let h0 = w
        let mask = CAShapeLayer()
        let maskRect = CGRect(x: 0, y: 0, width: w, height: h0)
        mask.path = UIBezierPath(roundedRect: maskRect, cornerRadius:16).cgPath
        mapView.layer.mask = mask
        mapView.layer.borderColor = UIColor.darkGray.cgColor
        //mapView._setShowNightMode(true)
        
        // search text
        let h1 = searchText.frame.size.height
        let y1 = h0 + m
        let searchTextRect = CGRect(x:0, y: y1, width:w, height:h1)
        searchText.frame = searchTextRect
        
        // search crown on left side
        let h2 = h - (h0 + m + h1 + m)
        let w2 = searchCrown.frame.size.width
        let y2 = y1 + h1 + m
        let searchCrownRect = CGRect(x:0, y: y2, width:w2, height:h2)
        searchCrown.frame = searchCrownRect
        
        // zoom crown on right side
        let w3 = zoomPicker.frame.size.width
        let x3 = w - w3
        let zoomPickerRect = CGRect(x:x3, y:y2, width:w3, height:h2)
        zoomPicker.frame = zoomPickerRect
        
        // result text in middle
        let w4 = w - (w2 + w3 + 2*m)
        let x4 = w2 + m
        let poiPickerFrame = CGRect(x:x4, y:y2, width:w4, height:h2)
        poiPicker.frame = poiPickerFrame
    }
    
    func zoomPickerAction(_ item:ZoomItem) {
        
        if item.distance == Double(-1) {
            freePitch = true
        }
        else {
            freePitch = false
            distanceNow = item.distance
            updateCamera(distanceNow)
        }
    }
    
    func updateMotion(_ motion: CMDeviceMotion!) {
        
        if let motion = motion {
            
            let attitude = motion.attitude
            
            if motionAtt == nil {
                updateAttitude(attitude)
            }
            
            let threshold = 0.13
            let yprDelta = ( // yaw pitch roll delta
                abs(motionAtt.pitch - attitude.pitch) +
                    abs(motionAtt.yaw   - attitude.yaw)   +
                    abs(motionAtt.roll  - attitude.roll))
            
            if  yprDelta > threshold {
                updateAttitude(attitude)
            }
        }
    }
    
    func updateAttitude(_ attitude:CMAttitude ) {
        
        motionAtt = attitude
        
        if freePitch {
            
            let pitchMax = Double.pi/3
            let pitchMin = 0.03
            
            let pitch = max(pitchMin,min(attitude.pitch,pitchMax))
            let pitchNorm = (pitch-pitchMin) / (pitchMax-pitchMin)
            let distance = distMin + (distMax-distMin) * pitchNorm
            updateCamera(distance)
        }
        else  {
            updateCamera(distanceNow)
        }
    }
    
    func updateCamera(_ distance:Double) {
        
        
        //let heading = (locationMgr.heading?.trueHeading)!
        let newCamera = MKMapCamera(lookingAtCenter: locationNow.coordinate, fromDistance:distance, pitch: 60, heading: headingNow)
        
        //let newCenter = locationWithBearing(bearing: headingNow, distanceMeters: distance, origin: locationNow.coordinate)
        //let frmCamera = MKMapCamera(lookingAtCenter: newCenter, fromEyeCoordinate: locationNow.coordinate, eyeAltitude: distance)
        //print(String(format: "⊕ (%5.2f %5.2f %5.2f) distance: %.f",motionAtt.roll, motionAtt.pitch,motionAtt.yaw,distance))
        
        UIView.animate(withDuration:1.0, delay:0.5, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            
            self.mapView.camera = newCamera
        }) { success in
            self.searchPOIs()
        }
        
        
    }
    func searchTextAction(_ text: String) {
        searchPOIs()
    }
    
    func poiPickerAction(_ annotation: Annotation) {
        
        let mapItem = annotation.mapItem!
        let name = mapItem.name
        let hash = mapItem.hashValue
        let anno = mapAnno[hash]
        if anno != nil {
            mapView.selectAnnotation(anno!, animated: true)
        }
        print("\(#function):\(name!)")
    }
    
    func searchPOIs() {

        headingPrev = headingNow

        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchText.text
        
        let upperCenter = CGPoint(x:mapView.frame.size.width, y:mapView.frame.size.height/4)
        let newCenter = mapView.convert(upperCenter, toCoordinateFrom: mapView)
        let newSpan = MKCoordinateSpanMake(mapView.region.span.latitudeDelta, mapView.region.span.latitudeDelta/2)
        let newRegion = MKCoordinateRegionMake(newCenter, newSpan)
        
        request.region = newRegion
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("\(#function) error: \(error!)")
                return
            }
            self.updateMapAnnotations(response.mapItems)
        }
    }
    
    func setMapCenterAtBottom() {
        
        let oldRegion = mapView.regionThatFits(MKCoordinateRegionMake(locationNow.coordinate, locationSpan))
        let oldCenter = oldRegion.center
        let newCenter = CLLocationCoordinate2DMake(oldCenter.latitude + oldRegion.span.latitudeDelta/2, oldCenter.longitude)
        let newRegion = MKCoordinateRegionMake(newCenter, oldRegion.span)
        mapView.setRegion(newRegion, animated: true)
    }
    
    func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6)
        
        let rbearing = bearing * Double.pi / 180.0
        
        let lat1 = origin.latitude * Double.pi / 180
        let lon1 = origin.longitude * Double.pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(rbearing))
        let lon2 = lon1 + atan2(sin(rbearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.first {
            locationNow = location
            poiPicker.locationNow = location
            locationSpan = MKCoordinateSpanMake(0.005, 0.005)
            
            //mapView.setUserTrackingMode(.followWithHeading, animated: true)
            //let mapCam = mapView.camera
            //mapView.camera = MKMapCamera(lookingAtCenter: locationNow, fromDistance:100, pitch: 60, heading:mapCam.heading)
            print("📍 \(#function) \(location)")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 \(#function) \(error)")
    }
    func requestLocation() {
        
        switch  CLLocationManager.authorizationStatus() {
        case .notDetermined:        locationMgr.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:  locationMgr.requestLocation()
        case .denied: return
        default: return
        }
    }
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        DispatchQueue.main.async() {
            switch status {
            case .authorizedWhenInUse:  self.locationMgr.requestLocation()
            case .denied:               return
            default:                    return
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if(CLLocationCoordinate2DIsValid(mapView.centerCoordinate)) {
            headingNow = newHeading.trueHeading
        }
    }
    
    func updateMapAnnotations(_ mapItems: [MKMapItem]){
        
        var newMapAnno = [Int:Annotation]()
        
        for item in mapItems {
            let hash = item.hashValue
            if mapAnno[hash] != nil {
                newMapAnno[hash] = mapAnno[hash]
            }
            else {
                let anno = Annotation()
                anno.coordinate = item.placemark.coordinate
                anno.title = item.placemark.name
                anno.mapItem = item
                mapView.addAnnotation(anno)
                newMapAnno[hash] = anno
            }
        }
        for anno in mapAnno.values {
            let hash = anno.mapItem.hashValue
            if newMapAnno[hash] == nil {
                mapView.removeAnnotation(anno)
            }
        }
        mapAnno = newMapAnno
        let annos = Array(mapAnno.values)
        if annos.count > 0 {
            poiPicker.updateAnnotations(annos)
        }
    }
    

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is Annotation {
            
            let identifier = "Annotation"
            
            if let annoView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                annoView.annotation = annotation
                return annoView
            }
            else{
                let annoView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                return annoView
            }
        }
        return nil
    }
}

