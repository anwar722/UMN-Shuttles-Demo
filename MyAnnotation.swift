//
//  MyAnnotation.swift
//  Map Demo
//
//  Created by Mashfique Anwar on 9/19/15.
//  Copyright (c) 2015 Mashfique Anwar. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class MyAnnotation : NSObject, MKAnnotation {
    dynamic var coordinate : CLLocationCoordinate2D
    var title: String!
    var subtitle: String!
    
    init(location coord:CLLocationCoordinate2D) {
        self.coordinate = coord
        super.init()
    }
}

