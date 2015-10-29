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

class SwitchViewController: UIViewController {
    
    var switchAccessoryName: String!
    var isSwitchServiceFound:Bool = false
    var isAlertVisible:Bool = false
    var isViewAppeared = true
    var activityTimer = NSTimer()
    var utility = Utility.sharedInstance
    
    var logMessages: Logger = Logger()
    var switchInstance:Switch = Switch.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disableSwitchControls()
        switchInstance.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopActivityAnimation()
        isViewAppeared = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        isViewAppeared = true
    }

    
    @IBOutlet weak var switchTitle: UILabel!
    @IBOutlet weak var switchStateSegmentedControl: UISegmentedControl!
    
    @IBAction func switchStateChanged(sender: UISegmentedControl) {
        switchStateSegmentedControl.enabled = false
        
        if switchInstance.isAccessoryConnected() {
            print("\(switchAccessoryName) is reachable")
            if switchStateSegmentedControl.selectedSegmentIndex == 0 {
                self.logMessages.addLogText("Turning Switch OFF ...")
                self.startActivityAnimation("Turning OFF")
            }
            else  {
                self.logMessages.addLogText("Turning Switch ON ...")
                self.startActivityAnimation("Turning ON")
            }
            switchInstance.writeToPowerState(switchStateSegmentedControl.selectedSegmentIndex)
        }
        else {
            print("\(switchAccessoryName) is not reachable")
            self.logMessages.addLogText("\(switchAccessoryName) is not reachable")
            clearSwitch()
        }
    }
    
    
    func addNewAccessory(accessory: HMAccessory?) {
        if let accessory = accessory {
            self.startActivityAnimation("Connecting")
            switchAccessoryName = accessory.name
            switchInstance.selectedAccessory(accessory)
            switchInstance.discoverServicesAndCharacteristics()
        }
    }
    
    func clearSwitch() {
        switchAccessoryName = nil
        switchTitle.textColor = UIColor(red: 170.0/255.0, green: 171.0/255.0, blue: 175.0/255.0, alpha: 1.0)
        switchTitle.text = "Device Name"
        switchTitle.enabled = false
        isSwitchServiceFound = false
        disableSwitchControls()
        
    }
    
    func enableSwitchControls() {
        switchStateSegmentedControl.enabled = true
        switchTitle.enabled = true
    }
    
    func disableSwitchControls() {
        self.stopActivityAnimation()
        switchStateSegmentedControl.enabled = false
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

extension SwitchViewController: SwitchProtocol {
    
    func didReceiveState(value: Int) {
        print("didReceiveState \(value)")
        if value == 0 {
            self.logMessages.addLogText("    SwitchState value: OFF")
        }
        else  {
            self.logMessages.addLogText("    SwitchState value: ON")
        }
        enableSwitchControls()
        stopActivityAnimation()
        switchStateSegmentedControl.selectedSegmentIndex = value
    }
    
    func didStateChanged(state: Int) {
        print("didStateChanged \(state)")
        if state == 0 {
            self.logMessages.addLogText("Switch turned OFF")
        }
        else  {
            self.logMessages.addLogText("Switch turned ON")
        }
        switchStateSegmentedControl.enabled = true
        self.stopActivityAnimation()
    }
    
    func didFoundServiceAndCharacteristics(isAllFound: Bool) {
        print("didFoundServiceAndCharacteristics: \(isAllFound)")
        if isAllFound == true {
            switchTitle.textColor = UIColor.blackColor()
            switchTitle.text = switchAccessoryName
            isSwitchServiceFound = true
            switchInstance.readValues()
        }
        else {
            logMessages.addLogText("Accessory is not Switch")
            clearSwitch()
            showAlert("Accessory is not Switch")
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
        clearSwitch()
    }
    
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!) {
        print("didReceiveAccessoryReachabilityUpdate: \(accessory)")
        addNewAccessory(accessory)
    }

}

extension SwitchViewController: SelectAccessaryDelegate {
    func selectedAccessary(accessary: HMAccessory!) {
        print("selectedAccessary \(accessary.name)")
        self.logMessages.addLogText("selectedAccessary: \(accessary.name)")
        clearSwitch()
        //this delegate is called before viewWillAppear() therefore setting this flag here
        //otherwise Alert box will not appear
        isViewAppeared = true
        addNewAccessory(accessary)
    }
}
