//
//  FakeUrlSession.swift
//  SwiftSummit
//
//  Created by Thomas Visser on 05/11/15.
//  Copyright © 2015 Thomas Visser. All rights reserved.
//

import Foundation
import UIKit

// This file contains all the behind-the-scenes logic that makes the demo work,
// without internet, without actually reading json & images from Apple servers.
// 
// It could get ugly.

class FakeNSURLSession {
    
    func dataTaskWithURL(url: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> FakeNSURLSessionDataTask {
        
        return FakeNSURLSessionDataTask(url: url, completionHandler: completionHandler)
    }
    
}

class FakeNSURLSessionDataTask {
    
    let url: NSURL
    let completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void
    
    init(url: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        self.url = url
        self.completionHandler = completionHandler
    }
    
    func resume() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let data: NSData
            let response = NSURLResponse()
            
            if (self.url.pathExtension == "json") {
                data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("naming", ofType: "json")!)!
            } else {
                data = UIImageJPEGRepresentation(UIImage(named: self.url.lastPathComponent!)!, 1.0)!
            }
            
            self.completionHandler(data, response, nil)
        }
    }
}