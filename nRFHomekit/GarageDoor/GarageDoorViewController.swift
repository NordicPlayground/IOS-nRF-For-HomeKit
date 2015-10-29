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

import UIKit
import HomeKit

class GarageDoorViewController: UIViewController {
    
    var doorAccessoryName: String!
    var isDoorServiceFound:Bool = false
    var isAlertVisible:Bool = false
    var isViewAppeared = true
    var activityTimer = NSTimer()
    var utility = Utility.sharedInstance
    
    var logMessages: Logger = Logger()
    var door:GarageDoor = GarageDoor.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disableDoorControls()
        disableLockControls()
        door.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopActivityAnimation()
        isViewAppeared = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("LightbulbVC: viewWillAppear")
        isViewAppeared = true
    }
    
    @IBOutlet weak var doorTitle: UILabel!
    @IBOutlet weak var doorCurrentState: UILabel!
    @IBOutlet weak var doorObstructionState: UILabel!
    @IBOutlet weak var doorPowerState: UISegmentedControl!
    @IBOutlet weak var lockCurrentState: UILabel!
    @IBOutlet weak var lockPowerState: UISegmentedControl!
    
    @IBAction func doorPowerStateChanged(sender: UISegmentedControl) {
        doorPowerState.enabled = false
        if door.isAccessoryConnected() {
            print("\(doorAccessoryName) is reachable")
            if doorPowerState.selectedSegmentIndex == 0 {
                self.logMessages.addLogText("Openning GaragerDoor ...")
                self.startActivityAnimation("Opening")
            }
            else  {
                self.logMessages.addLogText("Closing GarageDoor ...")
                self.startActivityAnimation("Closing")
            }
            door.writeToDoorTargetState(doorPowerState.selectedSegmentIndex)
        }
        else {
            print("\(doorAccessoryName) is not reachable")
            self.logMessages.addLogText("\(doorAccessoryName) is not reachable")
            clearDoor()
        }

    }
    
    @IBAction func lockPowerStateChanged(sender: UISegmentedControl) {
        lockPowerState.enabled = false
        if door.isAccessoryConnected() {
            print("\(doorAccessoryName) is reachable")
            if lockPowerState.selectedSegmentIndex == 0 {
                self.logMessages.addLogText("Openning Lock ...")
                self.startActivityAnimation("Opening")
            }
            else  {
                self.logMessages.addLogText("Closing Lock ...")
                self.startActivityAnimation("Closing")
            }
            door.writeToLockTargetState(lockPowerState.selectedSegmentIndex)
        }
        else {
            print("\(doorAccessoryName) is not reachable")
            self.logMessages.addLogText("\(doorAccessoryName) is not reachable")
            clearDoor()
        }
 
    }
    
    func clearDoor() {
        doorAccessoryName = nil
        isDoorServiceFound = false
        doorTitle.textColor = UIColor(red: 170.0/255.0, green: 171.0/255.0, blue: 175.0/255.0, alpha: 1.0)
        doorTitle.text = "Device Name"
        doorCurrentState.text = "-"
        doorObstructionState.text = "-"
        disableDoorControls()
        disableLockControls()
    }
    
    func enableDoorControls() {
        doorPowerState.enabled = true
    }
    
    func enableLockControls() {
        lockPowerState.enabled = true
    }
    
    func disableDoorControls() {
        self.stopActivityAnimation()
        doorPowerState.enabled = false
    }
    
    func disableLockControls() {
        lockPowerState.enabled = false
        lockCurrentState.text = "-"
    }
    
    func startActivityAnimation(message: String) {
        // 20 seconds timeout
        utility.displayActivityIndicator(view, msg: message, xOffset: -60, yOffset: 10)
        let delayInSeconds = 20.0
        activityTimer = NSTimer.scheduledTimerWithTimeInterval(delayInSeconds, target: self, selector: Selector("processingTimeout"), userInfo: nil, repeats: false)
    }
    
    func stopActivityAnimation() {
        utility.removeActivityIndicator()
        stopTimer()
    }
    
    func processingTimeout() {
        self.stopActivityAnimation()
        self.showAlert("Time out!. Please Select Device again")
        self.logMessages.addLogText("Time out.")
    }
    
    func stopTimer() {
        activityTimer.invalidate()
    }
    
    func showAlert(message: String) {
        if isViewAppeared {
            utility.showAlert(self, title: "nRF HomeKit", message: message)
        }
    }
    
    func switchLockStatus(status:Int) {
        switch status {
        case HMCharacteristicValueLockMechanismState.Unsecured.rawValue:
            print("Lock status Open Selected")
            lockPowerState.enabled = true
            self.stopActivityAnimation()
            self.logMessages.addLogText("Lock is Open")
            
        case HMCharacteristicValueLockMechanismState.Secured.rawValue:
            print("Lock status Closed Selected")
            lockPowerState.enabled = true
            self.stopActivityAnimation()
            self.logMessages.addLogText("Lock is Close")
            
        default:
            break
        }
    }

    func switchDoorStatus(status:Int) {
        switch status {
        case HMCharacteristicValueDoorState.Open.rawValue:
            print("Door status Open Selected")
            doorPowerState.enabled = true
            self.stopActivityAnimation()
            self.logMessages.addLogText("Door is Open")
            
        case HMCharacteristicValueDoorState.Closed.rawValue:
            print("Door status Closed Selected")
            doorPowerState.enabled = true
            self.stopActivityAnimation()
            self.logMessages.addLogText("Door is Close")
            
        default:
            break
        }
    }
    
    func addNewAccessory(accessory: HMAccessory?) {
        if let accessory = accessory {
            self.startActivityAnimation("Connecting")
            doorAccessoryName = accessory.name
            door.selectedAccessory(accessory)
            door.discoverServicesAndCharacteristics()
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let scanVC = navigationController.topViewController as! SelectAccessoryTableViewController
            scanVC.delegate = self
            scanVC.logMessages = self.logMessages
        }
        else if segue.identifier == "log" {
            let logVC = segue.destinationViewController as! LogTableViewController
            logVC.logMessages = self.logMessages
        }
    }
    
}

extension GarageDoorViewController: GarageDoorProtocol {
    
    func didReceiveDoorTargetState(value: Int) {
        print("didReceiveDoorTargetState \(value)")
        self.logMessages.addLogText("   DoorTargetState value: \(door.getLockStateInString(value))")
        self.doorPowerState.enabled = true
        switch (value) {
        case HMCharacteristicValueDoorState.Open.rawValue:
            self.lockPowerState.selectedSegmentIndex = HMCharacteristicValueDoorState.Open.rawValue
            self.enableDoorControls()
            self.stopActivityAnimation()
        case HMCharacteristicValueDoorState.Closed.rawValue:
            self.lockPowerState.selectedSegmentIndex = HMCharacteristicValueDoorState.Closed.rawValue
            self.enableDoorControls()
            self.stopActivityAnimation()
            
        default:
            break
        }
    }
    
    func didReceiveDoorCurrentState(value: Int) {
        print("didReceiveDoorCurrentState \(value)")
        doorCurrentState.text = door.getDoorStateInString(value)
        self.logMessages.addLogText("    DoorCurrentState value: \(door.getDoorStateInString(value))")
    }
    
    func didReceiveDoorObstructionState(value: Int) {
        print("didReceiveDoorObstructionState \(value)")
        if value == 0 {
            doorObstructionState.text = "NO"
            self.logMessages.addLogText("    Is Obstruction Detected: NO")
        }
        else  {
            self.logMessages.addLogText("    Is Obstruction Detected: YES")
            doorObstructionState.text = "YES"
        }
        
    }
    
    func didReceiveLockTargetState(value: Int) {
        print("didReceiveLockTargetState \(value)")
        self.logMessages.addLogText("   LockTargetState value: \(door.getLockStateInString(value))")
        self.lockPowerState.enabled = true
        switch (value) {
        case HMCharacteristicValueLockMechanismState.Unsecured.rawValue:
            self.lockPowerState.selectedSegmentIndex = HMCharacteristicValueLockMechanismState.Unsecured.rawValue
            self.enableLockControls()
            self.stopActivityAnimation()
        case HMCharacteristicValueLockMechanismState.Secured.rawValue:
            self.lockPowerState.selectedSegmentIndex = HMCharacteristicValueLockMechanismState.Secured.rawValue
            self.enableLockControls()
            self.stopActivityAnimation()
            
        default:
            break
        }

    }
    
    func didReceiveLockCurrentState(value: Int) {
        print("didReceiveLockCurrentState \(value)")
        lockCurrentState.text = door.getLockStateInString(value)
        self.logMessages.addLogText("    LockCurrentState value: \(door.getLockStateInString(value))")

    }
    
    func didLockTargetStateChanged(lockState: Int) {
        print("didLockTargetStateChanged \(lockState)")
        switchLockStatus(lockState)
        door.readLockMechanismCurrentState()
    }
    
    func didDoorTargetStateChanged(doorState: Int) {
        print("didDoorTargetStateChanged \(doorState)")
        switchDoorStatus(doorState)
        door.readDoorCurrentState()
        door.readDoorObstructionState()
    }
    
    
    
    func didFoundServiceAndCharacteristics(isAllFound: Bool) {
        print("didFoundLockServiceAndCharacteristics: \(isAllFound)")
        if isAllFound == true {
            doorTitle.textColor = UIColor.blackColor()
            doorTitle.text = doorAccessoryName
            isDoorServiceFound = true
            door.readValues()
        }
        else {
            logMessages.addLogText("Accessory is not GarageDoor")
            clearDoor()
            showAlert("Accessory is not GarageDoor")
        }
    }
    
    func didReceiveLogMessage(message: String) {
        print("didReceiveLogMessage: \(message)")
        logMessages.addLogText(message)
    }
    
    func didReceiveErrorMessage(message: String) {
        print("didReceiveErrorMessage: \(message)")
        logMessages.addLogText(message)
        self.showAlert(message)
        clearDoor()
    }
    
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!) {
        print("didReceiveAccessoryReachabilityUpdate: \(accessory)")
        addNewAccessory(accessory)
    }
    
}

extension GarageDoorViewController: SelectAccessaryDelegate {
    func selectedAccessary(accessary: HMAccessory!) {
        print("selectedAccessary \(accessary.name)")
        self.logMessages.addLogText("selectedAccessary: \(accessary.name)")
        clearDoor()
        //this delegate is called before viewWillAppear() therefore setting this flag here
        //otherwise Alert box will not appear
        isViewAppeared = true
        addNewAccessory(accessary)
    }
}
