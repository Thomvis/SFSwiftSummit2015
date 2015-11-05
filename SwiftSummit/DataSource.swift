//
//  DataSource.swift
//  SwiftSummit
//
//  Created by Thomas Visser on 03/10/15.
//  Copyright © 2015 Thomas Visser. All rights reserved.
//

import Foundation
import UIKit
import Result

struct Bird {
    let name: String
    let description: String
    let imagePath: String
    
    init(name: String, description: String, imagePath: String) {
        self.name = name
        self.description = description
        self.imagePath = imagePath
    }
}

enum BirdsError: ErrorType {
    case LegacyError(NSError?)
    case JsonParseError
    case ImageDecodingError
    case OtherError
}

class DataSource {
    let session = FakeNSURLSession()
}


extension DataSource {
    
    func getBirds(completionHandler: [(Bird, UIImage)] -> Void) {
        let task = session.dataTaskWithURL(NSURL(string: "http://developer.apple.com/new-language/naming.json")!) { (data, response, error) -> Void in
            if let data = data, json = self.birdsJsonFromResponseData(data) {
                var result: [(Bird, UIImage)] = []
                for (index, bird) in json.enumerate() {
                    if let bird = self.parseBird(bird) {
                        self.getImage(bird) { image in
                            result.insert((bird, image), atIndex: min(result.count, index))
                            
                            if result.count == json.count {
                                dispatch_async(dispatch_get_main_queue()) {
                                    completionHandler(result)
                                }
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    func birdsJsonFromResponseData(data: NSData) -> [[String:AnyObject]]? {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
            if let json = json as? [[String:AnyObject]] {
                return json
            }
        } catch _ { }
        
        return nil
    }
    
    func parseBird(json: [String:AnyObject]) -> Bird? {
        if let name = json["name"] as? String,
            let description = json["description"] as? String,
            let imagePath = json["image"] as? String {
                return Bird(name: name, description: description, imagePath: imagePath)
        }
        
        return nil
    }
    
    private func getImage(bird: Bird, completionHander: UIImage -> Void) {
        let task = session.dataTaskWithURL(NSURL(string: bird.imagePath)!) { (data, response, error) -> Void in
            if let data = data {
                let image = UIImage(data: data)
                if let image = image {
                    completionHander(image)
                }
            }
        }
        
        task.resume()
    }
    
}

















