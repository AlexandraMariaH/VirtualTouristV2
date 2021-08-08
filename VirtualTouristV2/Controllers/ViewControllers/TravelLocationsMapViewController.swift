//
//  TravelLocationsMapViewController.swift
//  VirtualTouristV2
//
//  Created by Alexandra Hufnagel on 11.07.21.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController! = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    /// Variables for saving the coordinates of the selected pin
    var latitude: Double?
    var longitude: Double?
    
    var pins: [Pin]?
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.addGestureRecognizer(longTapGesture)
        
        setupFetchedResultsController()
        
        showPinsOnMap()
    }
    
    @objc func longTap(gestureRecognizer: UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let locationInView = gestureRecognizer.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
        }
    }
    
    func addAnnotation(location: CLLocationCoordinate2D){
        addAnnotationToMapView(location)
        
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = location.longitude
        pin.latitude = location.latitude
        
        try? dataController.viewContext.save()
    }
    
    func showPinsOnMap(){
        fetchPinFromDataController()
        
        for pin in self.pins! {
                let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                addAnnotationToMapView(coordinate)
        }
    }
    
    fileprivate func addAnnotationToMapView(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect mkAnnotationView: MKAnnotationView) {
        
        latitude = mkAnnotationView.annotation?.coordinate.latitude
        longitude = mkAnnotationView.annotation?.coordinate.longitude
        
        fetchPinFromDataController()
        
        self.performSegue(withIdentifier: "tapPin", sender: nil)
    }
    
    fileprivate func fetchPinFromDataController() {
        do {
            pins = try dataController.viewContext.fetch(Pin.fetchRequest())
        } catch {
            print("fetching pin was not successfull")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        if let photoAlbumViewController = segue.destination as? PhotoAlbumViewController {
            for pin in pins! {
                if (pin.latitude == latitude && pin.longitude == longitude) {
                    if let indexPathOfTappedPin = pins?.firstIndex(of: pin){
                        
                        photoAlbumViewController.pin = pins?[indexPathOfTappedPin]
                        photoAlbumViewController.dataController = dataController
                    }
                    
                }
            }
        }
    }
    
}
