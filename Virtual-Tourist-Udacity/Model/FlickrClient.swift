//
//  FlickrClient.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 2/2/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import Foundation
import CoreData


// MARK: -- Flickr Constants
/***************************************************************/

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    var session = URLSession.shared
    
    // MARK: -- Helper for Creating a URL from Parameters
    /***************************************************************/
    func getImagesFromFlickr(_ selectedPin: Pin, _ page: Int, _ completionHandler: @escaping (_ result: [Photo]?, _ error: NSError?) -> Void) {
        
        /*Set the parameters from FlickrConstants */
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
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        /* Create the request */
        let task = taskForGETMethod(request: request) { (parsedResult, error) in
            
            /* Display Error */
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult?[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            performUIUpdatesOnMain {
                
                let context = CoreDataStack.getContext()
               
                var imageUrlStrings = [Photo]()
                
                for url in photosArray {
                    guard let urlString = url[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photosArray)")
                        return
                    }
                    let photo:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context ) as! Photo
                    
                    photo.urlString = urlString
                    photo.pin = selectedPin
                    imageUrlStrings.append(photo)
                    CoreDataStack.saveContext()
                    
                }
                completionHandler(imageUrlStrings, nil)
            }
            
        }
        
        task.resume()
    }
    
    // MARK: GETMethod
    private func taskForGETMethod(request: URLRequest, _ completionHandlerForGET: @escaping(_ result: AnyObject?, _ error: NSError?) -> Void)-> URLSessionDataTask {
        /* Create the request */
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* Display Error */
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        task.resume()
        return task
    }
    
    func getDataFromUrl(_ urlString: String, _ completionHandler: @escaping (_ imageData: Data?, _ error: String?) -> Void) {
        
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completionHandler(nil, error?.localizedDescription)
                return
            }
            completionHandler(data, nil)
        }
        task.resume()
    }
    
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
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    func bboxString(longitude:Double, latitude:Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
