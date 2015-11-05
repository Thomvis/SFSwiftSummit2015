//
//  ViewController.swift
//  SwiftSummit
//
//  Created by Thomas Visser on 30/09/15.
//  Copyright © 2015 Thomas Visser. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    let dataSource = DataSource()
    var birds: [(Bird, UIImage)]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Birds"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        dataSource.getBirds { [weak self] birds in
            self?.birds = birds
            self?.tableView.reloadData()
        }
    }
    
}

extension ViewController {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assert(section == 0)
        
        return birds.map { $0.count } ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let birds = birds where indexPath.item < birds.count else {
            fatalError()
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.detailTextLabel?.numberOfLines = 0
        
        let (bird, image) = birds[indexPath.item]
        cell.updateWithBird(bird, image: image)
        
        return cell
    }
    
}

extension UITableViewCell {
    func updateWithBird(bird: Bird, image: UIImage) {
        self.textLabel?.text = bird.name
        self.detailTextLabel?.text = bird.description
        self.imageView?.image = image
    }
}
