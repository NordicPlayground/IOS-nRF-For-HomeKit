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

protocol HomeKitManagerDelegate {
    func didAddedNewHome()
    func didReceiveError(error: NSError!)
    func didSetPrimaryHome()
    func didUpdateHomeName()
    func didRemoveHome()
    func didInitializedHomeManager()
}

class HomeKitManager: NSObject, HMHomeManagerDelegate {
    
    var myHMManager: HMHomeManager!
    var myHome: HMHome!
    var myRooms: [HMRoom]!
    
    var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    var delegate:HomeKitManagerDelegate?
    
    override init() {
        super.init()
        initHomeManager()
    }
    
    func initHomeManager() {
        myHMManager = HMHomeManager()
        myHMManager.delegate = self
    }
    
    //this delegate method is called once HMHomeManager() is initialized
    func homeManagerDidUpdateHomes(manager: HMHomeManager) {
        print("homeManagerDidUpdateHomes")
        myHMManager = manager
        if let delegate = self.delegate {
            delegate.didInitializedHomeManager()
        }
    }
    
    func getAllHomes() -> [HMHome] {
        return myHMManager.homes
    }
    
    func getPrimaryHome() -> HMHome? {
        if myHMManager.primaryHome != nil {
            return myHMManager.primaryHome!
        }
        return nil
    }
    
    func isPrimaryHome(home: HMHome!) -> Bool {
        if home != nil {
            if home == getPrimaryHome() {
                return true
            }
            return false
        }
        return false
    }
    
    func setPrimaryHome(primaryHome: HMHome) {
        myHMManager.updatePrimaryHome(primaryHome, completionHandler: { (error:NSError?) -> Void in
            if error != nil {
                if let delegate = self.delegate {
                    delegate.didReceiveError(error)
                }
            }
            else {
                // Primary home updated successfully
                if let delegate = self.delegate {
                    delegate.didSetPrimaryHome()
                }
            }
        })
    }
    
    func updateHomeName(home:HMHome, name:String) {
        home.updateName(name) { (error: NSError?) -> Void in
            if error != nil {
                if let delegate = self.delegate {
                    delegate.didReceiveError(error)
                }
            }
            else {
                // Home name is updated successfully
                if let delegate = self.delegate {
                    delegate.didUpdateHomeName()
                }
            }
        }
    }
    
    func removeHome(home: HMHome) {
        myHMManager.removeHome(home) { (error: NSError?) -> Void in
            if error != nil {
                if let delegate = self.delegate {
                    delegate.didReceiveError(error)
                }
            }
            else {
                // Home is removed successfully
                if let delegate = self.delegate {
                    delegate.didRemoveHome()
                }
            }
        }
    }
    
    func addNewHome(name: String) {
        myHMManager.addHomeWithName(name, completionHandler: { (home:HMHome?, error:NSError?) -> Void in
            if error != nil {
                print("Error in adding Home \(self.errorMessage.getHMErrorDescription(error!.code))")
                if let delegate = self.delegate {
                    delegate.didReceiveError(error)
                }
            }
            else {
                print("Added Home successfully")
                if home != nil {
                    self.myHome = home
                    print("Created home: \(self.myHome.name)")
                    if let delegate = self.delegate {
                        delegate.didAddedNewHome()
                    }
                }
                else {
                    print("created home is nil")
                }
            }
        })
    }

}
