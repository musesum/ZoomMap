//
//  SearchCrown.swift
//  ZoomMap
//
//  Created by warren on 6/16/17.
//  Copyright © 2017 Muse. All rights reserved.
//

import UIKit

class SearchCrown: UIView {
    
    
    required init?(coder:NSCoder) {
        super.init(coder: coder)
        updateView()
    }
    func updateView() {
        
        roundCorners(radius:16)
    }
}
