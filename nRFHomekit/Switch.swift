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

protocol SwitchProtocol {
    func didReceiveState(value: Int)
    func didStateChanged(switchState: Int)
    func didFoundServiceAndCharacteristics(isAllFound: Bool)
    func didReceiveLogMessage(message: String)
    func didReceiveErrorMessage(message: String)
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!)
}


public class Switch: NSObject, HMAccessoryDelegate {
    var delegate:SwitchProtocol?
    private var homekitAccessory: HMAccessory?
    private var isRequiredServiceFound:Bool = false
    
    private var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    private var characteristicName: HMCharacteristicName = HMCharacteristicName()
    private var serviceName: HMServiceName = HMServiceName()
    
    private var switchPowerStateCharacteristic: HMCharacteristic?
    
    public class var sharedInstance : Switch {
        struct StaticSwitch {
            static let instance : Switch = Switch()
        }
        return StaticSwitch.instance
    }
    
    func selectedAccessory(accessory: HMAccessory?) {
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
    
    func isAccessoryConnected() -> Bool {
        if let homekitAccessory = homekitAccessory {
            return homekitAccessory.reachable
        }
        return false
    }
    
    private func clearAccessory() {
        switchPowerStateCharacteristic = nil
        homekitAccessory = nil
    }
    
    
    func writeToPowerState(state:Int) {
        if let switchPowerStateCharacteristic = switchPowerStateCharacteristic {
            switchPowerStateCharacteristic.writeValue(state, completionHandler: { (error: NSError?) -> Void in
                if error == nil {
                    print("successfully switched state")
                    if let delegate = self.delegate {
                        delegate.didStateChanged(state)
                    }
                }
                else {
                    print("Error in switching Switch state \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing switchstate: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: SwitchState  is nil")
            }
        }
    }
    
    func discoverServicesAndCharacteristics() {
        if let homekitAccessory = homekitAccessory {
            isRequiredServiceFound = false
            for service in homekitAccessory.services {
                print("\(homekitAccessory.name) has Service: \(service.name) and ServiceType: \(service.serviceType) and ReadableServiceType: \(serviceName.getServiceType(service.serviceType))")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("\(homekitAccessory.name) has Service: \(serviceName.getServiceType(service.serviceType))")
                }
                if isSwitchService(service) {
                    print("Switch service found")
                    isRequiredServiceFound = true
                }
                discoverCharacteristics(service)
            }
            if isRequiredServiceFound == true && switchPowerStateCharacteristic != nil {
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
    
    private func isSwitchService(service: HMService?) -> Bool {
        if let service = service {
            if service.serviceType == HMServiceTypeSwitch {
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
                if isSwitchPowerStateCharacteristic(characteristic) {
                    switchPowerStateCharacteristic = characteristic
                }
            }
        }
        else  {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Service is nil")
            }
        }
    }
    
    private func isSwitchPowerStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypePowerState {
                return true
            }
            return false
        }
        return false
    }
    
    func readValues() {
        if let homekitAccessory = homekitAccessory {
            if isRequiredServiceFound && homekitAccessory.reachable {
                print("\(homekitAccessory.name) is reachable")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("Reading Switch Characteristics values ...")
                }
                readPowerStateValue()
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
    
    private func readPowerStateValue() {
        if let switchPowerStateCharacteristic = switchPowerStateCharacteristic {
            switchPowerStateCharacteristic.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Switch State value from switch \(switchPowerStateCharacteristic.value)")
                    if switchPowerStateCharacteristic.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveState(switchPowerStateCharacteristic.value as! Int)
                        }
                    }
                    else {
                        print("Switch State value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Switch State value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Switch State value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Switch State: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: SwitchState is nil")
            }
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
