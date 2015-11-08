//
//  bus.swift
//  Map Demo
//
//  Created by Mashfique Anwar on 10/24/15.
//  Copyright (c) 2015 Mashfique Anwar. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class Bus : MKPointAnnotation  {
    var oldCoord : CLLocationCoordinate2D!
    var addedToMap = false
    dynamic var angle: CGFloat = 0.0

    init(coord: CLLocationCoordinate2D) {
        self.oldCoord = coord
    }
}

private var angleObserverContext = 0

// Subclassed MKAnnotationView so that whenever the "angle" property of a Bus annotation is changed, the corresponding bus is rotated
class BusAnnotationView : MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        addAngleObserver()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // add observer
    
    private func addAngleObserver() {
        if let annotation = annotation as? Bus {
            transform = CGAffineTransformMakeRotation(annotation.angle)
            annotation.addObserver(self, forKeyPath: "angle", options: .New | .Old, context: &angleObserverContext)
        }
    }
    
    // remove observer
    
    private func removeAngleObserver() {
        if let annotation = annotation as? Bus {
            annotation.removeObserver(self, forKeyPath: "angle")
        }
    }
    
    // remember to remove observer when annotation view is deallocated
    
    deinit {
        removeAngleObserver()
    }
    
    // Remember, since annotation views can be reused, if the annotation changes,
    // remove the old annotation's observer, if any, and add new one's.
    
    override var annotation: MKAnnotation? {
        willSet {
            removeAngleObserver()
        }
        didSet {
            addAngleObserver()
        }
    }
    
    // Handle observation events for the annotation's `angle`, rotating as appropriate
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
        if context == &angleObserverContext {
            UIView.animateWithDuration(0.5) {
                if let angleNew = change[NSKeyValueChangeNewKey] as? CGFloat {
                    self.transform = CGAffineTransformMakeRotation(angleNew)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}






