//
//  ViewController.swift
//  Map Demo
//
//  Created by Mashfique Anwar on 6/7/15.
//  Copyright (c) 2015 Mashfique Anwar. All rights reserved.
//


import UIKit

import MapKit           // IMPORTANT- for map view

import CoreLocation     // IMPORTANT - for user's location

import Foundation

import QuartzCore


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSXMLParserDelegate {
    
    // MKMapViewDelegate helps to control the map view
    // CLLocationManagerDelegate helps to get the user's location
    
    //************************************For XML Parser*********************************************
    var parser = NSXMLParser()
    
    var latitudeArray: NSMutableArray = NSMutableArray()
    var longitudeArray: NSMutableArray = NSMutableArray()
    
    //*********************************************************************************************
    
    @IBOutlet var map: MKMapView!
    
    var locationManager = CLLocationManager()       // the variable that we'll access when we need to do something with the location. Should be outside viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.removeOverlays(map.overlays)
        map.delegate = self
        beginParsing()
        
        // Determining the user's location
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Setting User Location
        
        let latitude:CLLocationDegrees = 44.973366
        let longitude:CLLocationDegrees = -93.217622
        
        let latDelta:CLLocationDegrees = 0.07 // latDelta is the difference between latitudes from one side of the screen to the other. For eg 0.00001 would be very zoomed in and 1 would be very zoomed out!
        let lonDelta:CLLocationDegrees = 0.07   // similar to latDelta
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)    // a span is basically the combination of two deltas (i.e., the two changes between degrees)
        
        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)   // a pair of coordinates
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)    // combines the span and location
        
        //var timer = NSTimer.scheduledTimerWithTimeInterval(0.09, target: self, selector: "exampleTimer", userInfo: nil, repeats: true)
        
        map.setRegion(region, animated: false)
        map.rotateEnabled = false
    }
    
    
    // This function will be called everytime a new location is registered by the phone. This is basically the function which updates the current location of the user!
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation : CLLocation = locations[0] as CLLocation
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        let latDelta:CLLocationDegrees = 0.01 // latDelta is the difference between latitudes from one side of the screen to the other. For eg 0.00001 would be very zoomed in and 1 would be very zoomed out!
        
        let lonDelta:CLLocationDegrees = 0.01   // similar to latDelta
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)    // a span is basically the combination of two deltas (i.e., the two changes between degrees)
        
        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)   // a pair of coordinates
        
        var region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)    // combines the span and location
        
        //self.map.setRegion(region, animated: true)      // need to add self since we're in a closure (not sure if we need this line)
        
        
    }
    
    
    func addPolyLineToMap(locations: [CLLocation!])
    {
        var coordinates = locations.map({ (location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        
        let polyline = MKPolyline(coordinates: &coordinates, count: locations.count)
        
        self.map.addOverlay(polyline)
    }
    
    func mapView(mapView: MKMapView!, viewForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        
        if (overlay is MKPolyline) {
            let pr = MKPolylineRenderer(overlay: overlay);
            pr.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.5);
            pr.lineWidth = 5;
            return pr;
        }
        
        return nil
    }
    
    //***************** XML Parsing *******************//
    
    var control = ""    // this will "control" the conditional statements in the parser
    
    func beginParsing() {
        control = "drawingRoutes"
        let urlForRoutes = NSURL(string: "http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=umn-twin&r=connector")
        parser = NSXMLParser(contentsOfURL: urlForRoutes!)!
        parser.delegate = self
        parser.parse()
        
        
        
        //var timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateBusLocation", userInfo: nil, repeats: true)
    }
    
    func updateBusLocation() {
        control = "trackingBuses"
        let epochTime = String(Int(NSDate().timeIntervalSince1970))     // calculate Epoch Time   // example epochTime: 1442694234
        let urlForTrackingBuses = NSURL(string: "http://webservices.nextbus.com/service/publicXMLFeed?command=vehicleLocations&a=umn-twin&r=connector&t=\(epochTime)")
        parser = NSXMLParser(contentsOfURL: urlForTrackingBuses!)!
        parser.delegate = self
        parser.parse()
    }
    
    func getStopPrediction(stopID: String) {
        control = "prediction"
        let urlForPredictions = NSURL(string: "http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=umn-twin&r=connector&s=\(stopID)")
        parser = NSXMLParser(contentsOfURL: urlForPredictions!)!
        parser.delegate = self
        parser.parse()
    }
    
    var lookedMoreThanOnce = false
    var startTrackingBuses = false

    var busDirection = CLLocationDirection()
    
    var myAnnotation:Bus!
    var busArray: [Bus!] = []   //Empty array to hold "Bus" annotation types
    
    var vehicleCount = 0
    var oldVehicleCount = 0
    var vehicleIndex = 0
    var trackingBusForTheVeryFirstTime = true
    
    // Boolean for stop annotations (Need to change name before final release) :
    var stopAnnotation = false
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if (control == "drawingRoutes") {
            // ------------------------------------------------ For Drawing Routes ----------------------------------------------//
            if (elementName == "stop") {
                if let latitude = (attributeDict["lat"]){
                    if let longitude = (attributeDict["lon"]) {
                        let coord = CLLocationCoordinate2DMake(Double(latitude)!, Double(longitude)!)
                        let ann = StopAnnotation()
                        
                        ann.coordinate = coord
                        ann.title = attributeDict["title"] as String!
                        ann.subtitle = "Predictions???"         // So predictions need to be done in the same function too!
                        ann.imageName = "stop.png"
                        
                        self.map.addAnnotation(ann)
                    }
                }
                
            }
            
            if (elementName == "path") {
                if (lookedMoreThanOnce == true) {
                    // Clear the arrays (2 arrays: latitudeArray, longitudeArray)
                    latitudeArray.removeAllObjects()
                    longitudeArray.removeAllObjects()
                }
            }
            
            if (elementName == "point") {
                lookedMoreThanOnce = true
                latitudeArray.addObject(attributeDict["lat"]!)
                longitudeArray.addObject(attributeDict["lon"]!)
                
                // Draw the line
                let latArray = latitudeArray as NSArray as! [String]
                let lonArray = longitudeArray as NSArray as! [String]
                
                var locations: [CLLocation] = []
                
                //println(latArray.count)
                for (var i = 0; i < latArray.count; i++) {
                    let tempLat = (latArray[i] as NSString).doubleValue
                    let tempLon = (lonArray[i] as NSString).doubleValue
                    let tempLocation = CLLocation(latitude: tempLat, longitude: tempLon)
                    
                    locations.append(tempLocation)
                }
                
                addPolyLineToMap(locations)
            }
            // ---------------------------------------------------------------------------------------------------------------//
        }
        else if (control == "trackingBuses") {
            self.stopAnnotation = false     // Now we're tracking buses, so this should be set to false
            if (elementName == "body"){
                // Need to check oldVehicleCount with current one
                
                if vehicleCount > 0 {
                    trackingBusForTheVeryFirstTime = false
                }
                
                if (vehicleCount != oldVehicleCount && !trackingBusForTheVeryFirstTime) {
                    trackingBusForTheVeryFirstTime = true
                    busArray.removeAll(keepCapacity: false)
                }
            }
            else if (elementName == "vehicle") {
                //firstTimeTrackingBus = true;
                
                let latitude = Double(attributeDict["lat"]!)
                let longitude = Double(attributeDict["lon"]!)
                let dir = Double(attributeDict["heading"]!)
                
                let currentCoord = CLLocationCoordinate2DMake(latitude!, longitude!)
                
                // Checking the buses for the VERY FIRST TIME
                if (trackingBusForTheVeryFirstTime || vehicleCount == 0) {
                    
                    // Generate bus array
                    let bus = Bus(coord: currentCoord)      // remember to add ID
                    self.busArray.append(bus)
                    self.vehicleCount++
                    self.oldVehicleCount = self.vehicleCount
                }
                else {  // UPDATE BUS Location. Note: this is not the first time
                    
                    if (self.vehicleIndex >= self.vehicleCount) {
                        // Need to start over as the number of buses may have changed
                        self.trackingBusForTheVeryFirstTime = true
                        
                        // Need to delete existing annotations from the map
                        
                        // Empty busArray
                        busArray.removeAll(keepCapacity: false)
                        
                        // Reset count and index for buses
                        self.vehicleCount = 0
                        self.vehicleIndex = 0
                        return
                    }
                    
                    let oldCoord = busArray[vehicleIndex].oldCoord
                    
                    if (oldCoord.latitude == latitude && oldCoord.longitude == longitude) {
                        // Delete annotation or do nothing
                        return
                    }
                    else {
                        
                        // Rotating the bus:
                        UIView.animateWithDuration(0.5) {
                            self.busArray[self.vehicleIndex].coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                            
                            
                            // If bus annotations have not been added to the map yet:
                            if (self.busArray[self.vehicleIndex].addedToMap == false) {
                                self.map.addAnnotation(self.busArray[self.vehicleIndex])
                                self.busArray[self.vehicleIndex].addedToMap = true
                                return
                            }
                            self.busArray[self.vehicleIndex].angle = CGFloat(self.degreesToRadians(dir!))
                        }
                        
                        if (vehicleIndex < vehicleCount - 1) {
                            self.vehicleIndex++
                        }
                        else {
                            self.vehicleIndex = 0
                        }
                        return
                    }
                }
                
            }
            
        }
    }

    
    var newStop = StopAnnotation()
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        
        if (annotation is StopAnnotation) {
            let reuseId = "pin"
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            
            if pinView == nil {
                pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                self.view.addSubview(pinView!)
            }
            else {
                pinView!.annotation = annotation
            }
            
            //let stop = annotation as! StopAnnotation
            pinView!.image = imageWithImage(UIImage(named:"stop.png")!, scaledToSize: CGSize(width: 11.0, height: 11.0))
            pinView!.canShowCallout = true
            pinView!.layer.zPosition = -1
            
            let btn = UIButton(type: .DetailDisclosure)
            pinView?.rightCalloutAccessoryView = btn
            
            return pinView
        }
        
        let reuseId = "pin\(self.vehicleIndex)"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        
        
        if pinView == nil {
            pinView = BusAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.image = imageWithImage(UIImage(named:"arrow.png")!, scaledToSize: CGSize(width: 19.0, height: 19.0))
            self.view.addSubview(pinView!)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // For resizing image for bus annotation
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // For rotating bus annotations:
    func degreesToRadians(degrees: Double) -> Double { return degrees * M_PI / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / M_PI }
    
    // Adapted from http://nshipster.com/mkgeodesicpolyline/
    
    func directionBetweenPoints(sourcePoint: MKMapPoint, destinationPoint : MKMapPoint) -> CLLocationDirection {
        let x : Double = destinationPoint.x - sourcePoint.x;
        let y : Double = destinationPoint.y - sourcePoint.y;
        
        return fmod(radiansToDegrees(atan2(y, x)), 360.0) + 90.0;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}