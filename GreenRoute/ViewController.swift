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
    @IBOutlet weak var mapView1: GMSMapView!
    @IBOutlet weak var labe: UITextView!
    
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
    var selectedRoute: Dictionary<String,AnyObject>!
    var notSelectedRoute: Array<Dictionary<String, AnyObject>> = []
    var overviewPolyline: Dictionary<String,AnyObject>!
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 1.0)
        //mapView1.camera = camera
        print("loadeed camera")
    }

    @IBAction func parseAndGet(_ sender: AnyObject) {
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 1.0)
        mapView1.camera = camera
        var sourceStr: String = origin.text!
        var destinationStr: String = destination.text!
        var error: NSError?
        var counter:UInt = 0
        var directionsURl = baseURLDirections+"origin="+sourceStr+"&destination="+destinationStr+"&alternatives=true"
        directionsURl = directionsURl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        labe.text = ""
        mapView1.clear()
        let finalURL = URL(string: directionsURl)
        print("final url")
        let directionsData = try? Data(contentsOf: finalURL!)
        print("directions data")
        DispatchQueue.main.async(execute: { () -> Void in
            //let directionsData = NSData(contentsOfURL: finalURL!)
            print(" in here")
            // to deserialize the data.
            do {
                if let dictionary = try JSONSerialization.jsonObject(with: directionsData!, options: .mutableContainers) as? Dictionary<String,AnyObject> {
                    print("check do")
                    if(error != nil){
                        print(error)
                    } else {
                        let status = dictionary["status"] as! String
                        if status == "OK" {
                            self.notSelectedRoute = (dictionary["routes"] as! Array<Dictionary<String, AnyObject>>)
                            for item in self.notSelectedRoute {
                                self.overviewPolyline = item["overview_polyline"] as! Dictionary<String, AnyObject>
                                let legs = item["legs"] as! Array<Dictionary<String, AnyObject>>
                                
                                let startLoc = legs[0]["start_location"] as! Dictionary<String, AnyObject>
                                self.originCoordinate =  CLLocationCoordinate2DMake(startLoc["lat"] as! Double, startLoc["lng"] as! Double)
                                
                                let endLoc = legs[legs.count - 1]["end_location"] as! Dictionary<String, AnyObject>
                                self.destinationCoordinate = CLLocationCoordinate2DMake(endLoc["lat"] as! Double, endLoc["lng"] as! Double)
                                
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                                
                                print("origin address\(self.originAddress) destination \(self.destinationAddress)")
                                
                                self.calculateTotalDistanceAndDuration(item)
                                self.configureMapAndMarkersForRoute()
                                print("counter is \(counter)")
                                self.drawRoute(counter)
                                counter = counter+1
                                self.labe.text = self.labe.text+self.totalDistance+" "+self.totalDuration+"\n"
                            }
                            
                        }
                        
                    }
                }
            
            } catch {
                print(error)
            }
        })
        
    }

    
    func calculateTotalDistanceAndDuration(_ dum:Dictionary<String,AnyObject>) {
        
        let legs = dum["legs"]as! [[String:Any]]
        
        totalDistanceInMeters = 0
        totalDurationInSeconds = 0
        print ("leg is\(legs)")
        for step in legs {
            totalDistanceInMeters += (step["distance"] as! Dictionary<String, AnyObject>)["value"] as! UInt
            totalDurationInSeconds += (step["duration"] as! Dictionary<String, AnyObject>)["value"] as! UInt
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

        print(totalDuration)
        print(totalDistance)
    }

    func configureMapAndMarkersForRoute() {
        mapView1.camera = GMSCameraPosition.camera(withTarget: self.originCoordinate, zoom: 9.0)
        originMarker = GMSMarker(position: self.originCoordinate)
        originMarker.map = self.mapView1
        originMarker.icon = GMSMarker.markerImage(with: UIColor.green)
        originMarker.title = self.originAddress
        
        destinationMarker = GMSMarker(position: self.destinationCoordinate)
        destinationMarker.map = self.mapView1
        destinationMarker.icon = GMSMarker.markerImage(with: UIColor.red)
        destinationMarker.title = self.destinationAddress
    }
    
    func drawRoute(_ counter:UInt) {
        let route = self.overviewPolyline["points"] as! String
        //var counter:UInt = 0
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        if counter == 0{
            routePolyline.strokeColor = UIColor.blue
        } else{
            routePolyline.strokeColor = UIColor.darkGray
        }
        routePolyline.strokeWidth = 5
        routePolyline.map = mapView1
    }

}

