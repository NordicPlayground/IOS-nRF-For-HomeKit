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

///  - protocol: GarageDoorProtocol
///  - The GarageDoorProtocol defines the communication method for state updates from GarageDoor accessory to their delegates.
///
///    overview:
///     set a delegate on a GarageDoor accessory and implement methods in this protocol for updates you are interested in observing to keep your app's UI in sync with changes to GarageDoor accessory's internal state

protocol GarageDoorProtocol {
    
    /// Invoked when GarageDoor TargetState has been read
    /// - Parameter value: the current value of GarageDoor TargetState, 0 for Open and 1 for Closed
    func didReceiveDoorTargetState(value: Int)
    
    /// Invoked when GarageDoor CurrentState has been read
    /// - Parameter value: the current value of GarageDoor CurrentState, 0 for Open, 1 for Closed, 2 for Opening, 3 for Closing and 4 for Stopped
    func didReceiveDoorCurrentState(value: Int)
    
    /// Invoked when GarageDoor ObstructionState has been read
    /// - Parameter value: the current value of GarageDoor ObstructionState, 0 for No Obstruction Detected and 1 for Obstruction Detected
    func didReceiveDoorObstructionState(value: Int)
    
    /// Invoked when GarageDoor TargetState has been written
    /// - Parameter doorState: the current value of GarageDoor TargetState, 0 for Open and 1 for Closed
    func didDoorTargetStateChanged(doorState: Int)
    
    /// Invoked when DoorLock TargetState has been read
    /// - Parameter value: the current value of DoorLock TargetState, 0 for Unsecure and 1 for Secure
    func didReceiveLockTargetState(value: Int)
    
    /// Invoked when DoorLock CurrentState has been read
    /// - Parameter value: the current value of DoorLock CurrentState, 0 for Unsecure, 1 for Secure, 2 for Jammed and 3 for Unknown
    func didReceiveLockCurrentState(value: Int)
    
    /// Invoked when DoorLock TargetState has been written
    /// - Parameter lockState: the current value of DoorLock TargetState, 0 for Unsecure and 1 for Secure
    func didLockTargetStateChanged(lockState: Int)
    
    
    /// Invoked when all services and characteristics are found inside GarageDoor
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

///    - class: GarageDoor
///    - The GarageDoor class implements the logic required to communicate with the GarageDoor accessory.
///
///    overview:
///    set a GarageDoor accessory to function selectedAccessory(accessory: HMAccessory?), discover services and characteristics, readValues and then change the status of UI accordingly. Also you can write to GarageDoor characteristic TargetState to Open or Close the door. In addtion this class also implements Door Lock Service and its characteritsics.
///    - required: the protocol DoorLockProtocol must be implemented in order to receive internal status of DoorLock accessory

public class GarageDoor: NSObject, HMAccessoryDelegate {
    
    var delegate:GarageDoorProtocol?
    private var homekitAccessory: HMAccessory?
    private var isGarageDoorServiceFound:Bool = false
    
    private var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    private var characteristicName: HMCharacteristicName = HMCharacteristicName()
    private var serviceName: HMServiceName = HMServiceName()
    
    private var lockMechanismCurrentState: HMCharacteristic?
    private var lockMechanismTargetState: HMCharacteristic?
    private var doorCurrentState: HMCharacteristic?
    private var doorTargetState: HMCharacteristic?
    private var doorObstructionState: HMCharacteristic?

    /// Singleton implementation that will create only one instance of class GarageDoor
    public class var sharedInstance : GarageDoor {
        struct StaticGarageDoorLock {
            static let instance : GarageDoor = GarageDoor()
        }
        return StaticGarageDoorLock.instance
    }
    
    /// selectedAccessory sets the GarageDoor accessory.
    /// If accessory is nil then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter accessory: it is HomeKit GarageDoor accessory of type HMAccessory.
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
    
    /// isAccessoryConnected rerurns the reachablity status of GarageDoor accessory
    /// - Returns: Bool value, true if GarageDoor accessory is reachable and false otherwise
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
    
    /// writeToDoorTargetState sets the TargetState value of GarageDoor accessory
    /// If an error occurs during write operation then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter doorState: It is Int type value for GarageDoor TargetState, 0 for Open and 1 for Closed
    public func writeToDoorTargetState(doorState:Int) {
        if let doorTargetState = doorTargetState {
            doorTargetState.writeValue(doorState, completionHandler: { (error: NSError?) -> Void in
                if error == nil {
                    print("successfully switched Door state")
                    if let delegate = self.delegate {
                        delegate.didDoorTargetStateChanged(doorState)
                    }
                }
                else {
                    print("Error in switching Door state \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Doorstate: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: DoorTargetState is nil")
            }
        }
    }
    
    /// writeToLockTargetState sets the TargetState value of DoorLock accessory
    /// If an error occurs during write operation then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter lockState: It is Int type value for DoorLock TargetState, 0 for Unsecure and 1 for Secure
    public func writeToLockTargetState(lockState:Int) {
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
            isGarageDoorServiceFound = false
            for service in homekitAccessory.services {
                print("\(homekitAccessory.name) has Service: \(service.name) and ServiceType: \(service.serviceType) and ReadableServiceType: \(serviceName.getServiceType(service.serviceType))")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("\(homekitAccessory.name) has Service: \(serviceName.getServiceType(service.serviceType))")
                }
                if isGarageDoorService(service) {
                    print("GarageDoor service found")
                    isGarageDoorServiceFound = true
                }
                discoverCharacteristics(service)
            }
            if isGarageDoorServiceFound == true && doorCurrentState != nil && doorTargetState != nil {
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
    
    private func isGarageDoorService(service: HMService?) -> Bool {
        if let service = service {
            if service.serviceType == HMServiceTypeGarageDoorOpener {
                return true
            }
            return false
        }
        return false
    }
    
    private func isGarageDoorLockService(service: HMService?) -> Bool {
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
                if isLockCurrentStateCharacteristic(characteristic) {
                    lockMechanismCurrentState = characteristic
                }
                else if isLockTargetStateCharacteristic(characteristic) {
                    lockMechanismTargetState = characteristic
                }
                else if isDoorCurrentStateCharacteristic(characteristic) {
                    doorCurrentState = characteristic
                }
                else if isDoorTargetStateCharacteristic(characteristic) {
                    doorTargetState = characteristic
                }
                else if isDoorObstructionDetectedCharacteristic(characteristic) {
                    doorObstructionState = characteristic
                }
            }
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Service is nil")
            }
        }
    }
    
    private func isLockCurrentStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeCurrentLockMechanismState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isLockTargetStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeTargetLockMechanismState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isDoorCurrentStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeCurrentDoorState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isDoorTargetStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeTargetDoorState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isDoorObstructionDetectedCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeObstructionDetected {
                return true
            }
            return false
        }
        return false
    }

    /// readValues will read values of GarageDoor CurrentState, TargetState and ObstructionState. It also read DoorLock CurrentState and TargetState.
    /// It will call didReceiveDoorCurrentState, didReceiveDoorTargetState, and didReceiveDoorObstructionState, didReceiveLockCurrentState, didReceiveLockTargetState methods of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readValues() {
        if let homekitAccessory = homekitAccessory {
            if isGarageDoorServiceFound && homekitAccessory.reachable {
                print("\(homekitAccessory.name) is reachable")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("Reading GarageDoor Characteristics values ...")
                }
                readDoorCurrentState()
                readDoorTargetState()
                readDoorObstructionState()
                //LockMechanismCurrentState and LockMechanismTargetState are Optional characteristics
                if lockMechanismCurrentState != nil {
                    readLockMechanismCurrentState()
                }
                if lockMechanismTargetState != nil {
                    readLockMechanismTargetState()
                }
                
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
    
    /// readDoorCurrentState will read value of GarageDoor CurrentState.
    /// It will call didReceiveDoorCurrentState method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readDoorCurrentState() {
        if let doorCurrentState = doorCurrentState {
            doorCurrentState.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Door Current State value \(doorCurrentState.value)")
                    if doorCurrentState.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveDoorCurrentState(doorCurrentState.value as! Int)
                        }
                    }
                    else {
                        print("door Current State value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("CurrentDoorState value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Door Mechanism Current State value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Current State: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: DoorCurrentState  is nil")
            }
        }
    }
    
    /// readDoorTargetState will read value of GarageDoor TargetState.
    /// It will call didReceiveDoorTargetState method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readDoorTargetState() {
        if let doorTargetState = doorTargetState {
            doorTargetState.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Door Target State value from Lock \(doorTargetState.value)")
                    if doorTargetState.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveDoorTargetState(doorTargetState.value as! Int)
                        }
                    }
                    else {
                        print("Door Target State value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("DoorTargetState value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading DoorTargetState value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading DoorTargetState: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: doorTargetState is nil")
            }
        }
    }
    
    /// readDoorObstructionState will read value of GarageDoor ObstructionState.
    /// It will call didReceiveDoorObstructionState method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readDoorObstructionState() {
        if let doorObstructionState = doorObstructionState {
            doorObstructionState.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Door Obstruction State value \(doorObstructionState.value)")
                    if doorObstructionState.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveDoorObstructionState(doorObstructionState.value as! Int)
                        }
                    }
                    else {
                        print("Door Obstruction State value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("DoorObstructionState value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading DoorObstructionState value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading DoorObstructionState: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: doorObstructionState is nil")
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
    public func readLockMechanismTargetState() {
        if let lockMechanismTargetState = lockMechanismTargetState {
            lockMechanismTargetState.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got LockTargetState value from Lock \(lockMechanismTargetState.value)")
                    if lockMechanismTargetState.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveLockTargetState(lockMechanismTargetState.value as! Int)
                        }
                    }
                    else {
                        print("LockTargetState value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("LockTargetState value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Lock Mechanism Target State value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading LockTargetState: \(self.errorMessage.getHMErrorDescription(error!.code))")
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
    
    /// getDoorStateInString will return string equivalent value of GarageDoor States.
    /// - Parameter doorState: accept GarageDoor state of type Int.
    /// - Returns: Equivalent String value of GarageDoor state, It will return "Invalid" if GarageDoor state is not one of four specified values.
    public func getDoorStateInString(doorState:Int) -> String! {
        switch (doorState) {
        case HMCharacteristicValueDoorState.Open.rawValue:
            print("Door Current State: is Open")
            return "Open"
        case HMCharacteristicValueDoorState.Closed.rawValue:
            print("Door Current State: is Closed")
            return "Secured/Close"
        case HMCharacteristicValueDoorState.Stopped.rawValue:
            print("Door Current State: is Stopped")
            return "Stopped"
        case HMCharacteristicValueDoorState.Opening.rawValue:
            print("Door Current State: is Opening")
            return "Opening"
        case HMCharacteristicValueDoorState.Closing.rawValue:
            print("Door Current State: is Closing")
            return "Closing"

        default:
            print("Door Current State: is Invalid")
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

