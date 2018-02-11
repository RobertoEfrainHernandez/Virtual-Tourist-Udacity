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
        
        flickrCollectionView.register(PhotoAlbumCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        addAnnotation()
        print("Selected pin location: \(selectedPin)")
        
        fetchPhotos()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.flickrCollectionView.reloadData()
        self.flickrCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    func getFlickrPhotos(page: Int){
        
        FlickrClient.sharedInstance.getImagesFromFlickr(selectedPin, currentPage) { (results, error) in
            
            guard error == nil else {
                self.displayAlert(title: "Unable to get photos from Flickr", message: error?.localizedDescription)
                return
            }
            /* Add results to photoData and reload flickrCollectionView */
            performUIUpdatesOnMain {
                if results != nil {
                    self.photoData = results!
                    
                    print("\(self.photoData.count) photos from Flickr fetched")
                    self.flickrCollectionView.reloadData()
                }
            }
        }
    }
    
    func removePhotos() {
        
        if selectedIndexPaths.count > 0 {
            for indexPath in selectedIndexPaths {
                let photo = photoData[indexPath.row]
                CoreDataStack.getContext().delete(photo)
                self.photoData.remove(at: indexPath.row)
                self.flickrCollectionView.deleteItems(at: [indexPath as IndexPath])
                print("Photo at row \(indexPath.row) was deleted")
            }
            CoreDataStack.saveContext()
        }
        selectedIndexPaths = [NSIndexPath]()
    }
    
    @IBAction func newCollectionTapped(_ sender: UIButton) {
        if photosSelected {
            removePhotos()
            self.flickrCollectionView.reloadData()
            photosSelected = false
            newCollectionButton.setTitle("New Collection", for: .normal)
        } else {
            for photo in photoData {
                CoreDataStack.getContext().delete(photo)
            }
            CoreDataStack.saveContext()
            currentPage += 1
            getFlickrPhotos(page: currentPage)
            
        }
    }
    
}

// MARK: -- MapView Delegate Methods
/***************************************************************/
extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func addAnnotation() {
        let annotation = MKPointAnnotation()
        let lat = CLLocationDegrees(selectedPin.latitude)
        let lon = CLLocationDegrees(selectedPin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        
        //zoom into an appropriate region
        let span = MKCoordinateSpanMake(0.25, 0.25)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        performUIUpdatesOnMain {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: -- Fetch Results Delegate Methods
/***************************************************************/
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func fetchPhotos(){
       
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", selectedPin!)
        let context = CoreDataStack.getContext()
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        if let data = fetchedResultsController.fetchedObjects, data.count > 0 {
            print("\(data.count) photos from core data fetched.")
            photoData = data
            self.flickrCollectionView.reloadData()
        } else {
            getFlickrPhotos(page: currentPage)
        }
    }
}

// MARK: -- CollectionView Data Source Methods
/***************************************************************/
extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let flickrCell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let photo = photoData[indexPath.row]
        
        flickrCell.flickrImage.image = UIImage(named: "placeholder")
        flickrCell.activityIndicator.startAnimating()
        
        if photo.imageData != nil {
            performUIUpdatesOnMain {
                flickrCell.activityIndicator.stopAnimating()
            }
            flickrCell.flickrImage.image = UIImage(data: photo.imageData! as Data)
        } else {
            
            FlickrClient.sharedInstance.getDataFromUrl(photo.urlString!) { (results, error) in
                guard let imageData = results else {
                    self.displayAlert(title: "Image data error", message: error)
                    return
                }
                
                performUIUpdatesOnMain {
                    photo.imageData = imageData as NSData?
                    flickrCell.activityIndicator.stopAnimating()
                    flickrCell.flickrImage.image = UIImage(data: photo.imageData! as Data)
                }
            }
        }
        
        if selectedIndexPaths.index(of: indexPath as NSIndexPath) != nil {
            flickrCell.flickrImage.alpha = 0.25
        } else {
            flickrCell.flickrImage.alpha = 1.0
        }
        
        if let layout = collectionView.collectionViewLayout as? CollectionViewSlantedLayout {
            flickrCell.contentView.transform = CGAffineTransform(rotationAngle: layout.slantingAngle)
        }
    
        return flickrCell
    }
}

// MARK: -- CollectionView Slanted Layout Delegate Methods
/***************************************************************/
extension PhotoAlbumViewController: CollectionViewDelegateSlantedLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //NSLog("Did select item at indexPath: [\(indexPath.section)][\(indexPath.row)]")
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCollectionViewCell
        
        let index = selectedIndexPaths.index(of: indexPath as NSIndexPath)
        
        if let index = index {
            selectedIndexPaths.remove(at: index)
            cell.flickrImage.alpha = 1.0
        } else {
            selectedIndexPaths.append(indexPath as NSIndexPath)
            print(selectedIndexPaths)
            selectedIndexPaths.sort{$1.row < $0.row}
            print("Selected IndexPaths: \(selectedIndexPaths)")
            
            cell.flickrImage.alpha = 0.25
        }
        
        if selectedIndexPaths.count > 0 {
            newCollectionButton.setTitle("Delete", for: .normal)
            photosSelected = true
            
        } else {
            newCollectionButton.setTitle("New Collection", for: .normal)
            photosSelected = false
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: CollectionViewSlantedLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGFloat {
        return collectionViewLayout.scrollDirection == .vertical ? 180 : 325
    }
}

// MARK: -- Scroll View Delegate Extention
/***************************************************************/
extension PhotoAlbumViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = self.flickrCollectionView else {return}
        guard let visibleCells = collectionView.visibleCells as? [PhotoAlbumCollectionViewCell] else {return}
        for parallaxCell in visibleCells {
            let yOffset = ((collectionView.contentOffset.y - parallaxCell.frame.origin.y) / parallaxCell.imageHeight) * yOffsetSpeed
            let xOffset = ((collectionView.contentOffset.x - parallaxCell.frame.origin.x) / parallaxCell.imageWidth) * xOffsetSpeed
            parallaxCell.offset(CGPoint(x: xOffset,y :yOffset))
        }
    }
}
