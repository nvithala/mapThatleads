//
//  ViewController.swift
//  GreenRoute
//
//  Created by Vithala,Niharika on 3/20/17.
//  Copyright © 2017 Vithala,Niharika. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
//import JSSAlertView

var justOnce:Bool = true

class ViewController: UIViewController,CLLocationManagerDelegate {

    @IBOutlet weak var origin: UITextField!
    @IBOutlet weak var destination: UITextField!
    @IBOutlet weak var dummy: UIButton!
    @IBOutlet weak var duration: UITextField!
    @IBOutlet weak var distance: UITextField!
    @IBOutlet weak var trial1: UITextField!
    @IBOutlet weak var trial2: UITextField!
    @IBOutlet weak var mapView1: GMSMapView!
    
    //MARK:from here
    let baseURLDirections:String = "https://maps.googleapis.com/maps/api/directions/json?"
    var selectedRoute: Dictionary<NSObject,AnyObject>!
    var returnedRoute: Array<Dictionary<NSObject, AnyObject>> = []
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
    var hybriddataDict:[Double:Double] = [:]
    var semidataDict:[Double:Double] = [:]
    var routeDict:[UInt:Double] = [:]
    var totalFuel:Double = 0
    var finalDict:Array<Dictionary<NSObject, AnyObject>> = []
    var hybrid: Bool = false
    var NOThybrid: Bool = false
    var semi:Bool = false
    
    var sourceTap: Bool = false

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
    var placesClient: GMSPlacesClient!
    var bounds = GMSCoordinateBounds()
    var sourceStr: String = ""
    var destinationStr: String = ""
    var flagForRoute:Bool = true
 
    //markers
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var fuelMarker: GMSMarker!
    var speedMarker: GMSMarker!
    
    var locationManager = CLLocationManager()
    var error:NSError!
    var didFindMyLocation = false
    
    var locationMarker: GMSMarker!
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        placesClient = GMSPlacesClient.sharedClient()


    }
    
    override func viewDidAppear(animated: Bool) {
        if(justOnce){
            let alertController = UIAlertController(title: "Car Type", message: "Please select your car type", preferredStyle: .Alert)
            
            let actionHybrid = UIAlertAction(title: "Hybrid", style: .Default) { (action:UIAlertAction) in
                print("You've pressed the Hybrid button")
                self.hybrid = true
            }
            
            let actionNormal = UIAlertAction(title: "Normal", style: .Default) { (action:UIAlertAction) in
                print("You've pressed Normal button")
                self.NOThybrid = true
            }
            
            let actionSemi = UIAlertAction(title: "Semi-Truck", style: .Default) { (action:UIAlertAction) in
                print("You've pressed the Semi button")
                self.semi = true
            }
            let image:UIImage? = UIImage(named:"hybrid.jpg")!.imageWithRenderingMode(.AlwaysOriginal)
            let image1:UIImage? = UIImage(named:"conventional.jpg")!.imageWithRenderingMode(.AlwaysOriginal)
            let image2:UIImage? = UIImage(named:"semi-truck.jpg")!.imageWithRenderingMode(.AlwaysOriginal)

            actionHybrid.setValue(image, forKey: "image")
            actionNormal.setValue(image1, forKey: "image")
            actionSemi.setValue(image2, forKey: "image")
            
            alertController.addAction(actionHybrid)
            alertController.addAction(actionNormal)
            alertController.addAction(actionSemi)
            
            self.presentViewController(alertController, animated: true, completion:nil)
            justOnce=false
        }
        
    }

    func clearDictionaries(){
        self.dict = [:]
        self.finalDict = []
        self.routeDict = [:]
        self.arrayOfPoints = []
        self.dicForCustomMarkers = []
    }
    
    @IBAction func openGmaps(sender: AnyObject) {
        var googleURLString = "http://maps.google.com?f=d&saddr=\(self.sourceStr)&daddr=\(self.destinationStr)&sspn=0.2,0.1&nav=1"
        googleURLString = googleURLString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        print(self.originCoordinate)
        if let googleUrl = NSURL(string: googleURLString) {
            if UIApplication.sharedApplication().canOpenURL(googleUrl){
                UIApplication.sharedApplication().openURL(googleUrl)
            } else {
                let alertController = UIAlertController(title: "Error", message: "Something is wrong!", preferredStyle: .Alert)
                self.presentViewController(alertController, animated: true, completion:nil)
            }
        }
        
    }
    
    @IBAction func parseAndGet(sender: AnyObject) {
        view.endEditing(true)
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 1.0)
        mapView1.camera = camera
         sourceStr = origin.text!
        destinationStr = destination.text!
       
        var error: NSError?
        
        self.clearDictionaries()
        self.minDuration = UInt.max
        self.bufferDuration = 0
        self.minFuelOverall = 1000000000000000
        self.displayRoute = 0
        self.displayDuration = ""
        self.routeWithMinFuelNo = 0
        self.routeWithMinDuration = 0
        self.finalDisplayString = ""
        self.fasterBy = ""
        
        var directionsURl = baseURLDirections+"origin="+sourceStr+"&destination="+destinationStr+"&alternatives=true"+"&departure_time"+"1490993519000"
        directionsURl = directionsURl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let finalURL = NSURL(string: directionsURl)
        let directionsData = NSData(contentsOfURL: finalURL!)
        
        //MARK: data
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
        
        //MARK: hybrid Data
        hybriddataDict[5] = 0.0202604920402102
        hybriddataDict[10] = 0.0202839756578303
        hybriddataDict[15] = 0.020333075132268
        hybriddataDict[20] = 0.0204081632593086
        hybriddataDict[25] = 0.0205098154020884
        hybriddataDict[30] = 0.0202604920402102
        hybriddataDict[35] = 0.0207961972472435
        hybriddataDict[40] = 0.020983213403166
        hybriddataDict[45] = 0.0212014133937445
        hybriddataDict[50] = 0.0214526508918699
        hybriddataDict[55] = 0.0217391303814272
        hybriddataDict[60] = 0.0220634586442949
        hybriddataDict[65] = 0.0224287086676216
        hybriddataDict[70] = 0.0228384990885294
        hybriddataDict[75] = 0.0232970932956804
        hybriddataDict[80] = 0.0238095236732426
        hybriddataDict[85] = 0.0243817483582131
        
        //MARH: semi-data dict
        
        semidataDict[7] = 0.337837837837838
        semidataDict[15] = 0.259067357512953
        semidataDict[19] = 0.187617260787992
        semidataDict[33] = 0.144300144300144
        semidataDict[48.4] = 0.132978723404255
        semidataDict[55] = 0.0904159132007233
        semidataDict[60] = 0.125
        
        //semi-truck
        

        /*
         * Something!
        */
        
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
                            self.returnedRoute = (dictionary["routes"] as! Array<Dictionary<NSObject, AnyObject>>)
                            
                            for item in self.returnedRoute {
                                print("ROUTE:\(self.displayRoute)")
                                self.overviewPolyline = item["overview_polyline"] as! Dictionary<NSObject, AnyObject>
                                //print(item)
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
    
    func nextHighestSemi(n: Double) -> Double? {
        let higher:Array<Double> = semidataDict.keys.filter{$0 >= n}
        let k = higher.isEmpty ? 0.125 : semidataDict[higher.minElement()!]
        return k
    }
    
    func nextHighestHybrid(n: Double) -> Double? {
        let higher1:Array<Double> = hybriddataDict.keys.filter{$0 >= n}
        let k1 = higher1.isEmpty ? nil : hybriddataDict[higher1.minElement()!]
        return k1
    }
    
    func clearMarkers(){
        fuelMarker = nil
        speedMarker = nil
        originMarker = nil
        destinationMarker = nil
        mapView1.selectedMarker = nil
    }
    
    //MARK: calculate fuel for each leg in route
    func calFuel(dum:Array<Dictionary<NSObject, AnyObject>>) -> Double{
        let steps = dum as NSArray
        let noOFSteps = steps.count
        let mid = Int(noOFSteps/2)
        print(steps.count)
        print("MID\(mid)")
        let temp = steps[mid] as! Dictionary<NSObject,AnyObject>
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
            let speed:Double = distanceMiles / durationHours
            print("speed \(speed)")
            var minMiles:Double = 0.0
            var minMilesHy:Double = 0.0
            var minMilesSemi:Double = 0.0
            
            if(self.hybrid == true){
                minMilesHy = nextHighestHybrid(speed)!
            }
            else if(self.NOThybrid == true){
                minMiles = nextHighest(speed)!
            }
            else if(self.semi == true){
                print("in semi")
                minMilesSemi = nextHighestSemi(speed)!
            }
            distanceLeg += distanceMiles
            if(self.hybrid){
                fuelForLeg += minMilesHy*distanceMiles
            } else if(self.NOThybrid){
                fuelForLeg += minMiles*distanceMiles
            } else if(self.semi){
                fuelForLeg += minMilesSemi*distanceMiles
            }
        }
        print("GALLONS\(fuelForLeg)")
        return fuelForLeg
    }
    
    func calculateTotalDistanceAndDuration(dum:Dictionary<NSObject,AnyObject>) {
        let legs = dum["legs"]as! NSArray
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
        clearMarkers()
        
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
        let z = self.finalDict[Int(self.routeWithMinFuelNo)] as Dictionary<NSObject,AnyObject>
        let w = z["route"] as! Int
        let diff = w-y
        self.fasterBy = "This route is faster by"+String(diff/60)+"mins"
        print(self.fasterBy)
        
        //MARK:fuel calculations
        let fuel1 = self.routeDict[self.routeWithMinDuration] as Double!
        let fuel2 = self.routeDict[self.routeWithMinFuelNo] as Double!
        self.differenceFuel = fuel1-fuel2
        self.percentDiffFuel = (self.differenceFuel/fuel1)*100
        self.fuelSaved = self.differenceFuel*2.50
        if(self.semi){
           self.savingCO2 = self.differenceFuel*22.38
        } else {
             self.savingCO2 = self.differenceFuel*19.64
        }
        let a = String(format: "%.2f", self.differenceFuel)
        let b = String(format: "%.2f", self.fuelSaved)
        let c = String(format: "%.2f", self.savingCO2)
        
        self.finalDisplayString = "Diff in fuel:"+a+"gallons,\n $ Saved:"+b+"$,\n Reduction in CO2 emissions:"+c+"lbs"
        
        //MARK: displaying custom marker with calculations
        if(self.routeWithMinDuration != self.routeWithMinFuelNo){
            var customMarker = self.dicForCustomMarkers[Int(self.routeWithMinFuelNo)]
            let start_point = CLLocationCoordinate2DMake(customMarker["lat"] as! Double, customMarker["lng"] as! Double)
            fuelMarker = GMSMarker(position: start_point)
            fuelMarker.map = self.mapView1
            fuelMarker.icon = UIImage(named: "lemon.jpg")
            fuelMarker.snippet = self.finalDisplayString
            fuelMarker.title = "Fuel Efficient route!"
            mapView1.selectedMarker=fuelMarker
            
            //speed marker
            var speedMarker1 = self.dicForCustomMarkers[Int(self.routeWithMinDuration)]
            var start_point1 = CLLocationCoordinate2DMake(speedMarker1["lat"] as! Double, speedMarker1["lng"] as! Double)
            speedMarker = GMSMarker(position: start_point1)
            speedMarker.map = self.mapView1
            speedMarker.icon = UIImage(named: "fastcar1.jpg")
            speedMarker.snippet = "\(self.fasterBy)"
            speedMarker.title = "Faster Route!"
            
        } else {
            var speedMarker1 = self.dicForCustomMarkers[Int(self.routeWithMinFuelNo)]
            var start_point = CLLocationCoordinate2DMake(speedMarker1["lat"] as! Double, speedMarker1["lng"] as! Double)
            speedMarker = GMSMarker(position: start_point)
            speedMarker.map = self.mapView1
            speedMarker.icon = UIImage(named: "fastcar1.jpg")
            speedMarker.snippet = "Faster route is also the most fuel efficient route!"
            speedMarker.title = "Faster Route!"
            mapView1.selectedMarker=speedMarker
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
            let path2 = GMSPath(fromEncodedPath: greenRoute)!
            routePolyline = GMSPolyline(path: path2)
            routePolyline.strokeColor = UIColor.greenColor()
            routePolyline.strokeWidth = 5
            routePolyline.map = mapView1
        }
    }
    
}

//MARK: to enable places api
extension ViewController: GMSAutocompleteViewControllerDelegate{
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // 3
        if status == .AuthorizedWhenInUse {
            
            // 4
            locationManager.startUpdatingLocation()
            print("started updating location")
            //5
            mapView1.myLocationEnabled = true
            mapView1.settings.myLocationButton = true
        }
    }
    
    // 6
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let lat = manager.location!.coordinate.latitude
            let long = manager.location!.coordinate.longitude
            let offset = 200.0 / 1000.0;
            let latMax = lat + offset;
            let latMin = lat - offset;
            let lngOffset = offset * cos(lat * M_PI / 200.0);
            let lngMax = long + lngOffset;
            let lngMin = long - lngOffset;
            let initialLocation = CLLocationCoordinate2D(latitude: latMax, longitude: lngMax)
            let otherLocation = CLLocationCoordinate2D(latitude: latMin, longitude: lngMin)
            print(initialLocation)
            bounds = GMSCoordinateBounds(coordinate: initialLocation, coordinate: otherLocation)
            mapView1.camera = mapView1.cameraForBounds(bounds, insets: UIEdgeInsets())!
          //  mapView1.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds))
            // 7
//            mapView1.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            //mapView1.animateToLocation(initialLocation)
            
            // 8
            locationManager.stopUpdatingLocation()
        }
        
    }
    // Handle the user's selection.
    func viewController(_viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        print(error)
    }
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        //print("Place name: \(place.name)")
        //print("Place address: \(place.formattedAddress)")
        //print("Place attributions: \(place.attributions)")
        if self.sourceTap {
            dispatch_async(dispatch_get_main_queue()){
                print(place.formattedAddress)
                self.origin.text = place.formattedAddress! as String
            }
        }else{
            dispatch_async(dispatch_get_main_queue()){
                self.destination.text = place.formattedAddress! as String
            }
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func wasCancelled(_viewController: GMSAutocompleteViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // Show the network activity indicator.
    func didRequestAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        //UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // Hide the network activity indicator.
    func didUpdateAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    
    func sourceTap(sender: AnyObject) {
        self.sourceTap = true
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.autocompleteBounds = bounds
        autocompleteController.delegate = self
        // Set a filter to return only addresses.
        let addressFilter = GMSAutocompleteFilter()
        //addressFilter.type = .Address
        autocompleteController.autocompleteFilter = addressFilter
        presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    func destinationTap(sender: AnyObject) {
        self.sourceTap = false
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        autocompleteController.autocompleteBounds = bounds
        // Set a filter to return only addresses.
        let addressFilter = GMSAutocompleteFilter()
        autocompleteController.autocompleteFilter = addressFilter
        presentViewController(autocompleteController, animated: true, completion: nil)
        
        
    }
}

