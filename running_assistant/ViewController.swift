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

class ViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    
    @IBOutlet weak var lonLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var paceSlider: UISlider!
    
    @IBOutlet weak var bleLabel: UILabel!
    
    @IBOutlet weak var speedLabel: UILabel!
    
    // Location Manager variables
    var locationManager:CLLocationManager!
    
    var locationStatus = ""
    var locationFixAchieved = false
    var count = 0
    // end Location Manager variables
    
    // Bluetooth variables
    var centralManager:CBCentralManager!
    var blueToothReady = false
    var peripheralConnected = false
    //    var currentPeripheral = CBPeripheral.Type.self
    var currentPeripheral:CBPeripheral!
    
    var uartService:CBService?
    var rxCharacteristic:CBCharacteristic?
    var txCharacteristic:CBCharacteristic?
    // end Bluetooth variables
    
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
    
    @IBAction func dataButton(sender: UIButton) {
        print("Button pressed")
        if (peripheralConnected == true) {
            
        }
    }
    
    // Location Manager (GPS) functions
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
    // end Location Manager (GPS) functions

    // Bluetooth functions
    func startUpCentralManager() {
        print("Initializing central manager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func discoverDevices() {
        print("discovering devices")
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    // Bluetooth central manager delegate functions
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        print("Discovered \(peripheral.name)")
        currentPeripheral = peripheral
        if peripheral.name == "BLE_Firmata" {
            currentPeripheral.delegate = self
            centralManager.stopScan()
            print(currentPeripheral.name)
            print("this worked!")
            centralManager.connectPeripheral(currentPeripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected to peripheral")
        bleLabel.text = "Connected to peripheral"
//        peripheral.delegate = self
        peripheral.discoverServices(nil)
//        peripheral.discoverServices([CBUUID(string: "00001530-1212-efde-1523-785feabcd123"), CBUUID(string: "180A")]) //array of dfuServiceUUID and deviceInformationServiceUUID
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let services = peripheral.services as [CBService]!
        for s in services {
            print(s)
            uartService = s
//            peripheral.discoverCharacteristics([txCharacteristicUUID(), rxCharacteristicUUID()], forService: uartService!)
            peripheral.discoverCharacteristics([CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e"), CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")], forService: uartService!) // for txCharacteristicUUID and rxCharacteristicUUID
//            peripheral.discoverCharacteristics(nil, forService: s)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for c in (service.characteristics as [CBCharacteristic]!) {
            print(c)
        }
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
    // end Bluetooth functions

}

