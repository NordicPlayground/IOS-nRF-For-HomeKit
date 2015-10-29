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

class DoorLockViewController: UIViewController {
    
    var lockAccessoryName: String!
    var isLockServiceFound:Bool = false
    var isAlertVisible:Bool = false
    var isViewAppeared = true
    var activityTimer = NSTimer()
    var utility = Utility.sharedInstance
    
    var logMessages: Logger = Logger()
    var lock:DoorLock = DoorLock.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disableLockControls()
        lock.delegate = self
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
    
    @IBOutlet weak var lockTitleLabel: UILabel!
    @IBOutlet weak var lockSegmentedControl: UISegmentedControl!
    @IBOutlet weak var lockCurrentStateValueLabel: UILabel!

    @IBAction func lockStatusChanged(sender: UISegmentedControl) {
        lockSegmentedControl.enabled = false
        if lock.isAccessoryConnected() {
            print("\(lockAccessoryName) is reachable")
            if lockSegmentedControl.selectedSegmentIndex == 0 {
                self.logMessages.addLogText("Openning Door Lock ...")
                startActivityAnimation("Opening")
            }
            else  {
                self.logMessages.addLogText("Closing Door Lock ...")
                startActivityAnimation("Closing")
            }
            lock.writeToTargetState(lockSegmentedControl.selectedSegmentIndex)
        }
        else {
            print("\(lockAccessoryName) is not reachable")
            self.logMessages.addLogText("\(lockAccessoryName) is not reachable")
            clearLock()
        }
    }
    
    func switchLockStatus(status:Int) {
        switch status {
        case HMCharacteristicValueLockMechanismState.Unsecured.rawValue:
            print("Door Lock status Open Selected")
            lockSegmentedControl.enabled = true
            self.stopActivityAnimation()
            self.logMessages.addLogText("Door Lock is Open")
            
        case HMCharacteristicValueLockMechanismState.Secured.rawValue:
            print("Door Lock status Closed Selected")
            lockSegmentedControl.enabled = true
            self.stopActivityAnimation()
            self.logMessages.addLogText("Door Lock is Close")
            
        default:
            break
        }
    }
    
    func clearLock() {
        lockAccessoryName = nil
        isLockServiceFound = false
        lockTitleLabel.textColor = UIColor(red: 170.0/255.0, green: 171.0/255.0, blue: 175.0/255.0, alpha: 1.0)
        lockTitleLabel.text = "Device Name"
        lockCurrentStateValueLabel.text = "-"
        disableLockControls()
        
    }

    func enableLockControls() {
        lockSegmentedControl.enabled = true
    }
    
    func disableLockControls() {
        self.stopActivityAnimation()
        lockSegmentedControl.enabled = false
    }
    
    func startActivityAnimation(message: String) {
        // 20 seconds timeout
        utility.displayActivityIndicator(view, msg: message, xOffset: -60, yOffset: -50)
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

    func addNewAccessory(accessory: HMAccessory?) {
        if let accessory = accessory {
            self.startActivityAnimation("Connecting")
            lockAccessoryName = accessory.name
            lock.selectedAccessory(accessory)
            lock.discoverServicesAndCharacteristics()
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let selectAccessoryVC = navigationController.topViewController as! SelectAccessoryTableViewController
            selectAccessoryVC.delegate = self
            selectAccessoryVC.logMessages = self.logMessages
        }
        else if segue.identifier == "log" {
            let logVC = segue.destinationViewController as! LogTableViewController
            logVC.logMessages = self.logMessages
        }
    }
    
}

extension DoorLockViewController: DoorLockProtocol {
    
    func didReceiveLockTargetState(value: Int) {
        print("didReceiveLockTargetState \(value)")
        self.logMessages.addLogText("   LockTargetState value: \(lock.getLockStateInString(value))")
        self.lockSegmentedControl.enabled = true
        switch (value) {
        case HMCharacteristicValueLockMechanismState.Unsecured.rawValue:
            self.lockSegmentedControl.selectedSegmentIndex = HMCharacteristicValueLockMechanismState.Unsecured.rawValue
            self.enableLockControls()
            self.stopActivityAnimation()
        case HMCharacteristicValueLockMechanismState.Secured.rawValue:
            self.lockSegmentedControl.selectedSegmentIndex = HMCharacteristicValueLockMechanismState.Secured.rawValue
            self.enableLockControls()
            self.stopActivityAnimation()
            
        default:
            break
        }
    }
    
    func didReceiveLockCurrentState(value: Int) {
        print("didReceiveLockCurrentState \(value)")
        lockCurrentStateValueLabel.text = lock.getLockStateInString(value)
        self.logMessages.addLogText("    LockCurrentState value: \(lock.getLockStateInString(value))")
    }
    
    func didLockTargetStateChanged(lockState: Int) {
        print("didLockTargetStateChanged \(lockState)")
        switchLockStatus(lockState)
        lock.readLockMechanismCurrentState()
    }
    
    func didFoundServiceAndCharacteristics(isAllFound: Bool) {
        print("didFoundLockServiceAndCharacteristics: \(isAllFound)")
        if isAllFound == true {
            lockTitleLabel.textColor = UIColor.blackColor()
            lockTitleLabel.text = lockAccessoryName
            isLockServiceFound = true
            lock.readValues()
        }
        else {
            logMessages.addLogText("Accessory is not Door Lock")
            clearLock()
            showAlert("Accessory is not Door Lock")
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
        clearLock()
    }
    
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!) {
        print("didReceiveAccessoryReachabilityUpdate: \(accessory)")
        addNewAccessory(accessory)
    }

}

extension DoorLockViewController: SelectAccessaryDelegate {
    func selectedAccessary(accessary: HMAccessory!) {
        print("selectedAccessary \(accessary.name)")
        self.logMessages.addLogText("selectedAccessary: \(accessary.name)")
        clearLock()
        //this delegate is called before viewWillAppear() therefore setting this flag here
        //otherwise Alert box will not appear
        isViewAppeared = true
        addNewAccessory(accessary)
    }
}
