//
//  SearchText.swift
//  ZoomMap
//
//  Created by warren on 6/16/17.
//  Copyright © 2017 Muse. All rights reserved.
//

import UIKit

protocol SearchTextDelegate {
    func searchTextAction(_ text: String)
}
class SearchText:UITextField, UITextFieldDelegate {
    
    var searchDelegate: SearchTextDelegate!
    
    required init?(coder:NSCoder) {
        super.init(coder: coder)
        updateView()
    }
    
    func updateView() {
        self.frame.size.height = 64
        roundCorners(radius:16)
        self.delegate = self
        self.text = "Trains"
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        print ("\(#function)")
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchDelegate.searchTextAction(textField.text!)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // yo
    }
}

