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

public class HMErrorCodeMessage {
    
    public class var sharedInstance : HMErrorCodeMessage {
        struct StaticHMErrorCodeMessage {
            static let instance : HMErrorCodeMessage = HMErrorCodeMessage()
        }
        return StaticHMErrorCodeMessage.instance
    }
    
    public func getHMErrorDescription(errorcode: Int) -> String {
        switch (errorcode) {
        case 1:
            return "AlreadyExists"
        case 2:
            return "NotFound"
        case 3:
            return "InvalidParameter"
        case 4:
            return "AccessoryNotReachable"
        case 5:
            return "ReadOnlyCharacteristic"
        case 6:
            return "WriteOnlyCharacteristic"
        case 7:
            return "NotificationNotSupported"
        case 8:
            return "OperationTimedOut"
        case 9:
            return "AccessoryPoweredOff"
        case 10:
            return "AccessDenied"
        case 11:
            return "ObjectAssociatedToAnotherHome"
        case 12:
            return "ObjectNotAssociatedToAnyHome"
        case 13:
            return "ObjectAlreadyAssociatedToHome"
        case 14:
            return "AccessoryIsBusy"
        case 15:
            return "OperationInProgress"
        case 16:
            return "AccessoryOutOfResources"
        case 17:
            return "InsufficientPrivileges"
        case 18:
            return "AccessoryPairingFailed"
        case 19:
            return "InvalidDataFormatSpecified"
        case 20:
            return "NilParameter"
        case 21:
            return "UnconfiguredParameter"
        case 22:
            return "InvalidClass"
        case 23:
            return "OperationCancelled"
        case 24:
            return "RoomForHomeCannotBeInZone"
        case 25:
            return "NoActionsInActionSet"
        case 26:
            return "NoRegisteredActionSets"
        case 27:
            return "MissingParameter"
        case 28:
            return "FireDateInPast"
        case 29:
            return "RoomForHomeCannotBeUpdated"
        case 30:
            return "ActionInAnotherActionSet"
        case 31:
            return "ObjectWithSimilarNameExistsInHome"
        case 32:
            return "HomeWithSimilarNameExists"
        case 33:
            return "RenameWithSimilarName"
        case 34:
            return "CannotRemoveNonBridgeAccessory"
        case 35:
            return "NameContainsProhibitedCharacters"
        case 36:
            return "NameDoesNotStartWithValidCharacters"
        case 37:
            return "UserIDNotEmailAddress"
        case 38:
            return "UserDeclinedAddingUser"
        case 39:
            return "UserDeclinedRemovingUser"
        case 40:
            return "UserDeclinedInvite"
        case 41:
            return "UserManagementFailed"
        case 42:
            return "RecurrenceTooSmall"
        case 43:
            return "InvalidValueType"
        case 44:
            return "ValueLowerThanMinimum"
        case 45:
            return "ValueHigherThanMaximum"
        case 46:
            return "StringLongerThanMaximum"
        case 47:
            return "HomeAccessNotAuthorized"
        case 48:
            return "OperationNotSupported"
        case 49:
            return "MaximumObjectLimitReached"
        case 50:
            return "AccessorySentInvalidResponse"
        case 51:
            return "StringShorterThanMinimum"
        case 52:
            return "GenericError"
        case 53:
            return "SecurityFailure"
        case 54:
            return "CommunicationFailure"
        case 55:
            return "MessageAuthenticationFailed"
        case 56:
            return "InvalidMessageSize"
        case 57:
            return "AccessoryDiscoveryFailed"
        case 58:
            return "ClientRequestError"
        case 59:
            return "AccessoryResponseError"
        case 60:
            return "NameDoesNotEndWithValidCharacters"
        case 61:
            return "AccessoryIsBlocked"
        case 62:
            return "InvalidAssociatedServiceType"
        case 63:
            return "ActionSetExecutionFailed"
        case 64:
            return "ActionSetExecutionPartialSuccess"
        case 65:
            return "ActionSetExecutionInProgress"
        case 66:
            return "AccessoryOutOfCompliance"
        case 67:
            return "DataResetFailure"
        case 68:
            return "NotificationAlreadyEnabled"
        case 69:
            return "RecurrenceMustBeOnSpecifiedBoundaries"
        case 70:
            return "DateMustBeOnSpecifiedBoundaries"
        case 71:
            return "CannotActivateTriggerTooFarInFuture"
        case 72:
            return "RecurrenceTooLarge"
        case 73:
            return "ReadWritePartialSuccess"
        case 74:
            return "ReadWriteFailure"
        case 75:
            return "NotSignedIntoiCloud"
        case 76:
            return "KeychainSyncNotEnabled"
        case 77:
            return "CloudDataSyncInProgress"
        case 78:
            return "NetworkUnavailable"
        case 79:
            return "AddAccessoryFailed"
        case 80:
            return "MissingEntitlement"
        case 81:
            return "CannotUnblockNonBridgeAccessory"
        case 82:
            return "DeviceLocked"
            
        default:
            return "Invalid HMErrorCode"
        }
        
    }
    
}
