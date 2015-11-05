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

extension FakeNSURLSession {
    func fetch(url: String) -> Async<Result<(NSData, NSURLResponse), BirdsError>> {
        return Async { completion in
            let task = self.dataTaskWithURL(NSURL(string: url)!, completionHandler: { (data, response, error) -> Void in
                if let data = data, response = response {
                    completion(Result(value: (data, response)))
                } else {
                    completion(Result(error: .LegacyError(error)))
                }
            })
            task.resume()
        }
    }
}


extension DataSource {
    
    func getBirds() -> Future<[(Bird, UIImage)], BirdsError> {
        return session.fetch("http://developer.apple.com/new-language/naming.json").flatMap { data, response in
            return self.birdsJsonFromResponseData(data)
        }.map { json in
            return json.flatMap(self.parseBird)
        }.flatMap { birds in
            return birds.map(self.getImage).sequence()
        }
    }
    
    func birdsJsonFromResponseData(data: NSData) -> Result<[[String:AnyObject]], BirdsError> {
        return materialize {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
            
            guard let res = json as? [[String:AnyObject]] else {
                throw BirdsError.JsonParseError
            }
            
            return res;
            }.analysis(ifSuccess: { Result(value: $0) }, ifFailure: { Result(error: .LegacyError($0)) });
    }
    
    func parseBird(json: [String:AnyObject]) -> Bird? {
        if let name = json["name"] as? String,
            let description = json["description"] as? String,
            let imagePath = json["image"] as? String {
                return Bird(name: name, description: description, imagePath: imagePath)
        }
        
        return nil
    }
    
    private func getImage(bird: Bird) -> Future<(Bird, UIImage), BirdsError> {
        return session.fetch(bird.imagePath).flatMap { data, response -> Result<(Bird, UIImage), BirdsError> in
            let image = UIImage(data: data)
            if let image = image {
                return Result(value: (bird, image))
            }
            return Result(error: .ImageDecodingError)
        }
    }
    
}

















