//
//  PhotoAlbumCollectionViewCell.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 2/6/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import UIKit
import Foundation
import CollectionViewSlantedLayout

let yOffsetSpeed: CGFloat = 150.0
let xOffsetSpeed: CGFloat = 100.0

// MARK: -- Flickr Photo Album Cell
/***************************************************************/

class PhotoAlbumCollectionViewCell: CollectionViewSlantedCell {
    
    /* Outlets */
    @IBOutlet weak var flickrImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    /* Properties */
    private var gradient = CAGradientLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let backgroundView = backgroundView {
            gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
            gradient.locations = [0.0, 1.0]
            gradient.frame = backgroundView.bounds
            backgroundView.layer.addSublayer(gradient)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let backgroundView = backgroundView {
            gradient.frame = backgroundView.bounds
        }
    }
    
    var image: UIImage = UIImage() {
        didSet {
            flickrImage.image = image
        }
    }
    
    var imageHeight: CGFloat {
        return (flickrImage?.image?.size.height) ?? 0.0
    }
    
    var imageWidth: CGFloat {
        return (flickrImage?.image?.size.width) ?? 0.0
    }
    
    
    func offset(_ offset: CGPoint) {
        flickrImage.frame = self.flickrImage.bounds.offsetBy(dx: offset.x, dy: offset.y)
    }
}
