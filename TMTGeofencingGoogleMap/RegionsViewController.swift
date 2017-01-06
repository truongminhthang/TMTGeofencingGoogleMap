//
//  ViewController.swift
//  TMT_Geofencing
//
//  Created by Trương Thắng on 1/4/17.
//  Copyright © 2017 Trương Thắng. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GoogleMaps

class RegionsViewController: UIViewController {
    
    @IBOutlet weak var regionsMapView: GMSMapView!
    @IBOutlet weak var updatesTableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var addRegion: UIBarButtonItem!
    var updateEvents: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        regionsMapView.isMyLocationEnabled = true

        registerNotification()
        updatesTableView.rowHeight = 60
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    lazy var locationManager : CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        return locationManager
    }()
    
    func registerNotification() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] (notification) in
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                self?.locationManager.stopUpdatingLocation()
                self?.locationManager.startMonitoringSignificantLocationChanges()
            } else {
                // Error: Significant location change monitoring is not available
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil) { [weak self](notification) in
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                self?.locationManager.stopMonitoringSignificantLocationChanges()
                self?.locationManager.startUpdatingLocation()
            } else {
                // Error: Significant location change monitoring is not available
            }
            
            if (self?.updatesTableView.isHidden == false) {
                self?.updatesTableView.reloadData()
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            
        case .denied:
            let alertController = UIAlertController(title: "Location services", message: "Location services were previously denied by the user. Please enable location services for this app in settings.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
        default:
            locationManager.startUpdatingLocation()
        }
        
        let regions = locationManager.monitoredRegions
        for region in regions {
            guard let circle = GMSCircle(region: region) else {continue}
            circle.map = regionsMapView
            circle.fillColor = UIColor.orange.withAlphaComponent(0.4)
        }
    }
    
    deinit {
        locationManager.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchView(_ sender: Any) {
        // Swap the hidden status of the map and table view so that the appropriate one is now showing.
        regionsMapView.isHidden = !regionsMapView.isHidden
        updatesTableView.isHidden = !updatesTableView.isHidden
        
        addRegion.isEnabled = !regionsMapView.isHidden
        if !updatesTableView.isHidden {
            updatesTableView.reloadData()
        }
    }
    
    @IBAction func addRegionDidTap() {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Create a new region based on the center of the map view.
            let coord = regionsMapView.camera.target
            let newRegion = CLCircularRegion(center: coord, radius: 200, identifier: "\(coord)")
            guard let circle = GMSCircle(region: newRegion) else {return }
            circle.map = regionsMapView
            circle.fillColor = UIColor.orange.withAlphaComponent(0.4)
            locationManager.startMonitoring(for: newRegion)
        }
    }
    
    
}

// MARK: - UITableViewDataSource

extension RegionsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return updateEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        configureCell(cell: cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
        cell.textLabel?.text = updateEvents[indexPath.row]
    }
}

// MARK: - <#Mark#>

extension RegionsViewController: CLLocationManagerDelegate {
    // When the user has granted authorization, start the standard location service.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Start the standard location service.
            locationManager.startUpdatingLocation()
        }
    }
    // A core location error occurred.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error)")
    }
    
    // The system delivered a new location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.first {
            let camera = GMSCameraPosition.camera(withLatitude: currentLocation.coordinate.latitude,
                                                  longitude: currentLocation.coordinate.longitude,
                                                  zoom: 18)
            
            
            DispatchQueue.main.async(execute: {
                self.regionsMapView.animate(to: camera)})
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let event = "did Enter region: \(region.identifier) at \(Date())"
        updateEvents.append(event)
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let event = "did Exit region: \(region.identifier) at \(Date())"
        updateEvents.append(event)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        let event = "monitoring did fail for region: \(region?.identifier ?? "Unknown") at \(Date())"
        updateEvents.append(event)
    }
}


