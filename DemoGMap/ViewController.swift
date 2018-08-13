//
//  ViewController.swift
//  DemoGMap
//
//  Created by Đừng xóa on 8/10/18.
//  Copyright © 2018 Đừng xóa. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController {
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var pinImageVerticalConstraint: NSLayoutConstraint!
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
        
//        let camera = GMSCameraPosition.camera(withLatitude: 21, longitude: 105.9, zoom: 6.0)
//        mapView.camera = camera
//        showMaker(position: camera.target)
    }
    
//    func showMaker(position: CLLocationCoordinate2D) {
//        let maker = GMSMarker()
//        maker.position = position
//        maker.title = "Ha Noi"
//        maker.snippet = "Viet Nam"
//        maker.map = mapView
//    }
    
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        //Creates a GMSGeocoder object to turn a latitude and longitude coordinate into a street address.
        let geocoder = GMSGeocoder()
        
        //reverse geocode the coordinate passed to the method.
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            //verifies there is an address in the response of type GMSAddress
            guard let address = response?.firstResult(), let line = address.lines else {return}
            
            self.addressLabel.text = line.joined(separator: "\n")
            
            //adds padding to the top and bottom of the map.
            let labelHeight = self.addressLabel.intrinsicContentSize.height
            self.mapView.padding = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0, bottom: labelHeight, right: 0)
            //animate the changes
            UIView.animate(withDuration: 0.25) {
                self.pinImageVerticalConstraint.constant = ((labelHeight - self.view.safeAreaInsets.top) * 0.5)
                self.view.layoutIfNeeded()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


    // a extension that conforms to CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    // called when the user grants or revokes location permissions.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //verify the if user has granted permission while the app is in use.
        guard status == .authorizedWhenInUse else {return}
        
        //if permissions have been established, ask the location manager for updates on the user’s location.
        locationManager.startUpdatingLocation()
        
        //draws a light blue dot where the user is located
        mapView.isMyLocationEnabled = true
        //adds a button, when tapped centers the map on the user’s location.
        mapView.settings.myLocationButton = true
    }
    
    //when the location manager receives new location data.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {return}
        
        //updates the map’s camera to center around the user’s current location.
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        let locValueL: CLLocationCoordinate2D = (manager.location?.coordinate)!
        print("locations: \(locValueL.latitude), \(locValueL.longitude)")
        locationManager.stopUpdatingLocation()
    }
}


extension ViewController: GMSMapViewDelegate {
    //Called each time the map stops moving and settles in a new position
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress ?? "")")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

//extension ViewController: GMSMapViewDelegate {
//    /* handles Info Window tap */
//    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
//        //detects when the user taps on the InfoWindow.
//        print("didTapInfoWindowOf")
//    }
//
//    /* handles Info Window long press */
//    func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
//        //detects when the InfoWindow has been long pressed.
//        print("didLongPressInfoWindowOf")
//    }
//
//    /* set a custom Info Window */
//    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
//        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 70))
//        view.backgroundColor = UIColor.white
//        view.layer.cornerRadius = 6
//
//        let lbl1 = UILabel(frame: CGRect.init(x: 8, y: 8, width: view.frame.size.width - 16, height: 15))
//        lbl1.text = "Hi there!"
//        view.addSubview(lbl1)
//
//        let lbl2 = UILabel(frame: CGRect.init(x: lbl1.frame.origin.x, y: lbl1.frame.origin.y + lbl1.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
//        lbl2.text = "I am a custom info window."
//        lbl2.font = UIFont.systemFont(ofSize: 14, weight: .light)
//        view.addSubview(lbl2)
//
//        return view
//    }
//}
