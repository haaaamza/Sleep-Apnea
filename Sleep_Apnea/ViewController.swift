//
//  ViewController.swift
//  Sleep_Apnea
//
//  Created by Hamza Mian on 2021-01-12.
//

import UIKit
import CoreBluetooth
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var connectingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var centralMessage: UILabel!
    @IBOutlet weak var topImage: UIImageView!
    @IBOutlet weak var bottomImage: UIImageView!
    @Published var notifRepo = notificationRepository()
    
    //TODO: Possibly Get rid of Popover to Connect and connect in this ViewController.
    var peripheralSleep: CBPeripheral?
    var centralManager: CBCentralManager?
    
    //MARK: ___________VIEW LIFECYCLE__________________________________
    override func viewDidAppear(_ animated: Bool) {
        self.connectingActivityIndicator.startAnimating() //initial view upon start
        //        self.centralMessage.text = "Searching for the device..."
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        profileButton.layer.cornerRadius = 23.0
        // STEP 1: create a concurrent background queue for the central
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        // STEP 2: create a central to scan for, connect to,
        // manage, and collect data from peripherals
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        //        performSegue(withIdentifier: "connect", sender: self)
    }
    
    //MARK:______________SEGUE TO USERNAME_____________________________________
    @IBAction func touchProfile(_ sender: Any) {//To update profile, in order to get info to store data in Firebase
        performSegue(withIdentifier: "profile", sender: self)
    }
    
    //MARK: _______________BLUETOOTH STATES__________________________________
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //        performSegue(withIdentifier: "connect", sender: self)
        switch central.state {
            case .unknown:
                print("Bluetooth status is UNKNOWN")
            case .resetting:
                print("Bluetooth status is RESETTING")
            case .unsupported:
                print("Bluetooth status is UNSUPPORTED")
            case .unauthorized:
                print("Bluetooth status is UNAUTHORIZED")
            case .poweredOff:
                print("Bluetooth status is POWERED OFF")
                DispatchQueue.main.async {
                    self.centralMessage.text = "Please turn on your Bluetooth!"
                    self.topImage.isHidden = false
                    self.bottomImage.isHidden = true
                    self.topImage.image = UIImage(named: "bluetooth_disabled")
                }
            case .poweredOn:
                print("Bluetooth status is POWERED ON")
                DispatchQueue.main.async { () -> Void in
                    self.connectingActivityIndicator.startAnimating()
                    self.centralMessage.text = "Searching for my board...."
                    self.topImage.isHidden = true
                }
                // STEP 3.2: scan for peripherals that we're interested in
                centralManager?.scanForPeripherals(withServices: nil, options: nil)
                
            @unknown default:
                print("UNKNOWN BLUETOOTH ERROR");
                exit(0);
        } // END switch
    }
    // STEP 4.1: discover what peripheral devices OF INTEREST
    // are available for this app to connect to
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else {
            return
        }
        print((peripheral.name!))
        print(peripheral.identifier)
        decodePeripheralState(peripheralState: peripheral.state)
        if ((peripheral.name?.contains("Shiv05_3311")) ?? false){ //MARK: Insert name here
            print("Found my board!")
            self.peripheralSleep = peripheral
            self.peripheralSleep?.delegate = self
            self.centralManager?.stopScan()
            self.centralManager?.connect(peripheralSleep!)
        }
        
    } // END func centralManager(... didDiscover peripheral
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async { () -> Void in
            self.connectingActivityIndicator.stopAnimating()
            self.connectingActivityIndicator.isHidden = true
            self.centralMessage.text = "Connected!"
            self.topImage.isHidden = false
            self.topImage.image = UIImage(named: "cloud")
            self.bottomImage.isHidden = false
        }
        print("Discovering all  services!....");
        self.peripheralSleep?.discoverServices([CBUUID.bandService])
        self.peripheralSleep?.delegate = self
    }
    
    
    // In the case the board is disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from my board!");
        DispatchQueue.main.async { () -> Void in
            self.centralMessage.text = "Searching for my board...."
            self.connectingActivityIndicator.isHidden = false
            self.connectingActivityIndicator.startAnimating()
        }
        self.centralManager?.scanForPeripherals(withServices: [CBUUID.bandService])
        print("Scanning for Periphs")
    }
    
    //
    // CBPeripheralDelegate Methods
    //
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            // now to discover characteristics for each service
            for service in services {
                // we want only to discover the characteristics of my InertialMeasurement Service
                if service.uuid == CBUUID.bandService {
                    // by setting it to be nil its going to discover all characteristics
                    print("My desired service: \(service.description)\n")
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    } // END func peripheral(... didDiscoverServices
    
    // STEP 10: confirm we've discovered characteristics
    // of interest within services of interest
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let charac = service.characteristics {
            for characteristic in charac {
                if characteristic.uuid == CBUUID.readBand {
                    print("My desired characteristic: \(characteristic.description)\n")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
        
    } // END func peripheral(... didDiscoverCharacteristicsFor service
    
    // STEP 12: we're notified whenever a characteristic
    // value updates regularly or posts once; read and
    // decipher the characteristic value(s) that we've
    // subscribed to
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // for acceleration
        if characteristic.uuid == CBUUID.readBand{
            // STEP 13: we generally have to decode BLE
            // data into human readable format
//            let acc_data = tb_vectorValue(using: characteristic)
            let eog_data = getEyeData(using: characteristic) ?? 0 //gets Eye data
            //print("eog data: " + String(eog_data))
            DispatchQueue.main.async { () -> Void in
                if username == ""{self.centralMessage.text = "Please enter your name!"}
                else {
                    self.centralMessage.text = "Storing your data in the Cloud!"
                    //MARK: Update FireBase here!
                    //print("Cloud!!!")
                    print("eog data: " + String(eog_data))
//                    let e1_data = Double((eog_data?)!).magnitude)
//                    let x_data = Double((acc_data?.x)!).magnitude
//                    let y_data = Double((acc_data?.y)!).magnitude
//                    let z_data = Double((acc_data?.z)!).magnitude
//                    print(x_data)
                    self.notifRepo.addData(Notification(EOG: eog_data))
                }
            } // END DispatchQueue.main.async...
        } // END if characteristic.uuid ==...
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("WRITE VALUE : \(characteristic)")
    }
    
    
    // Adapted from Silabs ThunderBoard App Code.
    func tb_vectorValue(using accelerometerMeasurementCharacteristic: CBCharacteristic) -> accelerometer_data? {
        if let data = accelerometerMeasurementCharacteristic.value{
            if data.count >= 6 {
                var xAccelerationTimes1k: Int16 = 0;
                var yAccelerationTimes1k: Int16 = 0;
                var zAccelerationTimes1k: Int16 = 0;
                (data as NSData).getBytes(&xAccelerationTimes1k, range: NSMakeRange(0, 2))
                (data as NSData).getBytes(&yAccelerationTimes1k, range: NSMakeRange(2, 2))
                (data as NSData).getBytes(&zAccelerationTimes1k, range: NSMakeRange(4, 2))
                let xAcceleration = α(xAccelerationTimes1k) / 1000.0;
                let yAcceleration = α(yAccelerationTimes1k) / 1000.0;
                let zAcceleration = α(zAccelerationTimes1k) / 1000.0;
                return accelerometer_data(x: xAcceleration, y: yAcceleration, z: zAcceleration)
            }
        }
        return nil
    }
    func getEyeData (using eogMeasurementCharacteristic: CBCharacteristic) -> Double?  /*/eyeData?*/{
        if let data = eogMeasurementCharacteristic.value{
            var e1Eye: Double = 0;

            (data as NSData).getBytes(&e1Eye, range: NSMakeRange(0, 2))
            return e1Eye //Processes Eye data for both eyes, due to device design.
            
        }
        print("We reached here, data is not a value!")
        return nil
    }
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        switch peripheralState {
            case .disconnected:
                print("Peripheral state: disconnected")
            case .connected:
                print("Peripheral state: connected")
            case .connecting:
                print("Peripheral state: connecting")
            case .disconnecting:
                print("Peripheral state: disconnecting")
            @unknown default:
                print("Unknown Peripheral state!")
                exit(0);
        }
        
    } // END func decodePeripheralState(peripheralState
}


