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
typealias DICT = Dictionary<AnyHashable, Any>

class ViewController: UIViewController {
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var pinImageVerticalConstraint: NSLayoutConstraint!
    private let locationManager = CLLocationManager()
    var searchLocation: CLLocationCoordinate2D?
    var currentLocation: CLLocationCoordinate2D?
    
    let maker = GMSMarker()
    var oldPolylineArr = GMSPolyline()
    
    
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
    
    @IBAction func deleteMarker(_ sender: UIButton) {
        maker.map = nil
        oldPolylineArr.map = nil
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
        currentLocation = (manager.location?.coordinate)!
//        print("1 locations: \(String(describing: currentLocation?.latitude)), \(String(describing: currentLocation?.longitude))")
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
        maker.map = nil
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress ?? "")")
//        print("Place attributions: \(String(describing: place.attributions))")
        searchLocation = place.coordinate
        
//        searchLocLatitude = place.coordinate.longitude
//        searchLocLongitude = place.coordinate.longitude
        mapView.camera = GMSCameraPosition.camera(withLatitude: (searchLocation?.latitude)!, longitude: (searchLocation?.longitude)!, zoom: 15)
        showMaker(position: mapView.camera.target)
//        print("2 locations: \(String(describing: searchLocation?.latitude)), \(String(describing: searchLocation?.longitude))")
        getPolylineRoute(from: currentLocation!, to: searchLocation!)
        dismiss(animated: true, completion: nil)
    }
    
    func showMaker(position: CLLocationCoordinate2D) {
        maker.position = position
        maker.map = mapView
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
    
    func getPolylineRoute(from source : CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&mode=driving&units=metric")!
        
        let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            guard let aData = data else {return}
            do {
                if let json = try JSONSerialization.jsonObject(with: aData, options: .mutableContainers) as? DICT {
                    let routes = json["routes"] as? [DICT] ?? []
                    let zero = routes[0]
                    let overview_polyline = zero["overview_polyline"] as? DICT ?? [:]
                    let points = overview_polyline["points"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        self.showPath(polyStr: points)
                    }
                }
            } catch {
                print("error in JSONSerialization")
            }
        })
        task.resume()
    }
    
    func showPath(polyStr: String) {
        oldPolylineArr.map = nil
        let path = GMSPath(fromEncodedPath: polyStr)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        polyline.map = mapView
        oldPolylineArr = polyline
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

