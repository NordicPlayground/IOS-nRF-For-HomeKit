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

protocol OutletProtocol {
    func didReceiveState(value: Int)
    func didReceiveInUse(value: Int)
    func didStateChanged(OutletState: Int)
    func didFoundServiceAndCharacteristics(isAllFound: Bool)
    func didReceiveLogMessage(message: String)
    func didReceiveErrorMessage(message: String)
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!)
}

public class Outlet: NSObject, HMAccessoryDelegate {
    var delegate:OutletProtocol?
    private var homekitAccessory: HMAccessory?
    private var isRequiredServiceFound:Bool = false
    
    private var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    private var characteristicName: HMCharacteristicName = HMCharacteristicName()
    private var serviceName: HMServiceName = HMServiceName()
    
    private var outletPowerStateCharacteristic: HMCharacteristic?
    private var outletInUseCharacteristic: HMCharacteristic?
    
    public class var sharedInstance : Outlet {
        struct StaticOutlet {
            static let instance : Outlet = Outlet()
        }
        return StaticOutlet.instance
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
        outletPowerStateCharacteristic = nil
        outletInUseCharacteristic = nil
        homekitAccessory = nil
    }
    
    
    func writeToPowerState(state:Int) {
        if let outletPowerStateCharacteristic = outletPowerStateCharacteristic {
            outletPowerStateCharacteristic.writeValue(state, completionHandler: { (error: NSError?) -> Void in
                if error == nil {
                    print("successfully Outleted state")
                    if let delegate = self.delegate {
                        delegate.didStateChanged(state)
                    }
                }
                else {
                    print("Error in Outleting Outlet state \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Outletstate: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: OutletState  is nil")
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
                if isOutletService(service) {
                    print("Outlet service found")
                    isRequiredServiceFound = true
                }
                discoverCharacteristics(service)
            }
            if isRequiredServiceFound == true && outletPowerStateCharacteristic != nil && outletInUseCharacteristic != nil {
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
    
    private func isOutletService(service: HMService?) -> Bool {
        if let service = service {
            if service.serviceType == HMServiceTypeOutlet {
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
                if isOutletPowerStateCharacteristic(characteristic) {
                    outletPowerStateCharacteristic = characteristic
                }
                else if isOutletInUseCharacteristic(characteristic) {
                    outletInUseCharacteristic = characteristic
                }
            }
        }
        else  {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Service is nil")
            }
        }
    }
    
    private func isOutletPowerStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypePowerState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isOutletInUseCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeOutletInUse {
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
                    delegate.didReceiveLogMessage("Reading Outlet Characteristics values ...")
                }
                readPowerStateValue()
                readInUseValue()
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
        if let outletPowerStateCharacteristic = outletPowerStateCharacteristic {
            outletPowerStateCharacteristic.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got Outlet State value from Outlet \(outletPowerStateCharacteristic.value)")
                    if outletPowerStateCharacteristic.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveState(outletPowerStateCharacteristic.value as! Int)
                        }
                    }
                    else {
                        print("Outlet State value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Outlet State value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Outlet State value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Outlet State: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: OutletState is nil")
            }
        }
    }
    
    private func readInUseValue() {
        if let outletInUseCharacteristic = outletInUseCharacteristic {
            outletInUseCharacteristic.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got OutletInUse value from Outlet \(outletInUseCharacteristic.value)")
                    if outletInUseCharacteristic.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveInUse(outletInUseCharacteristic.value as! Int)
                        }
                    }
                    else {
                        print("OutletInUse value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("OutletInUse value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading Outlet InUse value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading OutletInUse: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: OutletInUse is nil")
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
