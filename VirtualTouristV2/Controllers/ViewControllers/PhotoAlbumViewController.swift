//
//  PhotoAlbumViewController.swift
//  VirtualTouristV2
//
//  Created by Alexandra Hufnagel on 11.07.21.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: Outlets
    /// A map view that displays a map of pins
    @IBOutlet weak var photoMapView: MKMapView!
    /// A collection view that displays a collection of photos for a pin
    @IBOutlet weak var collectionView: UICollectionView!
    /// The layout for the collection view
    @IBOutlet weak var photoFlowLayout: UICollectionViewFlowLayout!
    /// A button that empties the photo album and fetches a new set of images
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // MARK: Variables
    /// The data controller is responsible for establishing a connection with data
    var dataController: DataController!
    /// The fetched results controller analysis the result of a fetched request
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    /// The pin whose photos are being displayed
    var pin: Pin!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "url", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: pin))-photos")
                
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0

        photoFlowLayout.minimumInteritemSpacing = space
        photoFlowLayout.minimumLineSpacing = space
        photoFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        if pin.photos?.count == 0 {
            downloadPictures(page: 1, completion: {
                self.collectionView.reloadData()
            })
        }
                
        setupFetchedResultsController()
        drawMap()
    }
    
    func drawMap() {
        var location = CLLocationCoordinate2D()
        location.longitude = pin.longitude
        location.latitude = pin.latitude
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        
        var annotations = [MKPointAnnotation]()
        annotations.append(annotation)
        
        photoMapView.addAnnotations(annotations)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
         
         let reuseId = "pin"
         var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
         
         if pinView == nil {
             pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
             pinView!.canShowCallout = true
         }
         else {
             pinView!.annotation = annotation
         }
         return pinView
     }
    
    func downloadPictures(page: Int, completion: @escaping () -> Void) {
        
        DispatchQueue.main.async {
            VTClient.downloadPhotos(latitude: self.pin.latitude, longitude: self.pin.longitude, perPage: 15, page: page) { data,error in
                
                if data?.total == 0 {
                    self.showAlert(message: "")
                }
                
                for photo in data!.photo {
                    let photoURL = VTClient.getPhotoURL(server: photo.server, id: photo.id, secret: photo.secret)
                    let photo = Photo(context: self.dataController.viewContext)
                    photo.url = photoURL
                    photo.pin = self.pin
                    
                    self.dataController.save()
                }
                self.setupFetchedResultsController()
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func showAlert(message: String) {
        let alertVC = UIAlertController(title: "No Images", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertVC, animated:true)
    }
    
    // MARK: Load new collection of photos
    @IBAction func newCollection(_ sender: Any) {
        newCollectionButton.isEnabled = false
        
        // Delete old collection
        if let objects = fetchedResultsController.fetchedObjects {
            for object in objects {
                dataController.viewContext.delete(object)
                try? dataController.viewContext.save()
            }
        }
        
        downloadPictures(page: 2, completion: {})
        newCollectionButton.isEnabled = true
    }

    // MARK: Items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects!.count
    }
    
    // MARK: Cell for item at index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        let photoObject = fetchedResultsController.object(at: indexPath)
                
        // Set the photo
        VTClient.taskForDownloadImage(url: URL(string: photoObject.url!)!) { data, error in
                    
            photoObject.photo = data
            photoObject.pin = self.pin
                    
            self.dataController.save()
            DispatchQueue.main.async {
                cell.photoAlbumImageView.image = UIImage(data: photoObject.photo!)
            }
        }
        return cell
    }
    
    // MARK: Delete Photo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        
        setupFetchedResultsController()
        
        collectionView.deleteItems(at: [indexPath])
    }

}
