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

class FanViewController: UIViewController {
    
    var fanAccessoryName: String!
    var isFanServiceFound:Bool = false
    var isAlertVisible:Bool = false
    var isViewAppeared = true
    var activityTimer = NSTimer()
    var utility = Utility.sharedInstance
    
    var logMessages: Logger = Logger()
    var fanInstance:Fan = Fan.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disableFanControls()
        fanInstance.delegate = self
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
    
    @IBOutlet weak var fanTitle: UILabel!
    @IBOutlet weak var fanStateSegmentedControl: UISegmentedControl!
    @IBOutlet weak var fanDirectionSegmentedControl: UISegmentedControl!
    @IBOutlet weak var fanSpeedSlider: UISlider!
    @IBOutlet weak var fanSpeedLabel: UILabel!
    
    
    
    @IBAction func fanStateChanged(sender: UISegmentedControl) {
        fanStateSegmentedControl.enabled = false
        if fanInstance.isAccessoryConnected() {
            print("\(fanAccessoryName) is reachable")
            if fanStateSegmentedControl.selectedSegmentIndex == 0 {
                self.logMessages.addLogText("Turning Fan OFF ...")
                self.startActivityAnimation("Turning OFF")
            }
            else  {
                self.logMessages.addLogText("Turning Fan ON ...")
                self.startActivityAnimation("Turning ON")
            }
            fanInstance.writeToPowerState(fanStateSegmentedControl.selectedSegmentIndex)
        }
        else {
            print("\(fanAccessoryName) is not reachable")
            self.logMessages.addLogText("\(fanAccessoryName) is not reachable")
            clearFan()
        }
        
    }

    @IBAction func fanDirectionChanged(sender: UISegmentedControl) {
        print("fanDirectionChanged \(fanDirectionSegmentedControl.selectedSegmentIndex)")
        fanDirectionSegmentedControl.enabled = false
        
        if fanInstance.isAccessoryConnected() {
            print("\(fanAccessoryName) is reachable")
            if fanDirectionSegmentedControl.selectedSegmentIndex == 0 {
                self.logMessages.addLogText("Changing Fan Direction to Clockwise ...")
                self.startActivityAnimation("Rotating Right")
            }
            else  {
                self.logMessages.addLogText("Changing Fan Direction to Counter Clockwise ...")
                self.startActivityAnimation("Rotating Left")
            }
            fanInstance.writeToRotationDirection(fanStateSegmentedControl.selectedSegmentIndex)
        }
        else {
            print("\(fanAccessoryName) is not reachable")
            self.logMessages.addLogText("\(fanAccessoryName) is not reachable")
            clearFan()
        }

    }
    
    @IBAction func fanSpeedChanged(sender: UISlider) {
        let speed = Int(fanSpeedSlider.value)
        print("fanSpeedChanged \(speed)")
        if fanInstance.isAccessoryConnected() {
            print("\(fanAccessoryName) is reachable")
            fanSpeedLabel.text = String(speed)
            if (speed % 10) == 0 {
                print("changing speed to \(speed)")
                fanInstance.writeToRotationSpeed(speed)
            }
        }
        else {
            print("\(fanAccessoryName) is not reachable")
            logMessages.addLogText("\(fanAccessoryName) is not reachable")
            clearFan()
        }
    }
    
    
    func addNewAccessory(accessory: HMAccessory?) {
        if let accessory = accessory {
            self.startActivityAnimation("Connecting")
            fanAccessoryName = accessory.name
            fanInstance.selectedAccessory(accessory)
            fanInstance.discoverServicesAndCharacteristics()
        }
    }
    
    func clearFan() {
        fanAccessoryName = nil
        fanTitle.textColor = UIColor(red: 170.0/255.0, green: 171.0/255.0, blue: 175.0/255.0, alpha: 1.0)
        fanTitle.text = "Device Name"
        isFanServiceFound = false
        fanSpeedLabel.text = ""
        disableFanControls()
        
    }
    
    func enableFanControls() {
        fanDirectionSegmentedControl.enabled = true
        fanStateSegmentedControl.enabled = true
        fanSpeedSlider.enabled = true
    }
    
    func disableFanControls() {
        self.stopActivityAnimation()
        self.fanSpeedSlider.enabled = false
        fanStateSegmentedControl.enabled = false
        fanDirectionSegmentedControl.enabled = false
    }
    
    func enableRotationControls() {
        fanSpeedSlider.enabled = true
        fanDirectionSegmentedControl.enabled = true
    }
    
    func disableRotationControls() {
        fanSpeedSlider.enabled = false
        fanDirectionSegmentedControl.enabled = false
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

extension FanViewController: FanProtocol {
    
    func didReceivePowerState(value: Int) {
        print("didReceivePowerState \(value)")
        enableFanControls()
        if value == 0 {
            self.logMessages.addLogText("    Fan PowerState value: OFF")
            disableRotationControls()
        }
        else  {
            self.logMessages.addLogText("    Fan PowerState value: ON")
        }
        stopActivityAnimation()
        fanStateSegmentedControl.selectedSegmentIndex = value
    }
    
    func didReceiveRotationDirection(value: Int) {
        print("didReceiveRotationDirection \(value)")
        if value == 0 {
            self.logMessages.addLogText("    Fan RotationDirection value: Clockwise")
        }
        else  {
            self.logMessages.addLogText("    Fan RotationDirection value: CounterClockwise")
        }
        fanDirectionSegmentedControl.selectedSegmentIndex = value
    }
    
    func didReceiveRotationSpeed(value: Int) {
        print("didReceiveRotationSpeed \(value)")
        logMessages.addLogText("    Fan RotationSpeed value: \(value)")
        fanSpeedSlider.value = Float(value)
        fanSpeedLabel.text = String(value)
    }
    
    func didPowerStateChanged(state: Int) {
        print("didStateChanged \(state)")
        if state == 0 {
            self.logMessages.addLogText("Fan turned OFF")
            disableRotationControls()
        }
        else  {
            self.logMessages.addLogText("Fan turned ON")
            enableRotationControls()
        }
        fanStateSegmentedControl.enabled = true
        self.stopActivityAnimation()
    }
    
    func didRotationDirectionChanged(value: Int) {
        print("didRotationDirectionChanged \(value)")
        if value == 0 {
            self.logMessages.addLogText("Fan Direction changed to Clockwise")
        }
        else  {
            self.logMessages.addLogText("Fan Direction changed to CounterClockwise")
        }
        fanDirectionSegmentedControl.enabled = true
        self.stopActivityAnimation()
    }
    
    func didFoundServiceAndCharacteristics(isAllFound: Bool) {
        print("didFoundServiceAndCharacteristics: \(isAllFound)")
        if isAllFound == true {
            fanTitle.textColor = UIColor.blackColor()
            fanTitle.text = fanAccessoryName
            isFanServiceFound = true
            fanInstance.readValues()
        }
        else {
            logMessages.addLogText("Accessory is not fan")
            clearFan()
            showAlert("Accessory is not fan")
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
        clearFan()
    }
    
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!) {
        print("didReceiveAccessoryReachabilityUpdate: \(accessory)")
        addNewAccessory(accessory)
    }
    
}

extension FanViewController: SelectAccessaryDelegate {
    func selectedAccessary(accessary: HMAccessory!) {
        print("selectedAccessary \(accessary.name)")
        self.logMessages.addLogText("selectedAccessary: \(accessary.name)")
        clearFan()
        //this delegate is called before viewWillAppear() therefore setting this flag here
        //otherwise Alert box will not appear
        isViewAppeared = true
        addNewAccessory(accessary)
    }
}


