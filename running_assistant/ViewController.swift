//
//  ViewController.swift
//  running_assistant
//
//  Created by Tyler Nappy on 3/13/16.
//  Copyright © 2016 Tyler Nappy. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var lonLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var paceSlider: UISlider!
    
    @IBOutlet weak var speedLabel: UILabel!
    
    
    
    var locationManager:CLLocationManager!
    
    var locationStatus = ""
    var locationFixAchieved = false
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Initiailizing GPS library
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = 1.0
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sliderValueChange(sender: UISlider) {
        let value = String(format:"%.02f", paceSlider.value)
        paceLabel.text = value
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        locationManager.stopUpdatingLocation()
        if (locationFixAchieved == false) { //run once
            locationFixAchieved = true
            let locationArray = locations as NSArray
            let locationObj = locationArray.lastObject as! CLLocation
//            let coord = locationObj.coordinate
            
            count++
            
            print(count)
//            latLabel.text = String(format:"Lat: %.02f", coord.latitude)
//            lonLabel.text = String(format:"Lon: %.02f", coord.longitude)
            print(coord.latitude)
            print(coord.longitude)
        }
        let newLocation = locations.last
        print("current position: \(newLocation!.coordinate.longitude) , \(newLocation!.coordinate.latitude)")
        print("current speed: \(newLocation!.speed)")
        latLabel.text = String(format:"Lat: %.06f", newLocation!.coordinate.latitude)
        lonLabel.text = String(format:"Lon: %.06f", newLocation!.coordinate.longitude)
        speedLabel.text = String(format:"Speed: %.06f", newLocation!.speed)
//        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            var shouldIAllow = false
            
            switch status {
            case CLAuthorizationStatus.Restricted:
                locationStatus = "Restricted Access to location"
            case CLAuthorizationStatus.Denied:
                locationStatus = "User denied access to location"
            case CLAuthorizationStatus.NotDetermined:
                locationStatus = "Status not determined"
            default:
                locationStatus = "Allowed to location Access"
                shouldIAllow = true
            }
            NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
            if (shouldIAllow == true) {
                NSLog("Location to Allowed")
                // Start location services
                locationManager.startUpdatingLocation()
            } else {
                NSLog("Denied access: \(locationStatus)")
            }
    }

}

