//
//  SKDNavigationController.swift
//  SakerDemo
//
//  Created by Thomas Morrell on 17/04/2016.
//  Copyright © 2016 thomasmorrell. All rights reserved.
//

import UIKit
import CoreBluetooth

class SKDNavigationController: UINavigationController {

    // Constants
    let animator = SKDAnimator()
    let uuidServiceString = "c00eed18-0480-11e6-b512-3e1d05defe78"
    let uuidCharacteristicString = "d50aa268-0483-11e6-b512-3e1d05defe78"
    
    // Properties
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    var data: NSMutableData?
    var currentIdentifier = ""
    
    lazy var alertLabel: UILabel = {
        
        let alertLabel = UILabel.init()
        alertLabel.translatesAutoresizingMaskIntoConstraints = false
        alertLabel.text = "Test"
        alertLabel.font = UIFont.init(name: "HirukoPro-Lt", size: 16.0)
        alertLabel.textColor = UIColor.whiteColor()
        
        return alertLabel
    }()
    
    lazy var alertView: UIView = { [unowned self] in
       
        let temporaryView = UIView.init()
        temporaryView.translatesAutoresizingMaskIntoConstraints = false
        temporaryView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
        temporaryView.layer.cornerRadius = 4.0
        temporaryView.layer.masksToBounds = true
        temporaryView.alpha = 0.0
        
        temporaryView.addSubview(self.alertLabel)
        
        var views = ["alertLabel": self.alertLabel]
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-40-[alertLabel]-40-|", options: [], metrics: nil, views: views)
        temporaryView.addConstraints(constraints)
        constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-20-[alertLabel]-20-|", options: [], metrics: nil, views: views)
        temporaryView.addConstraints(constraints)
        
        self.view.addSubview(temporaryView)
        
        let bottomConstraint = NSLayoutConstraint.init(item: self.view, attribute: .Bottom, relatedBy: .Equal, toItem: temporaryView, attribute: .Bottom, multiplier: 1.0, constant: 20.0)
        let trailingConstraint = NSLayoutConstraint.init(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: temporaryView, attribute: .Trailing, multiplier: 1.0, constant: 20.0)
        self.view.addConstraints([bottomConstraint,trailingConstraint])
        
        return temporaryView
    }()
    
    
    override func viewDidLoad() {
        
        delegate = self
        
        // Start up the CBCentralManager
        centralManager  = CBCentralManager.init(delegate: self, queue: nil)
        
        // Add somewhere to store the incoming data
        data = NSMutableData.init()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        // Don't keep it going while we're not showing.
        centralManager?.stopScan()
        print("Stopped scanning")
        hideAlert()
        
        super.viewWillDisappear(animated)
    }
    
    func showAlert(text: String, autodismiss: Bool) {
        
        let temporaryView = alertView
        alertLabel.text = text
        UIView.animateWithDuration(0.3) { 
            
            temporaryView.alpha = 1.0
        }
        
        if autodismiss {
            
            UIView.animateWithDuration(0.3, delay: 1.2, options: [], animations: {
                
                temporaryView.alpha = 0.0
                }, completion: nil)
        }
    }
    
    func hideAlert() {
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: [], animations: {
            
            self.alertView.alpha = 0.0
            }, completion: nil)
    }
    
    func handleMessage(message: String) {
        
        if (message != currentIdentifier) {
            
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier(message)
            setViewControllers([vc], animated: true)
            currentIdentifier = message
        }
    }
}

extension SKDNavigationController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        // Check if the state is powered on
        if (central.state != .PoweredOn) {
            return
        }
        
        // Start scanning
        scan()
        print("State updated")
    }
    
    func scan() {
        
        centralManager?.scanForPeripheralsWithServices([CBUUID.init(string: uuidServiceString)], options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        print("Started scanning")
        
        showAlert("Started scanning", autodismiss: false)
    }
    
    func cleanup() {
        
        // Don't do anything if the peripheral is connected
        if (discoveredPeripheral?.state == .Connected) {
            return
        }
        
        // Check if subscribed on the peripheral
        if (discoveredPeripheral?.services != nil) {
            
            if let services = discoveredPeripheral?.services {
                
                for service in services {
                    if (service.characteristics != nil) {
                        
                        if let characteristics = service.characteristics {
                            
                            for characteristic in characteristics {
                                
                                if (characteristic.UUID == CBUUID.init(string: uuidCharacteristicString)) {
                                    if (characteristic.isNotifying) {
                                        
                                        // Notifying, so unsubscribe
                                        discoveredPeripheral?.setNotifyValue(false, forCharacteristic: characteristic)
                                        
                                        return
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Connected but not subscribed, just disconnect
        if let discoveredPeripheral = discoveredPeripheral {
            
            centralManager?.cancelPeripheralConnection(discoveredPeripheral)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        // Reject any where the value is above reasonable range
        if (RSSI.integerValue > -15) {
            return;
        }
        
        // Reject if the signal strength is too low to be close enough (Close is around -22dB)
        if (RSSI.integerValue < -80) {
            return;
        }
        
        print("Discovered %s at %d", peripheral.name, RSSI.integerValue)
        
        // Check if the peripheral has already been seen
        if (discoveredPeripheral != peripheral) {
            
            discoveredPeripheral = peripheral
            
            print("Connecting to peripheral %s", peripheral.name)
            centralManager?.connectPeripheral(peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
     
        print("Failed to connect to %s", peripheral.name)
        cleanup()
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        print("Peripheral connected")
        showAlert("Peripheral connected", autodismiss: true)
        
        // Stop scanning
        centralManager?.stopScan()
        print("Stopped scanning")
        
        // Clear any existing data
        data?.length = 0
        
        // Set the peripheral delegate
        peripheral.delegate = self
        
        // Search for services with the UUID
        peripheral.discoverServices([CBUUID.init(string: uuidServiceString)])
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
     
        print("Peripheral disconnected")
        showAlert("Peripheral disconnected", autodismiss: true)
        discoveredPeripheral = nil
        
        // Peripheral disconnected so start scanning
        scan()
        handleMessage("scanning")
    }
}

extension SKDNavigationController: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        if (error != nil) {
            
            cleanup()
            return
        }
        
        // Discover characteristic
        if let services = peripheral.services {
            
            for service in services {
                
                peripheral.discoverCharacteristics([CBUUID.init(string: uuidCharacteristicString)], forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        if (error != nil) {
            
            cleanup()
            return
        }
        
        if let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                
                if (characteristic.UUID == CBUUID.init(string: uuidCharacteristicString)) {
                    
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if (error != nil) {
            
            print("Something went wrong")
            return
        }
        
        if let value = characteristic.value {
            
            let stringData = String.init(data: value, encoding: NSUTF8StringEncoding)
            
            // Check if the message is finished
            if (stringData == "EOM") {
                
                if let data = data {
                    
                    var message = String.init(data: data, encoding: NSUTF8StringEncoding)
                    if let message = message {
                        
                        handleMessage(message)
                    }
                }
                data = NSMutableData.init()
                
                return
            }
            
            // Otherwise, append the data
            data?.appendData(value)
            
            print("Received: %s", stringData)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if (error != nil) {
            
            print("Something went wrong")
        }
        
        if (characteristic.UUID != CBUUID.init(string: uuidCharacteristicString)) {
            
            return
        }
        
        if (characteristic.isNotifying) {
            print("Notification began on %@", characteristic)
        } else {
            print("Notification stopped on %@. Disconnecting.", characteristic)
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}


extension SKDNavigationController: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController,
                              animationControllerForOperation operation: UINavigationControllerOperation,
                                                              fromViewController fromVC: UIViewController,
                                                                                 toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }
    
}
