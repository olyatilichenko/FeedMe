//
//  ViewController.swift
//  FeedMe
//
//  Created by Olya Tilichenko on 28.02.2018.
//  Copyright © 2018 Olya Tilichenko. All rights reserved.
//

import UIKit
import GoogleMaps
import SafariServices

class ViewController: UIViewController {

    @IBOutlet private weak var mapCenterPinImage: UIImageView!
    @IBOutlet private weak var pinImageVerticalConstraint: NSLayoutConstraint!
    var searchedTypes = ["bakery", "cafe", "restaurant"]
    
    @IBOutlet weak var mapView: GMSMapView!
    
    private let locationManager = CLLocationManager()
    private let dataProvider = GoogleDataProvider()
    private let searchRadius: Double = 1000
    
    @IBOutlet weak var addressLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController,
            let controller = navigationController.topViewController as? TypesTableViewController else {
                return
        }
        controller.selectedTypes = searchedTypes
        controller.delegate = self
    }
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            
            self.addressLabel.unlock()
            
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            
            self.addressLabel.text = lines.joined(separator: "\n")
            
            let labelHeight = self.addressLabel.intrinsicContentSize.height
            self.mapView.padding = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0,
                                                bottom: labelHeight, right: 0)
            
            UIView.animate(withDuration: 0.25) {
                self.pinImageVerticalConstraint.constant = ((labelHeight - self.view.safeAreaInsets.top) * 0.5)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {

        mapView.clear()

        dataProvider.fetchPlacesNearCoordinate(coordinate, radius:searchRadius, types: searchedTypes) { places in
            places.forEach {

                let marker = PlaceMarker(place: $0)

                marker.map = self.mapView
            }
        }
    }
    
    @IBAction func refreshPlaces(_ sender: Any) {
        fetchNearbyPlaces(coordinate: mapView.camera.target)
    }
    
}

// MARK: - TypesTableViewControllerDelegate

extension ViewController: TypesTableViewControllerDelegate {
    func typesController(_ controller: TypesTableViewController, didSelectTypes types: [String]) {
        searchedTypes = controller.selectedTypes.sorted()
        dismiss(animated: true)
        fetchNearbyPlaces(coordinate: mapView.camera.target)
    }
}

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        guard status == .authorizedWhenInUse else {
            return
        }

        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)

        locationManager.stopUpdatingLocation()
        fetchNearbyPlaces(coordinate: location.coordinate)
    }
}

// MARK: - GMSMapViewDelegate

extension ViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        addressLabel.lock()
        if (gesture) {
            mapCenterPinImage.fadeIn(0.25)
            mapView.selectedMarker = nil
        }
    }

    
    /*func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        guard let placeMarker = marker as? PlaceMarker else {
            return false
        }
        
        let urlPlace = URL(string: placeMarker.place.urlPlace)
        let vc = SFSafariViewController(url: urlPlace!)
        present(vc, animated: true, completion: nil)
        mapCenterPinImage.fadeOut(0.25)
        return false
    }*/
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        mapCenterPinImage.fadeIn(0.25)
        mapView.selectedMarker = nil
        return false
    }
}
