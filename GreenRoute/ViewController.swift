//
//  ViewController.swift
//  GreenRoute
//
//  Created by Vithala,Niharika on 3/20/17.
//  Copyright © 2017 Vithala,Niharika. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {

    @IBOutlet weak var origin: UITextField!
    @IBOutlet weak var destination: UITextField!
    @IBOutlet weak var dummy: UIButton!
    @IBOutlet weak var duration: UITextField!
    @IBOutlet weak var distance: UITextField!
    
    @IBOutlet weak var mapView1: GMSMapView!
    
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
    var selectedRoute: Dictionary<NSObject,AnyObject>!
    var notSelectedRoute: Array<Dictionary<NSObject, AnyObject>> = []
    var overviewPolyline: Dictionary<NSObject,AnyObject>!
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    var totalDistanceInMeters: UInt = 0
    var totalDistance: String!
    var totalDurationInSeconds: UInt = 0
    var totalDuration: String!
    var dict:[UInt:AnyObject] = [:]
    var minDuration:UInt = UInt.max
    var bufferDuration:UInt = 0
    var dataDict:[Double:Double] = [:]
    var routeDict:[UInt:Double] = [:]
    var totalFuel:Double = 0
    
    
    // in testing
    var displayDuration:String = ""
    var displayDistance:String = ""
    var displayRoute:UInt = 0
    
    
    //markers
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    
    //manage locations
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        print("Loaded camera")
    }
    
    @IBAction func parseAndGet(sender: AnyObject) {
        view.endEditing(true)
        
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 1.0)
        mapView1.camera = camera
        let sourceStr: String = origin.text!
        let destinationStr: String = destination.text!
        var error: NSError?
        
        //reset values
        self.minDuration = UInt.max
        self.bufferDuration = 0
        self.dict = [:]

        self.displayRoute = 0
        self.displayDuration = ""
        var directionsURl = baseURLDirections+"origin="+sourceStr+"&destination="+destinationStr+"&alternatives=true"
        directionsURl = directionsURl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let finalURL = NSURL(string: directionsURl)
        let directionsData = NSData(contentsOfURL: finalURL!)
        
        dataDict[8] = 0.07
        dataDict[16] = 0.065
        dataDict[18] = 0.065
        dataDict[20] = 0.06
        dataDict[25] = 0.05
        dataDict[30] = 0.046
        dataDict[35] = 0.043
        dataDict[40] = 0.041
        dataDict[45] = 0.04
        dataDict[50] = 0.038
        dataDict[55] = 0.036
        dataDict[60] = 0.0385
        dataDict[65] = 0.04
        dataDict[70] = 0.042
        dataDict[75] = 0.05
        dataDict[80] = 0.079

        dispatch_async(dispatch_get_main_queue(),{ () -> Void in
           
            print("start dispatching")
            // to deserialize the data.
            do {
                if let dictionary = try NSJSONSerialization.JSONObjectWithData(directionsData!, options: .MutableContainers) as? Dictionary<NSObject,AnyObject> {
                    print("check do")
                    if(error != nil){
                        print(error)
                    } else {
                        let status = dictionary["status"] as! String
                        if status == "OK" {
                            self.notSelectedRoute = (dictionary["routes"] as! Array<Dictionary<NSObject, AnyObject>>)

                            for item in self.notSelectedRoute {
                                self.displayRoute = self.displayRoute+1
                                self.overviewPolyline = item["overview_polyline"] as! Dictionary<NSObject, AnyObject>
                                var legs = item["legs"] as! Array<Dictionary<NSObject, AnyObject>>
                                
                                let startLoc = legs[0]["start_location"] as! Dictionary<NSObject, AnyObject>
                                self.originCoordinate =  CLLocationCoordinate2DMake(startLoc["lat"] as! Double, startLoc["lng"] as! Double)
                                
                                let endLoc = legs[legs.count - 1]["end_location"] as! Dictionary<NSObject, AnyObject>
                                self.destinationCoordinate = CLLocationCoordinate2DMake(endLoc["lat"] as! Double, endLoc["lng"] as! Double)
                                
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                                
                                print("origin address\(self.originAddress) destination \(self.destinationAddress)")
                                self.calculateTotalDistanceAndDuration(item)
                                
                                if(self.bufferDuration < self.minDuration) {
                                    self.minDuration = self.bufferDuration
                                }
                                self.dict[self.bufferDuration] = self.overviewPolyline
                            }
                            
                            self.configureMapAndMarkersForRoute()
                            self.drawRoute()
                        }
                        
                    }
                }
            
            } catch {
                print(error)
            }
        })
        
    }

    func calFuel(dum:Array<Dictionary<NSObject, AnyObject>>) -> Double{
        let steps = dum as NSArray
        var fuelForLeg = 0.0
        var distanceLeg = 0.0
        for step in steps {
            let distanceMetres = (step["distance"] as! Dictionary<NSObject, AnyObject>)["value"] as! Double
            let durationSeconds = (step["duration"] as! Dictionary<NSObject, AnyObject>)["value"] as! Double
            let distanceMiles = distanceMetres * 0.000621371
            let durationHours = durationSeconds / 3600
            let speed = distanceMiles / durationHours
            var minVal = 0.0
            for (key,value) in dataDict {
                if(key == speed){
                    minVal = value
                    break;
                } else {
                    if(minVal == 0.0){
                        minVal = value
                    } else {
                        if(key>speed && key<minVal){
                            minVal = value
                        }
                    }
                }
            }
            distanceLeg += distanceMiles
            print("distance\(distanceMiles)")
            
            print("duration\(durationHours)")
            let gallons = minVal*distanceMiles
            fuelForLeg += gallons
            //print("GALLONS\(gallons)")
            
        }
        print("distance\(distanceLeg)")
        return fuelForLeg
    }

    func calculateTotalDistanceAndDuration(dum:Dictionary<NSObject,AnyObject>) {

        let legs = dum["legs"]as! NSArray
        
        // to calculate speed for each leg in a step, fuel consumed is calculated by the called method.
        for leg in legs {
            let steps = leg["steps"] as! Array<Dictionary<NSObject, AnyObject>>
            var fuelForLeg = calFuel(steps)
            self.routeDict[displayRoute] = fuelForLeg
        }

        //not important now just to calculate distance and duration and display them.
        totalDistanceInMeters = 0
        totalDurationInSeconds = 0
        
        for step in legs {
            totalDistanceInMeters += (step["distance"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
            totalDurationInSeconds += (step["duration"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
        }
        
        self.bufferDuration = totalDurationInSeconds
        let distanceInKilometers: Double = Double(totalDistanceInMeters / 1000)
        totalDistance = "Total Distance: \(distanceInKilometers) Km"
        let mins = totalDurationInSeconds / 60
        let hours = mins / 60
        let days = hours / 24
        let remainingHours = hours % 24
        let remainingMins = mins % 60
        let remainingSecs = totalDurationInSeconds % 60
        totalDuration = "Duration: \(days) d, \(remainingHours) h, \(remainingMins) mins, \(remainingSecs) secs"
        distance.text = totalDistance
        duration.text = totalDuration
        print(totalDuration)
        print(totalDistance)
        self.displayDuration = "\(self.displayDuration)" + "Route \(self.displayRoute) \(totalDistance) \(totalDuration) \n"

    }
    
    func configureMapAndMarkersForRoute() {
        mapView1.clear()
        mapView1.camera = GMSCameraPosition.cameraWithTarget(self.originCoordinate, zoom: 9.0)
        originMarker = GMSMarker(position: self.originCoordinate)
        originMarker.map = self.mapView1
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.originAddress
        originMarker.snippet = "hi"
        originMarker.infoWindowAnchor = CGPoint(x: 2, y:2)
        // mapView1.selectedMarker = originMarker
        
        destinationMarker = GMSMarker(position: self.destinationCoordinate)
        destinationMarker.map = self.mapView1
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        destinationMarker.title = self.destinationAddress
    }
    
    func drawRoute() {
        for(key,val) in dict {
            if(key != self.minDuration){
                let r = dict[key]
                let s = r!["points"] as! String
                let path: GMSPath = GMSPath(fromEncodedPath: s)!
                routePolyline = GMSPolyline(path: path)
                routePolyline.strokeColor = UIColor.grayColor()
                routePolyline.strokeWidth = 2
                routePolyline.map = mapView1
                
            }
        }
        let u = dict[self.minDuration]
        let v = u!["points"] as! String
        let w:GMSPath = GMSPath(fromEncodedPath: v)!
        routePolyline = GMSPolyline(path: w)
        routePolyline.strokeColor = UIColor.greenColor()
        routePolyline.strokeWidth = 2
        routePolyline.map = mapView1
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    // 2
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // 3
        if status == .AuthorizedWhenInUse {
            
            // 4
            locationManager.startUpdatingLocation()
            
            //5
            mapView1.myLocationEnabled = true
            mapView1.settings.myLocationButton = true
        }
    }
    
    // 6
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            
            // 7
            mapView1.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            
            // 8
            locationManager.stopUpdatingLocation()
        }
        
    }
}