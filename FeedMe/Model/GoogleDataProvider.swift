//
//  GoogleDataProvider.swift
//  FeedMe
//
//  Created by Olya Tilichenko on 28.02.2018.
//  Copyright © 2018 Olya Tilichenko. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import SwiftyJSON
import GoogleMaps

typealias PlacesCompletion = ([GooglePlace]) -> Void
//typealias PhotoCompletion = (String?) -> Void

class GoogleDataProvider {
    private var urlCache: [String: String] = [:]
    private var placesTask: URLSessionDataTask?
    private var session: URLSession {
        return URLSession.shared
    }
    
    func fetchPlacesNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, types: [String], completion: @escaping PlacesCompletion) -> Void {
        var urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate.latitude),\(coordinate.longitude)&radius=\(radius)&rankby=prominence&sensor=true&opennow&key=\(googleApiKey)"
        let typesString = types.count > 0 ? types.joined(separator: "|") : "bakery"  
        
        urlString += "&types=\(typesString)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? urlString
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        if let task = placesTask, task.taskIdentifier > 0 && task.state == .running {
            task.cancel()
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        placesTask = session.dataTask(with: url) { data, response, error in
            var placesArray: [GooglePlace] = []
            defer {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    completion(placesArray)
                }
            }
            guard let data = data,
                let json = try? JSON(data: data, options: .mutableContainers),
                let results = json["results"].arrayObject as? [[String: Any]] else {
                    return
            }
            results.forEach {
                let place = GooglePlace(dictionary: $0, acceptedTypes: types)
                placesArray.append(place)
            }
        }
        placesTask?.resume()
    }
    
    
    /*func fetchUrlFromReference(_ reference: String, completion: @escaping PhotoCompletion) -> Void {
        if let urlPl = urlCache[reference] {
            completion(urlPl)
        } else {
            let urlString = "https://maps.googleapis.com/maps/api/place/url?&urlreference=\(reference)&key=\(googleApiKey)"
            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            session.downloadTask(with: url) { url, response, error in
                var downloadedPhoto: String? = nil
                defer {
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        completion(downloadedPhoto)
                    }
                }
                guard let url = url else {
                    return
                }
                guard let urlData = try? Data(contentsOf: url) else {
                    return
                }
                downloadedPhoto = URL(data: urlData)
                self.photoCache[reference] = downloadedPhoto
                }
                .resume()
        }
    }*/
}

