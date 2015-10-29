/*
* Copyright (c) 2015, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
* documentation and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
* software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation
import HomeKit

///  - protocol: DoorLockProtocol
///  - The DoorLockProtocol defines the communication method for state updates from DoorLock accessory to their delegates.
///
///    overview:
///     set a delegate on a DoorLock accessory and implement methods in this protocol for updates you are interested in observing to keep your app's UI in sync with changes to DoorLock  accessory's internal state
protocol DoorLockProtocol {
    
    /// Invoked when DoorLock TargetState has been read
    /// - Parameter value: the current value of DoorLock TargetState, 0 for Unsecure and 1 for Secure
    func didReceiveLockTargetState(value: Int)
    
    /// Invoked when DoorLock CurrentState has been read
    /// - Parameter value: the current value of DoorLock CurrentState, 0 for Unsecure, 1 for Secure, 2 for Jammed and 3 for Unknown
    func didReceiveLockCurrentState(value: Int)
    
    /// Invoked when DoorLock TargetState has been written
    /// - Parameter lockState: the current value of DoorLock TargetState, 0 for Unsecure and 1 for Secure
    func didLockTargetStateChanged(lockState: Int)
    
    /// Invoked when all services and characteristics are found inside DoorLock
    /// - Parameter isAllFound: is true if all required Services and characteristics are found inside accessory and false otherwise
    func didFoundServiceAndCharacteristics(isAllFound: Bool)
    
    /// Invoked when an information is required to log
    /// - Parameter message: is log message of type string
    func didReceiveLogMessage(message: String)
    
    /// Invoked when an error occurs during communicating with accessory
    /// - Parameter message: is string representation of error code
    func didReceiveErrorMessage(message: String)
    
    /// Invoked when an accessory change its reachability status
    /// - Parameter accessory: is the HomeKit accessory that get back in range or go out of range
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!)
}

///    - class: DoorLock
///    - The DoorLock class implements the logic required to communicate with the DoorLock accessory.
///
///    overview:
///    set a DoorLock accessory to function selectedAccessory(accessory: HMAccessory?), discover services and characteristics, readValues and then change the status of UI accordingly. Also you can write to DoorLock characteristic TargetState to turn ON or OFF
///    - required: the protocol DoorLockProtocol must be implemented in order to receive internal status of DoorLock accessory

public class DoorLock: NSObject, HMAccessoryDelegate {
    
    var delegate:DoorLockProtocol?
    private var homekitAccessory: HMAccessory?
    private var isLockServiceFound:Bool = false
    
    private var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    private var characteristicName: HMCharacteristicName = HMCharacteristicName()
    private var serviceName: HMServiceName = HMServiceName()
    
    private var lockMechanismCurrentState: HMCharacteristic?
    private var lockMechanismTargetState: HMCharacteristic?
    
    /// Singleton implementation that will create only one instance of class DoorLock
    public class var sharedInstance : DoorLock {
        struct StaticDoorLock {
            static let instance : DoorLock = DoorLock()
        }
        return StaticDoorLock.instance
    }
    
    /// selectedAccessory sets the DoorLock accessory.
    /// If accessory is nil then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter accessory: it is HomeKit DoorLock accessory of type HMAccessory.
    public func selectedAccessory(accessory: HMAccessory?) {
        if let accessory = accessory {
            homekitAccessory = accessory
            if let homekitAccessory = homekitAccessory {
                homekitAccessory.delegate = self
            }
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Accessory is nil")
            }
        }
    }
    
    /// isAccessoryConnected rerurns the reachablity status of DoorLock accessory
    /// - Returns: Bool value, true if DoorLock accessory is reachable and false otherwise
    public func isAccessoryConnected() -> Bool {
        if let homekitAccessory = homekitAccessory {
            return homekitAccessory.reachable
        }
        return false
    }
    
    private func clearAccessory() {
        lockMechanismCurrentState = nil
        lockMechanismTargetState = nil
        homekitAccessory = nil
    }

    /// writeToTargetState sets the TargetState value of DoorLock accessory
    /// If an error occurs during write operation then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter lockState: It is Int type value for DoorLock TargetState, 0 for Unsecure and 1 for Secure
    public func writeToTargetState(lockState:Int) {
        if let lockMechanismTargetState = lockMechanismTargetState {
            lockMechanismTargetState.writeValue(lockState, completionHandler: { (error: NSError?) -> Void in
                if error == nil {
                    print("successfully switched Lock state")
                    if let delegate = self.delegate {
                        delegate.didLockTargetStateChanged(lockState)
                    }
                }
                else {
                    print("Error in switching Lock state \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Lockstate: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: LockMechanismTargetState is nil")
            }
        }
    }
    
    /// discoverServicesAndCharacteristics finds all services and characteristics inside homekit accessory.
    /// After search of services and characteristics, It calls the didFoundServiceAndCharacteristics: method of its delegate object.
    /// if required services and characteristics are found then parameter of didFoundServiceAndCharacteristics is set to true or false otherwise
    /// It also calls didReceiveLogMessage method and can call didReceiveErrorMessage method of its delegate object.
    public func discoverServicesAndCharacteristics() {
        if let homekitAccessory = homekitAccessory {
            isLockServiceFound = false
            for service in homekitAccessory.services {
                print("\(homekitAccessory.name) has Service: \(service.name) and ServiceType: \(service.serviceType) and ReadableServiceType: \(serviceName.getServiceType(service.serviceType))")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("\(homekitAccessory.name) has Service: \(serviceName.getServiceType(service.serviceType))")
                }
                if isLockService(service) {
                    print("Lock service found")
                    isLockServiceFound = true
                }
                discoverCharacteristics(service)
            }
            if isLockServiceFound == true && lockMechanismCurrentState != nil && lockMechanismTargetState != nil {
                if let delegate = delegate {
                    delegate.didFoundServiceAndCharacteristics(true)
                }
            }
            else {
                if let delegate = delegate {
                    delegate.didFoundServiceAndCharacteristics(false)
                }
                clearAccessory()
            }
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Accessory is nil")
            }
        }
    }
    
    private func isLockService(service: HMService?) -> Bool {
        if let service = service {
            if service.serviceType == HMServiceTypeLockMechanism {
                return true
            }
            return false
        }
        return false
    }
    
    private func discoverCharacteristics(service: HMService?) {
        if let service = service {
            for characteristic in service.characteristics {
                print("Service: \(service.name) has characteristicType: \(characteristic.characteristicType) and ReadableCharType: \(characteristicName.getCharacteristicType(characteristic.characteristicType))")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("    characteristic: \(characteristicName.getCharacteristicType(characteristic.characteristicType))")
                }
                if isCurrentStateCharacteristic(characteristic) {
                    lockMechanismCurrentState = characteristic
                }
                else if isTargetStateCharacteristic(characteristic) {
                    lockMechanismTargetState = characteristic
                }            
            }
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Service is nil")
            }
        }
    }
    
    private func isCurrentStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeCurrentLockMechanismState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isTargetStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeTargetLockMechanismState {
                return true
            }
            return false
        }
        return false
    }
    
    /// readValues will read values of DoorLock CurrentState and TargetState.
    /// It will call didReceiveLockCurrentState, didReceiveLockTargetState methods of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readValues() {
        if let homekitAccessory = homekitAccessory {
            if isLockServiceFound && homekitAccessory.reachable {
                print("\(homekitAccessory.name) is reachable")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("Reading DoorLock Characteristics values ...")
                }
                readLockMechanismCurrentState()
                readlockMechanismTargetState()
            }
            else {
                print("\(homekitAccessory.name) is not reachable")
                if let delegate = self.delegate {
                    delegate.didReceiveErrorMessage("Accessory is not reachable")
                }
                clearAccessory()
            }
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Accessory is nil")
            }
        }
    }
    
    /// readLockMechanismCurrentState will read value of DoorLock CurrentState.
    /// It will call didReceiveLockCurrentState method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readLockMechanismCurrentState() {
        if let lockMechanismCurrentState = lockMechanismCurrentState {
            lockMechanismCurrentState.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Lock Mechanism Current State value from Lock \(lockMechanismCurrentState.value)")
                    if lockMechanismCurrentState.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveLockCurrentState(lockMechanismCurrentState.value as! Int)
                        }
                    }
                    else {
                        print("Lock Mechanism Current State value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Current State value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Lock Mechanism Current State value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Current State: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: LockMechanismCurrentState  is nil")
            }
        }
    }
    
    /// readlockMechanismTargetState will read value of DoorLock TargetState.
    /// It will call didReceiveLockTargetState method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readlockMechanismTargetState() {
        if let lockMechanismTargetState = lockMechanismTargetState {
            lockMechanismTargetState.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Lock Mechanism Target State value from Lock \(lockMechanismTargetState.value)")
                    if lockMechanismTargetState.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveLockTargetState(lockMechanismTargetState.value as! Int)
                        }
                    }
                    else {
                        print("Lock Mechanism Target State value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Target State value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Lock Mechanism Target State value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Target State: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: lockMechanismTargetState is nil")
            }
        }
    }
    
    /// getLockStateInString will return string equivalent value of DoorLock States.
    /// - Parameter lockState: accept DoorLock state of type Int.
    /// - Returns: Equivalent String value of DoorLock state, It will return "Invalid" if DoorLock state is not one of four specified values.
    public func getLockStateInString(lockState:Int) -> String! {
        switch (lockState) {
        case HMCharacteristicValueLockMechanismState.Unsecured.rawValue:
            print("Lock Mechanism Current State: is Unsecured")
            return "Unsecured/Open"
        case HMCharacteristicValueLockMechanismState.Secured.rawValue:
            print("Lock Mechanism Current State: is Secured")
            return "Secured/Close"
        case HMCharacteristicValueLockMechanismState.Jammed.rawValue:
            print("Lock Mechanism Current State: is Jammed")
            return "Jammed"
        case HMCharacteristicValueLockMechanismState.Unknown.rawValue:
            print("Lock Mechanism Current State: is Unknown")
            return "Unknown"
        default:
            print("Lock Mechanism Current State: is Invalid")
            return "Invalid"
        }
    }
    
    // Mark: - HMAccessoryDelegate protocol
    public func accessoryDidUpdateReachability(accessory: HMAccessory) {
        if accessory.reachable == true {
            print("accessory: \(accessory.name) is reachable")
            if let delegate = delegate {
                delegate.didReceiveLogMessage("\(accessory.name) is reachable")
                delegate.didReceiveAccessoryReachabilityUpdate(accessory)
            }
            homekitAccessory = accessory
            discoverServicesAndCharacteristics()
        }
        else {
            print("accessory: \(accessory.name) is not reachable")
            if let delegate = delegate {
                delegate.didReceiveErrorMessage("\(accessory.name) is not reachable")
            }
        }
    }
}
