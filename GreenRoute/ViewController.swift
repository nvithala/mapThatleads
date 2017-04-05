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
    
    let baseURLDirections:String = "https://maps.googleapis.com/maps/api/directions/json?"
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
    var dataDictTraffic:[Double:Double] = [:]
    var routeDict:[UInt:Double] = [:]
    var totalFuel:Double = 0
    var finalDict:Array<Dictionary<NSObject, AnyObject>> = []

    // in testing
    var displayDuration:String = ""
    var displayDistance:String = ""
    var displayRoute:UInt = 0
    var minFuelOverall:Double = 1000000000000000
    var routeWithMinFuelNo:UInt = 0
    var routeWithMinDuration:UInt = 0
    var arrayOfPoints: Array<String> = []
    var dicForCustomMarkers: Array<Dictionary<NSObject,AnyObject>> = []
    var differenceFuel = 0.0
    var percentDiffFuel = 0.0
    var savingCO2 = 0.0
    var fuelSaved = 0.0
    var finalDisplayString:String = ""
    var fasterBy:String = ""
    
    
    //markers
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var fuelMarker: GMSMarker!
    var speedMarker: GMSMarker!
    
    
    //manage locations
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    @IBAction func parseAndGet(sender: AnyObject) {
        view.endEditing(true)
        let timeInterval = String(NSDate().timeIntervalSince1970)
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 1.0)
        mapView1.camera = camera
        let sourceStr: String = origin.text!
        let destinationStr: String = destination.text!
        var error: NSError?
        
        //reset values
        self.minDuration = UInt.max
        self.bufferDuration = 0
        self.dict = [:]
        self.finalDict = []
        self.routeDict = [:]
        self.arrayOfPoints = []
        self.minFuelOverall = 1000000000000000
        self.displayRoute = 0
        self.displayDuration = ""
        self.routeWithMinFuelNo = 0
        self.routeWithMinDuration = 0
        var directionsURl = baseURLDirections+"origin="+sourceStr+"&destination="+destinationStr+"&alternatives=true"+"&departure_time"+"1490993519000"
        directionsURl = directionsURl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let finalURL = NSURL(string: directionsURl)
        let directionsData = NSData(contentsOfURL: finalURL!)
        self.finalDisplayString = ""
        self.fasterBy = ""
        
        dataDict[7] = 0.0689655172413793
        dataDict[16.0625] = 0.0689655172413793
        dataDict[19] = 0.0526315789473684
        dataDict[27.8125] = 0.0510204081632653
        dataDict[38] = 0.0446428571428571
        dataDict[48.4] = 0.0354609929078014
        dataDict[60] = 0.0354609929078014
        dataDict[80] = 0.0571755288736421
        
        dataDictTraffic[10.34] = 0.0967117988394584
        dataDictTraffic[11.2] = 0.0892857142857143
        dataDictTraffic[19.2] = 0.0520833333333333
        dataDictTraffic[19.8] = 0.0505050505050505
        

        
        //MARK: desrialize the json response here. Mark the route with minimum duration
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
                                print("ROUTE:\(self.displayRoute)")
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
                                    self.routeWithMinDuration = self.displayRoute
                                }
                                var tempdict = ["route":self.bufferDuration,"polyline":self.overviewPolyline]
                                self.finalDict.append(tempdict as! Dictionary<NSObject, AnyObject>)
                                self.displayRoute = self.displayRoute+1
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
    
    func nextHighest(n: Double) -> Double? {
        let higher:Array<Double> = dataDict.keys.filter{$0 >= n}
        let k = higher.isEmpty ? nil : dataDict[higher.minElement()!]
        return k
    }
    
    func clearMarkers(){
        
    }
    
    //MARK: calculate fuel for each leg in route
    func calFuel(dum:Array<Dictionary<NSObject, AnyObject>>) -> Double{
        let steps = dum as NSArray
        let noOFSteps = steps.count
        let mid = Int(noOFSteps/2)
        let temp = steps[mid] as! Dictionary<NSObject,AnyObject>
        print(temp)
        let temp1 = temp["start_location"] as! Dictionary<NSObject,AnyObject>
        self.dicForCustomMarkers.append(temp1)
        var fuelForLeg = 0.0
        var distanceLeg = 0.0
        var minKey:UInt = 0
        for step in steps {
            let distanceMetres = (step["distance"] as! Dictionary<NSObject, AnyObject>)["value"] as! Double
            let durationSeconds = (step["duration"] as! Dictionary<NSObject, AnyObject>)["value"] as! Double
            let distanceMiles = distanceMetres * 0.000621371
            let durationHours = durationSeconds / 3600
            let speed = distanceMiles / durationHours
            let minMiles = nextHighest(speed)
            distanceLeg += distanceMiles
            let gallons = minMiles!*distanceMiles
            fuelForLeg += gallons
        }
        print("GALLONS\(fuelForLeg)")
        return fuelForLeg
    }
    
    func calculateTotalDistanceAndDuration(dum:Dictionary<NSObject,AnyObject>) {
        let legs = dum["legs"]as! NSArray
        // to calculate speed for each leg in a step, fuel consumed is calculated by the called method.
        for leg in legs {
            let steps = leg["steps"] as! Array<Dictionary<NSObject, AnyObject>>
            var fuelForLeg = calFuel(steps)
            if(fuelForLeg < self.minFuelOverall){
                minFuelOverall = fuelForLeg
                self.routeWithMinFuelNo = self.displayRoute
            }
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
    
    //MARK: configuring markers for routes
    func configureMapAndMarkersForRoute() {
        mapView1.clear()
        fuelMarker = nil
        speedMarker = nil
        originMarker = nil
        destinationMarker = nil
        self.fasterBy = ""
        mapView1.camera = GMSCameraPosition.cameraWithTarget(self.originCoordinate, zoom: 9.0)
        originMarker = GMSMarker(position: self.originCoordinate)
        originMarker.map = self.mapView1
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.originAddress
        
        destinationMarker = GMSMarker(position: self.destinationCoordinate)
        destinationMarker.map = self.mapView1
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        destinationMarker.title = self.destinationAddress
        
        //MARK: for speed comparisions
        let x = self.finalDict[Int(self.routeWithMinDuration)] as Dictionary<NSObject,AnyObject>
        let y = x["route"] as! Int
        print(y)
        let z = self.finalDict[Int(self.routeWithMinFuelNo)] as Dictionary<NSObject,AnyObject>
        let w = z["route"] as! Int
        print(w)
        let diff = w-y
        print(diff)
        self.fasterBy = "This route is faster by"+String(diff/60)+"mins"
        print(self.fasterBy)
        
        //MARK:fuel calculations
        let fuel1 = self.routeDict[self.routeWithMinDuration] as Double!
        let fuel2 = self.routeDict[self.routeWithMinFuelNo] as Double!
        self.differenceFuel = fuel1-fuel2
        self.percentDiffFuel = (self.differenceFuel/fuel1)*100
        self.fuelSaved = self.differenceFuel*2.50
        self.savingCO2 = self.differenceFuel*19.64

        let a = String(format: "%.2f", self.differenceFuel)
        let b = String(format: "%.2f", self.fuelSaved)
        let c = String(format: "%.2f", self.savingCO2)
        
        self.finalDisplayString = "Diff in fuel:"+a+"gallons,\n $ Saved:"+b+"$,\n Reduction in CO2 emissions:"+c+"lbs"
        
        //MARK: displaying custom marker with calculations
        if(self.routeWithMinDuration != self.routeWithMinFuelNo){
            var customMarker = self.dicForCustomMarkers[Int(self.routeWithMinFuelNo)]
            var start_point = CLLocationCoordinate2DMake(customMarker["lat"] as! Double, customMarker["lng"] as! Double)
            fuelMarker = GMSMarker(position: start_point)
            fuelMarker.map = self.mapView1
            fuelMarker.icon = UIImage(named: "smaller.jpeg")
            fuelMarker.snippet = self.finalDisplayString
            fuelMarker.title = "Fuel Efficient route!"
            mapView1.selectedMarker=fuelMarker
            
            // speed marker
//            var customMarker1 = self.dicForCustomMarkers[Int(self.routeWithMinDuration)]
//            var start_point1 = CLLocationCoordinate2DMake(customMarker1["lat"] as! Double, customMarker1["lng"] as! Double)
//            speedMarker = GMSMarker(position: start_point1)
//            speedMarker.map = self.mapView1
//            speedMarker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
//            speedMarker.snippet = self.fasterBy
//            speedMarker.title = "Fastest route!"
//            //mapView1.selectedMarker=speedMarker
        } else {
            var speedMarker = self.dicForCustomMarkers[Int(self.routeWithMinFuelNo)]
            var start_point = CLLocationCoordinate2DMake(speedMarker["lat"] as! Double, speedMarker["lng"] as! Double)
            fuelMarker = GMSMarker(position: start_point)
            fuelMarker.map = self.mapView1
            fuelMarker.icon = UIImage(named: "smallestcar.jpeg")
            fuelMarker.snippet = "Faster route is also the most fuel efficient route!"
            fuelMarker.title = "Faster Route!"
            mapView1.selectedMarker=fuelMarker
            
        }
        
     }
    
    func drawRoute() {
        for step in finalDict {
            var poly = step["polyline"] as! Dictionary<String,AnyObject>
            var points = poly["points"] as! String
            self.arrayOfPoints.append(points)
        }
        compareAndDraw()
    }
 
    //MARK: drawing routes based on fuel vs duration factor
    func compareAndDraw(){
        if(self.routeWithMinDuration == self.routeWithMinFuelNo){
            var points = self.arrayOfPoints[Int(self.routeWithMinFuelNo)]
            let path: GMSPath = GMSPath(fromEncodedPath: points)!
            routePolyline = GMSPolyline(path: path)
            routePolyline.strokeColor = UIColor.blueColor()
            routePolyline.strokeWidth = 5
            routePolyline.map = mapView1
        } else {
            //MARK: calculating difference in fuel and efficiencies.
            
            let googlePoints = self.arrayOfPoints[Int(self.routeWithMinDuration)]
            let path: GMSPath = GMSPath(fromEncodedPath: googlePoints)!
            routePolyline = GMSPolyline(path: path)
            routePolyline.strokeColor = UIColor.blueColor()
            routePolyline.strokeWidth = 5
            routePolyline.map = mapView1
            
            var greenRoute = self.arrayOfPoints[Int(self.routeWithMinFuelNo)]
            var path2 = GMSPath(fromEncodedPath: greenRoute)!
            routePolyline = GMSPolyline(path: path2)
            routePolyline.strokeColor = UIColor.greenColor()
            routePolyline.strokeWidth = 5
            routePolyline.map = mapView1
        }
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