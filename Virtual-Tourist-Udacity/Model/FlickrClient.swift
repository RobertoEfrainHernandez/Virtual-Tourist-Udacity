//
//  FlickrClient.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 2/2/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON

// MARK: -- Flickr Constants
/***************************************************************/

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    
    // MARK: -- Helper for Creating a URL from Parameters
    /***************************************************************/
    func flickrURLFromParameters(_ parameters: [String:String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    /* given a dictionary of parameters, covert unsafe ASCII characters and correctly formated url string. */
    func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    func bboxString(longitude:Double, latitude:Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        }
    
    // MARK: -- Networking
    /***************************************************************/
    func getImagesFromFlickr(_ selectedPin: Pin, _ page: Int, _ completionHandler: @escaping (_ result: [Photo]?, _ error: NSError?) -> Void) {
        /* Set Parameters */
        let methodParameters: [String:String] = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(longitude:selectedPin.longitude , latitude: selectedPin.latitude),
            Constants.FlickrParameterKeys.Latitude: "\(selectedPin.latitude)",
            Constants.FlickrParameterKeys.Longitude: "\(selectedPin.longitude)",
            Constants.FlickrParameterKeys.PerPage: "21",
            Constants.FlickrParameterKeys.Page: "\(page)",
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        /* Build the URL */
        let url = flickrURLFromParameters(methodParameters)
        
        Alamofire.request(url).validate(statusCode: 200..<300).responseJSON { (response) in
            if response.result.isSuccess {
                print("Success! Got the Images from Flickr!")
                let flickrJSON : JSON = JSON(response.result.value!)
                print(flickrJSON)
                let photosDict = flickrJSON["photos"]
                let photoArray = photosDict["photo"]
                
                performUIUpdatesOnMain {
                    let context = CoreDataStack.getContext()
                    
                    var imageUrlString = [Photo]()
                    
                    for url in photoArray {
                        let urlString = String(url[Constants.FlickrResponseKeys.MediumURL])
                        
                        let photo : Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context ) as! Photo
                        
                        photo.urlString = urlString
                        photo.pin = selectedPin
                        imageUrlString.append(photo)
                        CoreDataStack.saveContext()
                    }
                    completionHandler(imageUrlString, nil)
                }
            } else {
                print("Error: \(String(describing: response.result.error))")
            }
        }
    }
}
