//
//import UIKit
//import GoogleMaps
//import Foundation
//
//class Helper: NSObject{
//    
//    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
//    
//    var lookupAddressResults: Dictionary<NSString, AnyObject>!
//    
//    var fetchedFormattedAddress: String!
//    
//    var fetchedAddressLongitude: Double!
//    
//    var fetchedAddressLatitude: Double!
//    
//    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
//    
//    
//    override init() {
//        super.init()
//    }
//    
//    func geocodeAddress(_ address: String!, withCompletionHandler completionHandler:(status:String,success:Bool)->Void) {
//        if let lookupAddress = address {
//            var geocodeURLString = baseURLGeocode + "address=" + lookupAddress
//            geocodeURLString = geocodeURLString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
//            
//            let geocodeURL = NSURL(string: geocodeURLString)
//                       dispatch_async(dispatch_get_main_queue(),{ () -> Void in
//                            print("start dispatching")
//      
//                            do {
//                                let geocodingResultsData = NSData(contentsOfURL: geocodeURL!)
//                                var error: NSError?
//                                if let dictionary = try NSJSONSerialization.JSONObjectWithData(geocodingResultsData!, options: .MutableContainers) as? Dictionary<NSObject,AnyObject> {
//                                    if(error != nil){
//                                        print(error)
//                                        completionHandler(status: "", success: false)
//                                    } else {
//                                        let status = dictionary["status"] as! String
//                                        if status == "OK" {
//                                            let allResults = dictionary["results"] as! Array<Dictionary<NSString, AnyObject>>
//                                            self.lookupAddressResults = allResults[0]
//                                            
//                                            // Keep the most important values.
//                                            self.fetchedFormattedAddress = self.lookupAddressResults["formatted_address"] as! String
//                                            let geometry = self.lookupAddressResults["geometry"] as! Dictionary<NSString, AnyObject>
//                                            self.fetchedAddressLongitude = ((geometry["location"] as! Dictionary<NSString, AnyObject>)["lng"] as! NSNumber).doubleValue
//                                            self.fetchedAddressLatitude = ((geometry["location"] as! Dictionary<NSString, AnyObject>)["lat"] as! NSNumber).doubleValue
//                                            
//                                            completionHandler(status: status, success: true)
//                                        } else {
//                                            completionHandler(status: status, success: false)
//                                        }
//                                }
//                                
//                            }
//                            }catch {
//                                print(error)
//                                completionHandler(status: "", success: false)
//                            }
//                        })
//            
//                
//        }
//    }
//    
//}