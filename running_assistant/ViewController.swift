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
import CoreBluetooth

class ViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate {

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
        
        // Initializing BlE
        startUpCentralManager()
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
            let coord = locationObj.coordinate
            
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
    
    //Bluetooth variables and functions
    var centralManager:CBCentralManager!
    var blueToothReady = false
    var currentPeripheral = CBPeripheral.Type.self
    
    func startUpCentralManager() {
        print("Initializing central manager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func discoverDevices() {
        print("discovering devices")
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        print("Discovered \(peripheral.name)")
        if peripheral.name == "BLE_Firmata" {
            print(peripheral.name)
            print("this worked!")
            centralManager.connectPeripheral(peripheral, options: nil)
            centralManager.stopScan()
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("callback function run")
    }
    
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("checking state")
        switch (central.state) {
        case .PoweredOff:
            print("CoreBluetooth BLE hardware is powered off")
            
        case .PoweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")
            blueToothReady = true;
            
        case .Resetting:
            print("CoreBluetooth BLE hardware is resetting")
            
        case .Unauthorized:
            print("CoreBluetooth BLE state is unauthorized")
            
        case .Unknown:
            print("CoreBluetooth BLE state is unknown");
            
        case .Unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform");
            
        }
        if blueToothReady {
            discoverDevices()
        }
    }

}

