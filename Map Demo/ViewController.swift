//
//  ViewController.swift
//  Map Demo
//
//  Created by Mashfique Anwar on 6/7/15.
//  Copyright (c) 2015 Mashfique Anwar. All rights reserved.
//

//** Don't forget to add core-location framework and setup info.plist.

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
    
    //************************************************************************************************
    
    @IBOutlet var map: MKMapView!
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        map.removeOverlays(map.overlays)
        map.delegate = self
        beginParsing()      // Begin parsing the XML- starting with drawing routes and marking bus stops
 
        // Determining the user's location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()         // for our app, we'll request authorzation only when our app is running
        locationManager.startUpdatingLocation()
        
        
        // Setting User Location
        var latitude:CLLocationDegrees = 44.973366
        var longitude:CLLocationDegrees = -93.217622
        
        var latDelta:CLLocationDegrees = 0.07 // latDelta is the difference between latitudes from one side of the screen to the other. For eg 0.00001 would be very zoomed in and 1 would be very zoomed out!
        var lonDelta:CLLocationDegrees = 0.07   // similar to latDelta
        
        var span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)    // a span is basically the combination of two deltas (i.e., the two changes between degrees)
        
        var location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)   // a pair of coordinates
    
        var region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)    // combines the span and location
        map.setRegion(region, animated: true)
    }
    
    
    // This function will be called everytime a new location is registered by the phone. This is basically the function which updates the current location of the user!
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println(locations)
                
        var userLocation : CLLocation = locations[0] as CLLocation
        
        var latitude = userLocation.coordinate.latitude
        var longitude = userLocation.coordinate.longitude
        
        var latDelta:CLLocationDegrees = 0.01 // latDelta is the difference between latitudes from one side of the screen to the other. For eg 0.00001 would be very zoomed in and 1 would be very zoomed out!
        var lonDelta:CLLocationDegrees = 0.01   // similar to latDelta
        
        var span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)    // a span is basically the combination of two deltas (i.e., the two changes between degrees)
        
        var location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        var region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)    // combines the span and location
        
        //self.map.setRegion(region, animated: true)      // need to add self since we're in a closure
    }
    
    // ------------------- For MKPolyLine -------------------//
    
    func addPolyLineToMap(locations: [CLLocation!])
    {
        var coordinates = locations.map({ (location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        
        var polyline = MKPolyline(coordinates: &coordinates, count: locations.count)
        
        self.map.addOverlay(polyline)
    }
    
    func mapView(mapView: MKMapView!, viewForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        
        if (overlay is MKPolyline) {
            var pr = MKPolylineRenderer(overlay: overlay);
            pr.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.5);
            pr.lineWidth = 5;
            return pr;
        }
        
        return nil
    }
    // ------------------------------------------------//
    
    //***************** XML Parsing *******************//
    
    var control = ""    // this will "control" the conditional statements in the parser
    
    func beginParsing() {
        control = "drawingRoutes"
        var urlForRoutes = NSURL(string: "http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=umn-twin&r=connector")
        parser = NSXMLParser(contentsOfURL: urlForRoutes)!
        parser.delegate = self
        parser.parse()
  
        var timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateBusLocation", userInfo: nil, repeats: true)
    }
    
    func updateBusLocation() {
        control = "trackingBuses"
        var epochTime = String(Int(NSDate().timeIntervalSince1970))     // calculate Epoch Time   // example epochTime: 1442694234
        var urlForTrackingBuses = NSURL(string: "http://webservices.nextbus.com/service/publicXMLFeed?command=vehicleLocations&a=umn-twin&r=connector&t=\(epochTime)")
        parser = NSXMLParser(contentsOfURL: urlForTrackingBuses)!
        parser.delegate = self
        parser.parse()
    }
    
    var lookedMoreThanOnce = false
    var startTrackingBuses = false
    
    var busDirection = CLLocationDirection()
    
    var myAnnotation:Bus!
    var busArray: [Bus!] = []   //Empty array holding "Bus" annotation types
    
    var vehicleCount = 0
    var oldVehicleCount = 0
    var vehicleIndex = 0
    var trackingBusForTheVeryFirstTime = true
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: NSDictionary!) {
        if (control == "drawingRoutes") {
            // ------------------------------------------------ For Drawing Routes ----------------------------------------------//
            if (elementName == "stop") {
                if let latitude = attributeDict["lat"]?.doubleValue {
                    if let longitude = attributeDict["lon"]?.doubleValue {
                        let coord = CLLocationCoordinate2DMake(latitude, longitude)
                        let ann = StopAnnotation()
                        
                        ann.coordinate = coord
                        ann.title = attributeDict["title"] as String!
                        ann.subtitle = "Predictions???"
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
                let latArray = latitudeArray as NSArray as [String]
                let lonArray = longitudeArray as NSArray as [String]
                var locations: [CLLocation] = []
                
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
                
                let latitude = attributeDict["lat"]?.doubleValue
                let longitude = attributeDict["lon"]?.doubleValue
                let id = attributeDict["id"]?.string
                let dir = attributeDict["heading"]?.doubleValue
                                
                var currentCoord = CLLocationCoordinate2DMake(latitude!, longitude!)
                
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
                    //usArray[vehicleIndex] = Bus(coord: currentCoord)
                    
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
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
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
            
            let stop = annotation as StopAnnotation
            pinView.image = imageWithImage(UIImage(named:stop.imageName)!, scaledToSize: CGSize(width: 13.0, height: 13.0))
            pinView.canShowCallout = true
            return pinView
        }
        
        let reuseId = "pin\(self.vehicleIndex)"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        
        if pinView == nil {
            pinView = BusAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.image = imageWithImage(UIImage(named:"arrow.png")!, scaledToSize: CGSize(width: 21.0, height: 21.0))
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
    
    //************************************************//
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}