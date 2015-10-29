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

///  - protocol: LightbulbProtocol
///  - The LightbulbProtocol defines the communication method for state updates from Lightbulb accessory to their delegates.
///
///    overview:
///     set a delegate on a lightbulb accessory and implement methods in this protocol for updates you are interested in observing to keep your app's UI in sync with changes to lightbulb  accessory's internal state

protocol LightbulbProtocol {
    /// Invoked when lightbulb brightness has been read
    /// - Parameter value: the current value of lightbulb birightness, ranges from 0 to 100
    func didReceiveBrightness(value: Int)
    
    /// Invoked when lightbulb hue has been read
    /// - Parameter value: the current value of lightbulb hue, ranges from 0 to 360
    func didReceiveHue(value: Int)
    
    /// Invoked when lightbulb saturation has been read
    /// - Parameter value: the current value of lightbulb saturation, ranges from 0 to 100
    func didReceiveSaturation(value: Int)
    
    /// Invoked when lightbulb powerstate has been read
    /// - Parameter value: the current value of lightbulb powerstate, 0 for OFF and 1 for ON
    func didReceivePowerState(value: Int)
    
    /// Invoked when lightbulb powerstate has been written
    /// - Parameter powerState: the current value of lightbulb powerstate, 0 for OFF and 1 for ON
    func didPowerStateChanged(powerState: Int)
    
    
    /// Invoked when all services and characteristics are found inside lightbulb
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


///    - class: Lightbulb
///    - The Lightbulb class implements the logic required to communicate with the Lightbulb accessory.
///
///    overview:
///    set a lightbulb accessory to function selectedAccessory(accessory: HMAccessory?), discover services and characteristics, readValues and then change the status of UI accordingly. Also you can write to lightbulb characteristics (brightness, powerlevel, hue and saturation) to change their values
///    - required: the protocol LightbulbProtocol must be implemented in order to receive internal status of Lightbulb accessory


public class Lightbulb: NSObject, HMAccessoryDelegate {
    
    var delegate:LightbulbProtocol?
    private var isLightbulbServiceFound:Bool = false
    
    private var characteristicName: HMCharacteristicName = HMCharacteristicName()
    private var serviceName: HMServiceName = HMServiceName()
    private var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    
    private var homekitAccessory: HMAccessory?
    
    private var lightbulbBrightness: HMCharacteristic?
    private var lightbulbHue: HMCharacteristic?
    private var lightbulbSaturation: HMCharacteristic?
    private var lightbulbPowerState: HMCharacteristic?
    
    /// Singleton implementation that will create only one instance of class Lightbulb
    public class var sharedInstance : Lightbulb {
        struct StaticLightbulb {
            static let instance : Lightbulb = Lightbulb()
        }
        return StaticLightbulb.instance
    }
    
    /// selectedAccessory sets the lightbulb accessory.
    /// If accessory is nil then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter accessory: it is HomeKit Lightbulb accessory of type HMAccessory
    public func selectedAccessory(accessory: HMAccessory?) {
        if let accessory = accessory {
            homekitAccessory = accessory
            homekitAccessory!.delegate = self
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Accessory is nil")
            }
        }
    }
    
    /// isAccessoryConnected rerurns the reachablity status of lightbulb accessory 
    /// - Returns: Bool value, true if lightbulb accessory is reachable and false otherwise   
    public func isAccessoryConnected() -> Bool {
        if let homekitAccessory = homekitAccessory {
            return homekitAccessory.reachable
        }
        return false
    }
    
    private func clearAccessory() {
        homekitAccessory = nil
        lightbulbBrightness = nil
        lightbulbHue = nil
        lightbulbSaturation = nil
        lightbulbPowerState = nil
    }
    
    /// writeToBrightness sets the brightness value of lightbulb accessory
    /// If an error occurs during write operation then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter brightnessValue: It is Int type value for lightbulb brightness and it ranges from 0 to 100
    public func writeToBrightness(brightnessValue: Int) {
        if let lightbulbBrightness = lightbulbBrightness {
            lightbulbBrightness.writeValue(brightnessValue, completionHandler: { (error: NSError?) -> Void in
                if error != nil {
                    print("Error in writing brightness value in lightbulb \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Brightness: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
                else {
                    print("Brightness value changed successfully")
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Brightness is nil")
            }
        }
    }
    
    /// writeToHue sets the hue value of lightbulb accessory
    /// If an error occurs during write operation then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter hueValue: It is Int type value for lightbulb hue and it ranges from 0 to 360
    public func writeToHue(hueValue: Int) {
        if let lightbulbHue = lightbulbHue {
            lightbulbHue.writeValue(hueValue, completionHandler: { (error: NSError?) -> Void in
                if error != nil {
                    print("Error in writting hue value in lightbulb \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Hue: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
                else {
                    print("changed Hue successfully")
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Hue is nil")
            }
        }
    }
    
    /// writeToSaturation sets the saturation value of lightbulb accessory
    /// If an error occurs during write operation then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter saturationValue: It is Int type value for lightbulb hue and it ranges from 0 to 100
    public func writeToSaturation(saturationValue: Int) {
        if let lightbulbSaturation = lightbulbSaturation {
            lightbulbSaturation.writeValue(saturationValue, completionHandler: { (error: NSError?) -> Void in
                if error != nil {
                    print("Error in writting saturation value in lightbulb \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Saturation: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
                else {
                    print("changed Saturation successfully")
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Saturation is nil")
            }
        }
    }
    
    /// writeToPowerState sets the powerstate value of lightbulb accessory.
    /// If value is written successfully then it will call didPowerStateChanged method of its delegate object.
    /// If an error occurs during write operation then it will call didReceiveErrorMessage method of its delegate object.
    /// - Parameter powerStateValue: It is Int type value for lightbulb powerstate, 0 for OFF and 1 for ON.
    public func writeToPowerState(powerStateValue: Int) {
        if let lightbulbPowerState = lightbulbPowerState {
            lightbulbPowerState.writeValue(powerStateValue, completionHandler: { (error: NSError?) -> Void in
                if error == nil {
                    print("successfully switched power state of lightbulb")
                    if let delegate = self.delegate {
                        delegate.didPowerStateChanged(powerStateValue)
                    }
                }
                else {
                    print("Error in switching power state of lightbulb \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error writing Powerstate: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: PowerState is nil")
            }
        }
    }
    
    /// discoverServicesAndCharacteristics finds all services and characteristics inside homekit accessory.
    /// After search of services and characteristics, It calls the didFoundServiceAndCharacteristics: method of its delegate object.
    /// if required services and characteristics are found then parameter of didFoundServiceAndCharacteristics is set to true or false otherwise
    /// It also calls didReceiveLogMessage method and can call didReceiveErrorMessage method of its delegate object.
    public func discoverServicesAndCharacteristics() {
        if let homekitAccessory = homekitAccessory {
            isLightbulbServiceFound = false
            for service in homekitAccessory.services {
                print("\(homekitAccessory.name) has Service: \(service.name) and ServiceType: \(service.serviceType) and ReadableServiceType: \(serviceName.getServiceType(service.serviceType))")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("\(homekitAccessory.name) has Service: \(serviceName.getServiceType(service.serviceType))")
                }
                
                if isLightBulbService(service) {
                    print("Lightbulb service found")
                    isLightbulbServiceFound = true
                }
                discoverCharacteristics(service)
            }
            if isLightbulbServiceFound == true && lightbulbPowerState != nil && lightbulbBrightness != nil && lightbulbHue != nil && lightbulbSaturation != nil {
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
    
    private func discoverCharacteristics(service: HMService?) {
        if let service = service  {
            for characteristic in service.characteristics {
                print("Service: \(service.name) has characteristicType: \(characteristic.characteristicType) and ReadableCharType: \(characteristicName.getCharacteristicType(characteristic.characteristicType))")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("    characteristic: \(characteristicName.getCharacteristicType(characteristic.characteristicType))")
                }
                if isPowerStateCharacteristic(characteristic) {
                    
                    lightbulbPowerState = characteristic
                }
                else if isBrightnessCharacteristic(characteristic) {
                    lightbulbBrightness = characteristic
                }
                else if isHueCharacteristic(characteristic) {
                    lightbulbHue = characteristic
                }
                else if isSaturationCharacteristic(characteristic) {
                    lightbulbSaturation = characteristic
                }
            }
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Service is nil")
            }
        }
    }
    
    private func isPowerStateCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypePowerState {
                return true
            }
            return false
        }
        return false
    }
    
    private func isBrightnessCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeBrightness {
                return true
            }
            return false
        }
        return false
    }
    
    private func isHueCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeHue {
                return true
            }
            return false
        }
        return false
    }
    
    private func isSaturationCharacteristic(characteristic: HMCharacteristic?) -> Bool {
        if let characteristic = characteristic {
            if characteristic.characteristicType == HMCharacteristicTypeSaturation {
                return true
            }
            return false
        }
        return false
    }
    
    private func isLightBulbService(service: HMService?) -> Bool {
        if let service = service {
            if service.serviceType == HMServiceTypeLightbulb {
                return true
            }
            return false
        }
        return false
    }
    
    /// readValues will read values of lightbulb brightness, hue, saturation and powerstate.
    /// It will call didReceiveBrightness, didReceiveHue, didReceiveSaturation, and didReceivePowerState methods of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readValues() {
        if let homekitAccessory = homekitAccessory {
            if isAccessoryConnected() {
                print("\(homekitAccessory.name) is reachable")
                if let delegate = delegate {
                    delegate.didReceiveLogMessage("Reading Lightbulb Characteristics values ...")
                }
                readBrightnessValue()
                readHueValue()
                readSaturationValue()
                readPowerStateValue()
            }
            else {
                print("Accessory is not reachable")
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
    
    /// readBrightnessValue will read value of lightbulb brightness.
    /// It will call didReceiveBrightness method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readBrightnessValue() {
        if let lightbulbBrightness = lightbulbBrightness {
            lightbulbBrightness.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got brightness value from lightbulb \(lightbulbBrightness.value)")
                    if lightbulbBrightness.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveBrightness(lightbulbBrightness.value as! Int)
                        }
                    }
                    else {
                        print("Brightness value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Brightness value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading brightness value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Brightness: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Brigtness  is nil")
            }
        }
    }
    
    /// readHueValue will read value of lightbulb hue.
    /// It will call didReceiveHue method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readHueValue() {
        if let lightbulbHue = lightbulbHue {
            lightbulbHue.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got hue value from lightbulb \(lightbulbHue.value)")
                    if lightbulbHue.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveHue(lightbulbHue.value as! Int)
                        }
                    }
                    else {
                        print("Hue value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Hue value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading hue value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Hue: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Hue is nil")
            }
        }
    }
    
    /// readSaturationValue will read value of lightbulb saturation.
    /// It will call didReceiveSaturation method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readSaturationValue() {
        if let lightbulbSaturation = lightbulbSaturation {
            lightbulbSaturation.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got saturation value from lightbulb \(lightbulbSaturation.value)")
                    if lightbulbSaturation.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceiveSaturation(lightbulbSaturation.value as! Int)
                        }
                    }
                    else {
                        print("Saturation value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Saturation value is nil")
                        }
                        self.clearAccessory()
                    }
                }
                else {
                    print("Error in Reading saturation value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Saturation: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: Saturation  is nil")
            }
        }
    }
    
    /// readPowerStateValue will read value of lightbulb powerstate.
    /// It will call didReceivePowerState method of its delegate object.
    /// If an error occurs during read operation then it will call didReceiveErrorMessage method of its delegate object.
    public func readPowerStateValue() {
        if let lightbulbPowerState = lightbulbPowerState {
            lightbulbPowerState.readValueWithCompletionHandler({ (error: NSError?) -> Void in
                if error == nil {
                    print("Got powerstate value from lightbulb \(lightbulbPowerState.value)")
                    if lightbulbPowerState.value != nil {
                        if let delegate = self.delegate {
                            delegate.didReceivePowerState(lightbulbPowerState.value as! Int)
                        }
                    }
                    else {
                        print("Powerstate value is nil")
                        if let delegate = self.delegate {
                            delegate.didReceiveErrorMessage("Powerstate value is nil")
                        }
                        self.clearAccessory()
                    }
                    
                }
                else {
                    print("Error in Reading powerstate value \(self.errorMessage.getHMErrorDescription(error!.code))")
                    if let delegate = self.delegate {
                        delegate.didReceiveErrorMessage("Error reading Powerstate: \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.clearAccessory()
                }
            })
        }
        else {
            if let delegate = self.delegate {
                delegate.didReceiveErrorMessage("Characteristic: PowerState is nil")
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
        }
        else {
            print("accessory: \(accessory.name) is not reachable")
            if let delegate = delegate {
                delegate.didReceiveErrorMessage("\(accessory.name) is not reachable")
            }
        }
    }

}