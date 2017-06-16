//
//  ZoomPicker.swift
//  ZoomMap
//
//  Created by warren on 6/16/17.
//  Copyright © 2017 Muse. All rights reserved.
//

import UIKit

struct ZoomItem {
    var title    : String
    var distance : Double
    
    init (_ title_:String, _ distance_:Double) {
        title = title_
        distance = distance_
    }
}
protocol ZoomPickerDelegate {
    func zoomPickerAction(_ zoomItem:ZoomItem)
}

class ZoomPicker:UIPickerView, UIPickerViewDelegate  {
    
    var zoomDelegate: ZoomPickerDelegate!
    var zoomItems = [ZoomItem]()
    
    
    required init?(coder:NSCoder) {
        super.init(coder: coder)
        updateView()
        updateZoomItems([
            ZoomItem( "150",   150),
            ZoomItem( "500",   500),
            ZoomItem(  "1k",  1000),
            ZoomItem(  "3k",  3000),
            ZoomItem( "10k", 10000),
            ZoomItem("100k",100000),
            ZoomItem("tilt",    -1) // for a uint, this would be very big
            ])
    }
    func updateView() {
        self.delegate = self
        self.backgroundColor = UIColor.black
        roundCorners(radius:16)
    }
    func updateZoomItems(_ zoomItems_:[ZoomItem]) {
        zoomItems.removeAll()
        zoomItems = zoomItems_
        reloadAllComponents()
    }
    
    func setZoomNearestTo(distance:Double) {
        
        var i = 0
        var nearesti = 0
        var nearestSoFar = Double(99999)
        for zoomItem in zoomItems {
            let delta  = abs(zoomItem.distance - distance)
            if nearestSoFar > delta {
                nearestSoFar = delta
                nearesti = i
            }
            i += 1
        }
        selectRow(nearesti, inComponent: 0, animated: true)
        zoomDelegate.zoomPickerAction(zoomItems[nearesti])
    }
    
    // DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return zoomItems.count
    }
    
    // Delegate
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        let title = zoomItems[row].title
        
        let attributedString = NSAttributedString(string:title,
                                                  attributes: [NSForegroundColorAttributeName : UIColor.white])
        return attributedString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        zoomDelegate.zoomPickerAction(zoomItems[row])
    }
    
}
