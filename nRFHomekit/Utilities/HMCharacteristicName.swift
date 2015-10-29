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

public class HMCharacteristicName {
    
    public class var sharedInstance : HMCharacteristicName {
        struct StaticHMCharacteristicName {
            static let instance : HMCharacteristicName = HMCharacteristicName()
        }
        return StaticHMCharacteristicName.instance
    }
    
    public func getCharacteristicType(type: String!) -> String {
        switch(type) {
        case HMCharacteristicTypePowerState:
            return "PowerState"
        case HMCharacteristicTypeHue:
            return "Hue"
        case HMCharacteristicTypeSaturation:
            return "Saturation"
        case HMCharacteristicTypeBrightness:
            return "Brightness"
        case HMCharacteristicTypeTemperatureUnits:
            return "TemperatureUnits"
        case HMCharacteristicTypeCurrentTemperature:
            return "CurrentTemperature"
        case HMCharacteristicTypeTargetTemperature:
            return "TargetTemperature"
        case HMCharacteristicTypeCurrentHeatingCooling:
            return "CurrentHeatingCooling"
        case HMCharacteristicTypeTargetHeatingCooling:
            return "TargetHeatingCooling"
        case HMCharacteristicTypeCoolingThreshold:
            return "CoolingThreshold"
        case HMCharacteristicTypeHeatingThreshold:
            return "HeatingThreshold"
        case HMCharacteristicTypeCurrentRelativeHumidity:
            return "CurrentRelativeHumidity"
        case HMCharacteristicTypeTargetRelativeHumidity:
            return "TargetRelativeHumidity"
        case HMCharacteristicTypeCurrentDoorState:
            return "CurrentDoorState"
        case HMCharacteristicTypeTargetDoorState:
            return "TargetDoorState"
        case HMCharacteristicTypeObstructionDetected:
            return "ObstructionDetected"
        case HMCharacteristicTypeName:
            return "Name"
        case HMCharacteristicTypeManufacturer:
            return "Manufacturer"
        case HMCharacteristicTypeModel:
            return "Model"
        case HMCharacteristicTypeSerialNumber:
            return "SerialNumber"
        case HMCharacteristicTypeIdentify:
            return "Identity"
        case HMCharacteristicTypeRotationDirection:
            return "RotationDirection"
        case HMCharacteristicTypeRotationSpeed:
            return "RotationSpeed"
        case HMCharacteristicTypeOutletInUse:
            return "OutletInUse"
        case HMCharacteristicTypeVersion:
            return "Version"
        case HMCharacteristicTypeLogs:
            return "Logs"
        case HMCharacteristicTypeAudioFeedback:
            return "AudioFeedback"
        case HMCharacteristicTypeAdminOnlyAccess:
            return "AdminOnlyAccess"
        case HMCharacteristicTypeMotionDetected:
            return "MotionDetected"
        case HMCharacteristicTypeCurrentLockMechanismState:
            return "CurrentLockMechanismState"
        case HMCharacteristicTypeTargetLockMechanismState:
            return "TargetLockMechanismState"
        case HMCharacteristicTypeLockMechanismLastKnownAction:
            return "LockMechanismLastKnownAction"
        case HMCharacteristicTypeLockManagementControlPoint:
            return "LockManagementControlPoint"
        case HMCharacteristicTypeLockManagementAutoSecureTimeout:
            return "LockManagementAutoSecureTimeout"
            
        default:
            return "Custom"
        }
    }

    
}
