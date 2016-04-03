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
    
    var pace: Double = 0.0
    var desiredPace: Double = 0.0
    var previousDifference: Double = 0.0
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
    
    private var portMasks = [UInt8](count: 3, repeatedValue: 0)
    
    enum PinState:Int{
        case Low = 0
        case High
    }
    
    enum PinMode:Int{
        case Unknown = -1
        case Input
        case Output
        case Analog
        case PWM
        case Servo
    }
    // end Bluetooth variables
    
    // Miscellaneous variables
    let ledPins: [UInt8] = [2, 3, 5, 6, 9, 10, 17, 18] //17=A0 18=A1
//    let ledPins: [[String:Any]] = [["pinNumber": 2, "currentState": PinState.Low], ["pinNumber": 3, "currentState": PinState.Low], ["pinNumber": 5, "currentState": PinState.Low], ["pinNumber": 6, "currentState": PinState.Low], ["pinNumber": 9, "currentState": PinState.Low], ["pinNumber": 10, "currentState": PinState.Low], ["pinNumber": 17, "currentState": PinState.Low], ["pinNumber": 18, "currentState": PinState.Low]] //17=A0 18=A1
    var connectedToBLEAndSetModeToOutPut = false
    var previousLed: UInt8 = 0
    
    let metersPerSecondToMilesPerMinute = 0.0372823
    // end Miscelaneous variables
    
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
        desiredPace = Double(paceSlider.value)
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
            
            count += 1
            
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
        if (connectedToBLEAndSetModeToOutPut == true) {
            chooseLeds(newLocation!.speed)
        }
    }
    
    func chooseLeds(speed: CLLocationSpeed) {
        let speedMilesPerSecond = metersPerSecondToMilesPerMinute*speed //convert from m/s to miles/min
        let pace = 1/speedMilesPerSecond // convert from miles/min to min/mile
        let difference = desiredPace - pace
        if (difference != previousDifference) {
            writePinState(PinState.Low, pin:previousLed, characteristic:txCharacteristic!)
            if (difference < -45 && difference >= -60) {
                writePinState(PinState.High, pin:ledPins[0], characteristic:txCharacteristic!)
                previousLed = ledPins[0]
            }
            else if (difference < -30 && difference >= -45){
                writePinState(PinState.High, pin:ledPins[1], characteristic:txCharacteristic!)
                previousLed = ledPins[1]
            }
                
            else if (difference < -15 && difference >= -30) {
                writePinState(PinState.High, pin:ledPins[2], characteristic:txCharacteristic!)
                previousLed = ledPins[2]
            }
                
            else if (difference < 0 && difference >= -15) {
                writePinState(PinState.High, pin:ledPins[3], characteristic:txCharacteristic!)
                previousLed = ledPins[3]
            }
                
            else if (difference > 0 && difference <= 15) {
                writePinState(PinState.High, pin:ledPins[4], characteristic:txCharacteristic!)
                previousLed = ledPins[4]
            }
                
            else if difference > 15 && difference <= 30 {
                writePinState(PinState.High, pin:ledPins[5], characteristic:txCharacteristic!)
                previousLed = ledPins[5]
            }
                
            else if (difference > 30 && difference <= 45) {
                writePinState(PinState.High, pin:ledPins[6], characteristic:txCharacteristic!)
                previousLed = ledPins[6]
            }
                
            else if (difference>45 && difference<=60) {
                writePinState(PinState.High, pin:ledPins[7], characteristic:txCharacteristic!)
                previousLed = ledPins[7]
            }            
        }
        previousDifference = difference
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
//        peripheral.discoverServices([CBUUID(string: "00001530-1212-EFDE-1523-785FEABCD123"), CBUUID(string: "180A")]) //array of dfuServiceUUID and deviceInformationServiceUUID
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let services = peripheral.services as [CBService]!
        for s in services {
            print(s)
            uartService = s
//            peripheral.discoverCharacteristics([txCharacteristicUUID(), rxCharacteristicUUID()], forService: uartService!)
            peripheral.discoverCharacteristics([CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"), CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")], forService: s) // for txCharacteristicUUID and rxCharacteristicUUID
//            peripheral.discoverCharacteristics(nil, forService: s)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for c in (service.characteristics as [CBCharacteristic]!) {
            if (c.UUID == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")) { // if txCharacteristicUUID
                txCharacteristic = c
                print("IF STATEMENT WORKED!")
                print(c)
                //set pin modes to OUTPUT
                for pin in (ledPins as [UInt8]) {
                    print("Setting pin to OUTPUT: ")
                    print(pin)
                    writePinMode(PinMode.Output, pin:pin, characteristic:c)
                }
//                for pin in (ledPins as [UInt8]) {
//                    print("Setting pin to OUTPUT: ")
//                    print(pin)
//                    writePinState(PinState.High, pin:pin, characteristic:c)
//                }
//                for pin in (ledPins as [UInt8]) {
//                    print("Setting pin to OUTPUT: ")
//                    print(pin)
//                    writePinState(PinState.Low, pin:pin, characteristic:c)
//                }
                connectedToBLEAndSetModeToOutPut = true
            }
        }
    }
    
    func writePinMode(newMode:PinMode, pin:UInt8, characteristic:CBCharacteristic) {
        
        //Set a pin's mode
        
        let data0:UInt8 = 0xf4        //Status byte == 244
        let data1:UInt8 = pin        //Pin#
        let data2:UInt8 = UInt8(newMode.rawValue)    //Mode
        
        let bytes:[UInt8] = [data0, data1, data2]
        let newData:NSData = NSData(bytes: bytes, length: 3)
        print("Setting pin to OUTPUT")
        currentPeripheral.writeValue(newData, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
        
    }
    
    func writePinState(newState: PinState, pin:UInt8, characteristic:CBCharacteristic){
        
        
        print((self, funcName: (#function), logString: "writing to pin: \(pin)"))
        
        //Set an output pin's state
        
        var data0:UInt8  //Status
        var data1:UInt8  //LSB of bitmask
        var data2:UInt8  //MSB of bitmask
        
        //Status byte == 144 + port#
        let port:UInt8 = pin / 8
        data0 = 0x90 + port
        
        //Data1 == pin0State + 2*pin1State + 4*pin2State + 8*pin3State + 16*pin4State + 32*pin5State
        let pinIndex:UInt8 = pin - (port*8)
        var newMask = UInt8(newState.rawValue * Int(powf(2, Float(pinIndex))))
        
        portMasks[Int(port)] &= ~(1 << pinIndex) //prep the saved mask by zeroing this pin's corresponding bit
        newMask |= portMasks[Int(port)] //merge with saved port state
        portMasks[Int(port)] = newMask
        data1 = newMask<<1; data1 >>= 1  //remove MSB
        data2 = newMask >> 7 //use data1's MSB as data2's LSB
        
        let bytes:[UInt8] = [data0, data1, data2]
        let newData:NSData = NSData(bytes: bytes, length: 3)
//        delegate!.sendData(newData)
        print("Setting pin to HIGH")
        currentPeripheral.writeValue(newData, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
        
//        print((self, funcName: "setting pin states -->", logString: "[\(binaryforByte(portMasks[0]))] [\(binaryforByte(portMasks[1]))] [\(binaryforByte(portMasks[2]))]"))
        
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("----------")
        print(characteristic)
        print(error)
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

