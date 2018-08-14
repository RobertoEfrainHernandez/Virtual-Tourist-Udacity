//
//  TouristMapViewController.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 1/31/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import Spring
import ChameleonFramework

// MARK:- Tourist Map View Controller
/***************************************************************/

class TouristMapViewController: UIViewController {
    
    /* Outlets */
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    /* Properties */
    var editLabelVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editLabel.isHidden = true
        editLabel.backgroundColor = FlatTeal()
        editLabel.textColor = ContrastColorOf(editLabel.backgroundColor!, returnFlat: true)
        
        /* Initialize Long Press Gesture Recognizer */
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        
        longPress.minimumPressDuration = 0.6
        mapView.addGestureRecognizer(longPress)
        loadAnnotations()
    }

    
    @IBAction func editPressed(_ sender: Any) {
        editLabelVisible = !editLabelVisible
        
        if editLabelVisible {
            editButton.title = "Done"
            mapView.frame.origin.y -= 50
            editLabel.isHidden = false
            
        } else {
            editButton.title = "Edit"
            mapView.frame.origin.y = 0
            editLabel.isHidden = true
            
        }
    }
    
    @objc func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        /* Add Pin when the Long Press Gesture state has began */
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            
            let location = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(location, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            addedPinSaved(lat: newCoordinates.latitude, lon: newCoordinates.longitude)
            
            performUIUpdatesOnMain {
                self.loadAnnotations()
            }
        }
    }
    
    func addedPinSaved(lat: Double, lon: Double) {
        let context = CoreDataStack.getContext()
        let pin : Pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: context) as! Pin
        
        pin.latitude = lat
        pin.longitude = lon
        
        CoreDataStack.saveContext()
    }
    

    // MARK:- Navigation
    /***************************************************************/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPhotoAlbumVC" {
            let controller = segue.destination as! PhotoAlbumViewController
            let selectedPin = sender as! Pin
            controller.selectedPin = selectedPin
        }
    }
}

// MARK:- Map View Delegate Methods
/***************************************************************/
extension TouristMapViewController: MKMapViewDelegate {
    
    func loadAnnotations() {
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            print("There are \(searchResults.count) locations")
            var annotations = [MKPointAnnotation]()
            for result in searchResults as [Pin] {
                
                let lat = CLLocationDegrees(result.latitude)
                let long = CLLocationDegrees(result.longitude)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
                
            }
            performUIUpdatesOnMain {
                self.mapView.addAnnotations(annotations)
                print("Annotations added to the map view.")
            }
        }
        catch {
            print("Error fetching annotations: \(error)")
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation?.coordinate.longitude
        print("The selected pin's lat:\(String(describing: lat)), lon:\(String(describing: lon))")
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            for pin in searchResults as [Pin] {
                if pin.latitude == lat!, pin.longitude == lon! {
                    let selectedPin = pin
                    print("Found pin info.")
                    if editLabelVisible {
                        /* Delete selectedPin from CoreData */
                        performUIUpdatesOnMain {
                            
                            CoreDataStack.getContext().delete(selectedPin)
                            CoreDataStack.saveContext()
                            self.mapView.removeAnnotation(view.annotation!)
                            print("Deleted the selected pin.")
                            
                        }
                    } else {
                        /* Segue to Photo Album VC */
                        print("Perform segue to the photo album.")
                        performUIUpdatesOnMain {
                            self.performSegue(withIdentifier: "ShowPhotoAlbumVC", sender: selectedPin)
                        }
                    }
                }
            }
        }catch {
            print("Error: \(error)")
        }
    }
}
