//
//  PoiPicker.swift
//  ZoomMap
//
//  Created by warren on 6/16/17.
//  Copyright © 2017 Muse. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

protocol PoiPickerDelegate {
    func poiPickerAction(_ annotation:Annotation)
}
class PoiPicker:UIPickerView, UIPickerViewDelegate {
    
    var poiDelegate: PoiPickerDelegate!
    var annotations = [Annotation!]()
    var locationNow = CLLocation(latitude: 37.75894397, longitude: -122.42139956)
    
    required init?(coder:NSCoder) {
        super.init(coder: coder)
        updateView()
    }
    func updateView() {
        super.delegate = self
        self.backgroundColor = UIColor.black
        roundCorners(radius:16)
    }
    
    func updateAnnotations(_ annotations_:[Annotation]) {
        annotations.removeAll()
        annotations = annotations_
        annotations.sort() { distance(for:$0) < distance(for:$1) }
        reloadAllComponents()
    }
    
    func distance(for annotation:Annotation) -> Double {
        return (annotation.mapItem.placemark.location?.distance(from: locationNow))!
    }
    
    // DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return annotations.count
    }
    
    // Delegate
    
    func metersTitle(_ meters:Double) -> String {
        
        let title = ( meters <  1000 ? String(format:"%.0f",meters) :
            /**/      meters < 10000 ? String(format:"%.1fk",meters/1000) :
            /**/                       String(format:"%.0fk",meters/1000))
        return title
        
    }
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        let anno = annotations[row]
        let mapItem = anno?.mapItem
        let distance = self.distance(for:anno!)
        let title = (mapItem?.name)! + " - " + metersTitle(distance)
        
        let attributedString = NSAttributedString(string:title, attributes: [NSForegroundColorAttributeName : UIColor.white])
        return attributedString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        poiDelegate.poiPickerAction(annotations[row])
    }
    
}
