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

protocol FanProtocol {
    func didReceiveRotationDirection(value: Int)
    func didReceiveRotationSpeed(value: Int)
    func didReceivePowerState(value: Int)
    func didPowerStateChanged(powerState: Int)
    func didRotationDirectionChanged(value: Int)
    func didFoundServiceAndCharacteristics(isAllFound: Bool)
    func didReceiveLogMessage(message: String)
    func didReceiveErrorMessage(message: String)
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!)    
}

public class Fan: NSObject, HMAccessoryDelegate {
    
    var delegate:FanProtocol?
    private var homekitAccessory: HMAccessory?
    private var isRequiredServiceFound:Bool = false
    
    private var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    private var characteristicName: HMCharacteristicName = HMCharacteristicName()
    private var serviceName: HMServiceName = HMServiceName()
    
    private var fanPowerStateCharacteristic: HMCharacteristic?
    private var fanRotationDirectionCharacteristic: HMCharacteristic?
    private var fanRotationSpeedCharacteristic: HMCharacteristic?
    
    public class var sharedInstance : Fan {
        struct StaticFan {
            static let instance : Fan = Fan()
        }
        return StaticFan.instance
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
        fanPowerStateCharacteristic = nil
        fanRotationDirectionCharacteristic = nil
        fanRotationSpeedCharacteristic = nil
        homekitAccessory = nil
    }
    
    
    func writeToPowerState(state:Int) {
        if let fanPowerStateCharacteristic = fanPowerStateCharacteristic {
            fanPowerStateCharacteristic.writeValue(state, completionHandler: { (error: NSError?) -> Void in
                if error == nil {
                    print("successfully changed PowerState")
                    if let delegate = self.delegate {
                        delegate.didPowerStateChanged(state)
                    }
                }
                else {
                    print("Error in changing Fan PowerState \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Fan PowerState: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Fan PowerState  is nil")
            }
        }
    }
    
    func writeToRotationDirection(state:Int) {
        if let fanRotationDirectionCharacteristic = fanRotationDirectionCharacteristic {
            fanRotationDirectionCharacteristic.writeValue(state, completionHandler: { (error: NSError?) -> Void in
                if error == nil {
                    print("successfully changed RotationDirection")
                    if let delegate = self.delegate {
                        delegate.didRotationDirectionChanged(state)
                    }
                }
                else {
                    print("Error in changing Fan RotationDirection \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Fan RotationDirection: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Fan RotationDirection is nil")
            }
        }
    }
    
    func writeToRotationSpeed(value:Int) {
        if let fanRotationSpeedCharacteristic = fanRotationSpeedCharacteristic {
            fanRotationSpeedCharacteristic.writeValue(value, completionHandler: { (error: NSError?) -> Void in
                if error != nil {
                    print("Error in writing Fan RotationSpeed \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Fan RotationSpeed: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Fan RotationSpeed is nil")
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
                if isFanService(service) {
                    print("Fan service found")
                    isRequiredServiceFound = true
                }
                discoverCharacteristics(service)
            }
            if isRequiredServiceFound == true && fanPowerStateCharacteristic != nil && fanRotationDirectionCharacteristic != nil && fanRotationSpeedCharacteristic != nil {
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
    
    private func isFanService(service: HMService?) -> Bool {
        if let service = service {
            if service.serviceType == HMServiceTypeFan {
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
                if isFanPowerStateCharacteristic(characteristic) {
                    fanPowerStateCharacteristic = characteristic
                }
                else if isFanRotationDirectionCharacteristic(characteristic) {
                    fanRotationDirectionCharacteristic = characteristic
                }
                else if isFanRotationSpeedCharacteristic(characteristic) {
                    fanRotationSpeedCharacteristic = characteristic
                }
            }
        }
        else  {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Service is nil")
            }
        }
    }
    
    private func isFanPowerStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypePowerState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isFanRotationDirectionCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeRotationDirection {
                return true
            }
            return false
        }
        return false
    }
    
    private func isFanRotationSpeedCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeRotationSpeed {
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
                    delegate.didReceiveLogMessage("Reading Fan Characteristics values ...")
                }
                readPowerStateValue()
                readRotationDirectionValue()
                readRotationSpeedValue()
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
        if let fanPowerStateCharacteristic = fanPowerStateCharacteristic {
            fanPowerStateCharacteristic.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Fan PowerState value from Fan \(fanPowerStateCharacteristic.value)")
                    if fanPowerStateCharacteristic.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceivePowerState(fanPowerStateCharacteristic.value as! Int)
                        }
                    }
                    else {
                        print("Fan PowerState value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Fan PowerState value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Fan Power State value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Fan PowerState: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Fan PowerState is nil")
            }
        }
    }
    
    private func readRotationDirectionValue() {
        if let fanRotationDirectionCharacteristic = fanRotationDirectionCharacteristic {
            fanRotationDirectionCharacteristic.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got FanInUse value from Fan \(fanRotationDirectionCharacteristic.value)")
                    if fanRotationDirectionCharacteristic.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveRotationDirection(fanRotationDirectionCharacteristic.value as! Int)
                        }
                    }
                    else {
                        print("FanInUse value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Fan RotationDirection value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Fan RotationDirection value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Fan RotationDirection: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Fan RotationDirection is nil")
            }
        }
    }
    
    private func readRotationSpeedValue() {
        if let fanRotationSpeedCharacteristic = fanRotationSpeedCharacteristic {
            fanRotationSpeedCharacteristic.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Fan RotationSpeed value from Fan \(fanRotationSpeedCharacteristic.value)")
                    if fanRotationSpeedCharacteristic.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveRotationSpeed(fanRotationSpeedCharacteristic.value as! Int)
                        }
                    }
                    else {
                        print("Fan RotationSpeed value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Fan RotationSpeed value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Fan RotationSpeed value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Fan RotationSpeed: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Fan RotationSpeed is nil")
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