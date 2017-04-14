//
//  ViewController.swift
//  robotx_BLE
//
//  Created by Xipeng Wang on 4/13/17.
//  Copyright © 2017 Xipeng Wang. All rights reserved.
//

import UIKit
import CoreBluetooth

class RobotxViewController: UIViewController, UITextFieldDelegate,
    CBCentralManagerDelegate, CBPeripheralDelegate {

    //MARK: UI properties
    @IBOutlet weak var deiviceName: UILabel!
    @IBOutlet weak var controlButton: UIButton!
    @IBOutlet weak var rString: UILabel!
    @IBOutlet weak var tString: UITextField!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    
    //MARK: BLE properties
    var centralManager:CBCentralManager!
    var robotxBLE:CBPeripheral?
    var robotxCharc:CBCharacteristic?
    var devices : [String]! = ["------ Hello ROBOTX BLE ------------"]
    var connected:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tString.delegate = self
        
        controlButton.setTitle("Start", for: .normal)
        controlButton.setTitle("Searching", for: .highlighted)
        controlButton.setTitle("Connect to RobotX", for: .selected)
        controlButton.setTitle("Connected", for: [.highlighted, .selected])
        // Do any additional setup after loading the view, typically from a nib.
        self.connected = false;
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CBCentralManagerDelegate methods
    
    // Invoked when the central manager’s state is updated.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            message = "Bluetooth LE is turned on and ready for communication."
            
            //DEBUG:
            print(message)
            
        }
    }
    
    
    // Invoked when the central manager discovers a peripheral while scanning.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            devices.append(peripheralName)
            if peripheralName == RobotxDevice.CBNAME {
                print("ROBOTX_BLE FOUND! ADDING NOW!!!")
                // to save power, stop scanning for other devices
                // save a reference to the sensor tag
                robotxBLE = peripheral
                robotxBLE!.delegate = self
                controlButton.isSelected = true
                controlButton.isHighlighted = false
            }
        }
    }
    
    
    // Invoked when a connection is successfully created with a peripheral.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO ROBOTX!!!")
        controlButton.isHighlighted = true
        self.connected = true;
        deiviceName.text = peripheral.name
        peripheral.discoverServices(nil)
    }
    
    
    // Invoked when the central manager fails to create a connection with a peripheral.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.connected = false;
        deiviceName.text = "failed connection to Robotx"
        print("**** CONNECTION TO ROBOTX FAILS!!!")
    }
    
    
   
    // Invoked when an existing connection with a peripheral is torn down.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("**** DISCONNECTED FROM ROBOTX!!!")
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        deiviceName.text = "Device Name"
        if(robotxBLE != nil) {
            centralManager.cancelPeripheralConnection(robotxBLE!)
            robotxBLE = nil
            robotxCharc = nil
        }
        
    }
    
    
    //MARK: - CBPeripheralDelegate methods
    
    // Invoked when you discover the peripheral’s available services.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service)")
                // If we found either the temperature or the humidity service, discover the characteristics for those services.
                if (service.uuid == CBUUID(string: RobotxDevice.CBSERVICEUUID)) {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    // Invoked when you discover the characteristics of a specified service.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Chacteristic: \(characteristic)")
                if characteristic.uuid == CBUUID(string: RobotxDevice.CBChARACTERISTICUUID) {
                    robotxBLE?.setNotifyValue(true, for: characteristic)
                    robotxCharc = characteristic
                }
                /*
                let sendString : String = "HELLO IOS";
                let enableBytes = sendString.data(using: .utf8);
                print(sendString)
                //robotxBLE?.writeValue(enableBytes!, for: characteristic, type: .withResponse)
                robotxBLE?.writeValue(enableBytes!, for: characteristic, type: .withoutResponse)
                 */
            }
        }
    }
    
    // Invoked when you retrieve a specified characteristic’s value,
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: RobotxDevice.CBChARACTERISTICUUID) {
                if let string = String(data: dataBytes, encoding: .utf8) {
                    rString.text = string
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        guard let DevicesTableViewController = segue.destination as? DevicesTableViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        DevicesTableViewController.devicesNames = self.devices
    }
    
    //MARK: Actions
    @IBAction func controlAction(_ sender: UIButton) {
        
        if (self.connected) {
            sender.isHighlighted = false;
            sender.isSelected = false;
            self.connected = false;
            deiviceName.text = "Device Name"
            rString.text = "Received String"
            if(robotxBLE != nil) {
                centralManager.cancelPeripheralConnection(robotxBLE!)
                robotxBLE = nil
                robotxCharc = nil
            }
        } else if (sender.isSelected) {
            if (robotxBLE != nil) {
                centralManager.stopScan()
                centralManager.connect(robotxBLE!, options: nil)
            }
        } else if (sender.isHighlighted) {
            connected = false;
            centralManager.stopScan()
            devices.removeAll()
            sender.isHighlighted = true;
            // Initiate Scan for Peripherals
            if (true) {
                //Option 1: Scan for all devices
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            } else {
                // Option 2: Scan for devices that have the service you're interested in...
                let robotxBLEAdvertisingUUID = CBUUID(string: RobotxDevice.CBSERVICEUUID)
                print("Scanning for robotxBLE adverstising with UUID: \(robotxBLEAdvertisingUUID)")
                centralManager.scanForPeripherals(withServices: [robotxBLEAdvertisingUUID], options: nil)
            }
        }  else {
            print("Test,Test");
        }
    }
    
    @IBAction func sendAction(_ sender: UIButton) {
        if (robotxBLE != nil && robotxCharc != nil) {
            if let sendString : String = tString.text {
                let enableBytes = sendString.data(using: .utf8)
                //robotxBLE?.writeValue(enableBytes!, for: characteristic, type: .withResponse)
                robotxBLE?.writeValue(enableBytes!, for: robotxCharc!, type: .withoutResponse)
            }
        }
    }
    
    @IBAction func WButtonAction(_ sender: UIButton) {
        if (robotxBLE != nil && robotxCharc != nil) {
            let sendString : String = "W"
            let enableBytes = sendString.data(using: .utf8)
            robotxBLE?.writeValue(enableBytes!, for: robotxCharc!, type: .withoutResponse)
        }
    }
    
    @IBAction func AButtonAction(_ sender: UIButton) {
        if (robotxBLE != nil && robotxCharc != nil) {
            let sendString : String = "A"
            let enableBytes = sendString.data(using: .utf8)
            robotxBLE?.writeValue(enableBytes!, for: robotxCharc!, type: .withoutResponse)
        }
    }
    
    @IBAction func DButtonAction(_ sender: UIButton) {
        if (robotxBLE != nil && robotxCharc != nil) {
            let sendString : String = "D"
            let enableBytes = sendString.data(using: .utf8)
            robotxBLE?.writeValue(enableBytes!, for: robotxCharc!, type: .withoutResponse)
        }
    }
    
    @IBAction func SButtonAction(_ sender: UIButton) {
        if (robotxBLE != nil && robotxCharc != nil) {
            let sendString : String = "S"
            let enableBytes = sendString.data(using: .utf8)
            robotxBLE?.writeValue(enableBytes!, for: robotxCharc!, type: .withoutResponse)
        }
    }
    
    @IBAction func exc_ButtonAction(_ sender: UIButton) {
        if (robotxBLE != nil && robotxCharc != nil) {
            let sendString : String = "!"
            let enableBytes = sendString.data(using: .utf8)
            robotxBLE?.writeValue(enableBytes!, for: robotxCharc!, type: .withoutResponse)
        }
    }
    
    
    //MARK: Textfield Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    
}

