//
//  PhotoAlbumViewController.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 2/6/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CollectionViewSlantedLayout
import ChameleonFramework

// MARK: -- Photo Album View Controller
/***************************************************************/

private let reuseIdentifier = "PhotoAlbumCell"

class PhotoAlbumViewController: UIViewController {
    
    /* Outlets */
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flickrCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewLayout: CollectionViewSlantedLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    /* Properties */
    private let persistanContainter = NSPersistentContainer(name: "Photo")
    var selectedPin : Pin!
    var photoData : [Photo] = [Photo]()
    var selectedIndexPaths = [NSIndexPath]()
    var photosSelected = false
    var currentPage = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /* Set Collection Button Color */
        newCollectionButton.backgroundColor = FlatTeal()
        let contrastColor = ContrastColorOf(newCollectionButton.backgroundColor!, returnFlat: true)
        newCollectionButton.setTitleColor(contrastColor, for: .normal)
        
        /* Make First and Last cell not slanted when the view loads */
        collectionViewLayout.isFirstCellExcluded = true
        collectionViewLayout.isLastCellExcluded = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: -- MapView Delegate Methods
/***************************************************************/
extension PhotoAlbumViewController: MKMapViewDelegate {
    
}

// MARK: -- Fetch Results Delegate Methods
/***************************************************************/
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
}

// MARK: -- CollectionView Data Source Methods
/***************************************************************/
extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let flickrCell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        return flickrCell
    }
}

// MARK: -- CollectionView Slanted Layout Delegate Methods
/***************************************************************/
extension PhotoAlbumViewController: CollectionViewDelegateSlantedLayout {
    
}

// MARK: -- UIImageView Extention
/***************************************************************/
extension UIImageView {
    
}
