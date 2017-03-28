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
    
    
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 1.0)
        //mapView1.camera = camera
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        print("loaded camera")
    }

    
    @IBAction func parseAndGet(sender: AnyObject) {
        view.endEditing(true)
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 1.0)
        mapView1.camera = camera
        var sourceStr: String = origin.text!
        var destinationStr: String = destination.text!
        var error: NSError?
        var counter:UInt = 0
        var directionsURl = baseURLDirections+"origin="+sourceStr+"&destination="+destinationStr+"&alternatives=true"
        directionsURl = directionsURl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        let finalURL = NSURL(string: directionsURl)
        print("final url")
        let directionsData = NSData(contentsOfURL: finalURL!)
        print("directions data")
        dispatch_async(dispatch_get_main_queue(),{ () -> Void in
            //let directionsData = NSData(contentsOfURL: finalURL!)
            print(" in here")
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
                                self.overviewPolyline = item["overview_polyline"] as! Dictionary<NSObject, AnyObject>
                                let legs = item["legs"] as! Array<Dictionary<NSObject, AnyObject>>
                                
                                let startLoc = legs[0]["start_location"] as! Dictionary<NSObject, AnyObject>
                                self.originCoordinate =  CLLocationCoordinate2DMake(startLoc["lat"] as! Double, startLoc["lng"] as! Double)
                                
                                let endLoc = legs[legs.count - 1]["end_location"] as! Dictionary<NSObject, AnyObject>
                                self.destinationCoordinate = CLLocationCoordinate2DMake(endLoc["lat"] as! Double, endLoc["lng"] as! Double)
                                
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                                
                                print("origin address\(self.originAddress) destination \(self.destinationAddress)")
                                
                                self.calculateTotalDistanceAndDuration(item)
                                self.configureMapAndMarkersForRoute()
                                print("counter is \(counter)")
                                self.drawRoute(counter)
                                counter = counter+1
                            }
                            
                        }
                        
                    }
                }
            
            } catch {
                print(error)
            }
        })
        
    }

    
    func calculateTotalDistanceAndDuration(dum:Dictionary<NSObject,AnyObject>) {
        
        let legs = dum["legs"]as! NSArray
        
        totalDistanceInMeters = 0
        totalDurationInSeconds = 0
        
        for step in legs {
            totalDistanceInMeters += (step["distance"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
            totalDurationInSeconds += (step["duration"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
        }
        
        
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
    }

    
    
    
    func configureMapAndMarkersForRoute() {
        mapView1.camera = GMSCameraPosition.cameraWithTarget(self.originCoordinate, zoom: 9.0)
        originMarker = GMSMarker(position: self.originCoordinate)
        originMarker.map = self.mapView1
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.originAddress
        
        destinationMarker = GMSMarker(position: self.destinationCoordinate)
        destinationMarker.map = self.mapView1
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        destinationMarker.title = self.destinationAddress
    }
    
    func drawRoute(counter:UInt) {
        let route = self.overviewPolyline["points"] as! String
        //var counter:UInt = 0
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        if counter == 0{
            routePolyline.strokeColor = UIColor.blueColor()
        } else{
            routePolyline.strokeColor = UIColor.darkGrayColor()
        }
        routePolyline.strokeWidth = 5
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

