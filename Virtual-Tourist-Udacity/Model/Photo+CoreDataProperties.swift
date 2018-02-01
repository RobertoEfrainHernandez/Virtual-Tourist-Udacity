//
//  Photo+CoreDataProperties.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 2/1/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var urlString: String?
    @NSManaged public var pin: Pin?

}
