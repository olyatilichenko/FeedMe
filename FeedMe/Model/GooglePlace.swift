//
//  GooglePlace.swift
//  FeedMe
//
//  Created by Olya Tilichenko on 28.02.2018.
//  Copyright © 2018 Olya Tilichenko. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import SwiftyJSON

class GooglePlace {
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let placeType: String
    var urlPlace: String
    
    init(dictionary: [String: Any], acceptedTypes: [String])
    {
        let json = JSON(dictionary)
        name = json["name"].stringValue
        address = json["vicinity"].stringValue
        urlPlace = json["url"].stringValue
        
        let lat = json["geometry"]["location"]["lat"].doubleValue as CLLocationDegrees
        let lng = json["geometry"]["location"]["lng"].doubleValue as CLLocationDegrees
        coordinate = CLLocationCoordinate2DMake(lat, lng)
        
        
        var foundType = "restaurant"
        let possibleTypes = acceptedTypes.count > 0 ? acceptedTypes : ["bakery", "cafe", "restaurant"]
        
        if let types = json["types"].arrayObject as? [String] {
            for type in types {
                if possibleTypes.contains(type) {
                    foundType = type
                    break
                }
            }
        }
        placeType = foundType
    }
}

