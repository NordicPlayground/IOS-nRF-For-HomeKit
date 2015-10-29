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

class LightbulbViewController: UIViewController {

    var lightbulbAccessoryName: String!
    var isLightbulbServiceFound:Bool = false
    var isAlertVisible:Bool = false
    var isViewAppeared = true
    
    var activityTimer = NSTimer()
    var utility = Utility.sharedInstance
    
    var powerstateValue:Int = 0
    var brightnessValue:Int = 0
    var hueValue:Int = 0
    var saturationValue:Int = 0
    var oldHueValue:Int = 0
    var oldSaturationValue:Int = 0
    
    var logMessages: Logger = Logger()
    var light:Lightbulb = Lightbulb.sharedInstance
    
    @IBOutlet weak var lightbulbNameLabel: UILabel!
    @IBOutlet weak var colorWheel: ISColorWheel!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var powerSegmentedControl: UISegmentedControl!
    @IBOutlet weak var hueValueLabel: UILabel!
    @IBOutlet weak var saturationValueLabel: UILabel!
    @IBOutlet weak var brightnessValueLabel: UILabel!
    
    enum LightStatus: Int {
        case OFF
        case ON
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        light.delegate = self
        colorWheel.delegate = self
        colorWheel.continuous = true
        colorWheel.brightness = brightnessSlider.value
        clearLightbulb()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        print("LightbulbVC: viewWillDisappear")
        stopActivityAnimation()
        isViewAppeared = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("LightbulbVC: viewWillAppear")
        isViewAppeared = true
    }
    
    @IBAction func powerValueChanged(sender: UISegmentedControl) {
        print("powerValueChanged \(powerSegmentedControl.selectedSegmentIndex)")
        disableLightbulbControls()
        if light.isAccessoryConnected() {
            print("\(lightbulbAccessoryName) is reachable")
            if powerSegmentedControl.selectedSegmentIndex == 0 {
                self.logMessages.addLogText("Turning OFF Light ...")
                startActivityAnimation("Turning OFF")
            }
            else  {
                self.logMessages.addLogText("Turning ON Light ...")
                startActivityAnimation("Turning ON")
            }
            light.writeToPowerState(sender.selectedSegmentIndex)
        }
        else {
            print("\(lightbulbAccessoryName) is not reachable")
            logMessages.addLogText("\(lightbulbAccessoryName) is not reachable")
            clearLightbulb()
        }
    }
    
    func switchPowerState(state:Int) {
        switch state {
            case LightStatus.OFF.rawValue:
                enableLightbulbControls()
                disableLightbulbColorControls()
                self.stopActivityAnimation()
                self.logMessages.addLogText("Light is turned OFF")
            case LightStatus.ON.rawValue:
                enableLightbulbControls()
                light.readValues()
                self.stopActivityAnimation()
                self.logMessages.addLogText("Light is turned ON")
        default:
            break
        }
    }
    
    @IBAction func brightnessValueChanged(sender: UISlider) {
        colorWheel.brightness = brightnessSlider.value
        colorWheel.updateImage()
        //scaling Brightness value from 0 .. 1 (used by ColorWheel API) to 0 .. 100 (used by LightBulb Brightness)
        brightnessValue = Int(max(0, min(100, Int(brightnessSlider.value * 100))))
        brightnessValueLabel.text = String(brightnessValue)
        if light.isAccessoryConnected() {
                print("\(lightbulbAccessoryName) is reachable")
                if (brightnessValue % 10) == 0 {
                    print("changing Brightness to \(brightnessValue)")
                    light.writeToBrightness(brightnessValue)
                }
            }
            else {
                print("\(lightbulbAccessoryName) is not reachable")
                logMessages.addLogText("\(lightbulbAccessoryName) is not reachable")
                clearLightbulb()
            }
        }
    
    func addNewAccessory(accessory: HMAccessory?) {
        if let accessory = accessory {
            startActivityAnimation("Connecting")
            lightbulbAccessoryName = accessory.name
            light.selectedAccessory(accessory)
            light.discoverServicesAndCharacteristics()
        }
    }
    
    func enableLightbulbControls() {
        powerSegmentedControl.enabled = true
        brightnessSlider.enabled = true
        hueValueLabel.enabled = true
        saturationValueLabel.enabled = true
        brightnessValueLabel.enabled = true
    }
    
    func disableLightbulbControls() {
        powerSegmentedControl.enabled = false
        brightnessSlider.enabled = false
        colorWheel.brightness = 0.0
        colorWheel.updateImage()
        hueValueLabel.enabled = false
        saturationValueLabel.enabled = false
        brightnessValueLabel.enabled = false
        self.stopActivityAnimation()
    }
    
    func enableLightBulbColorControls() {
        brightnessSlider.enabled = true
        hueValueLabel.enabled = true
        saturationValueLabel.enabled = true
        brightnessValueLabel.enabled = true
    }
    
    func disableLightbulbColorControls() {
        brightnessSlider.enabled = false
        colorWheel.brightness = 0.0
        colorWheel.updateImage()
        hueValueLabel.enabled = false
        saturationValueLabel.enabled = false
        brightnessValueLabel.enabled = false
    }
    
    func clearLightbulb() {
        lightbulbAccessoryName = nil
        lightbulbNameLabel.textColor = UIColor(red: 170.0/255.0, green: 171.0/255.0, blue: 175.0/255.0, alpha: 1.0)
        lightbulbNameLabel.text = "Device Name"
        isLightbulbServiceFound = false
        disableLightbulbControls()
    }
    
    func startActivityAnimation(message: String) {
        // 20 seconds timeout
        utility.displayActivityIndicator(view, msg: message, xOffset: -60, yOffset: 80)
        let delayInSeconds = 20.0
        activityTimer = NSTimer.scheduledTimerWithTimeInterval(delayInSeconds, target: self, selector: Selector("processingTimeout"), userInfo: nil, repeats: false)
    }
    
    func processingTimeout() {
        self.stopActivityAnimation()
        showAlert("Time out!. Please Select Device again")
        self.logMessages.addLogText("Time out.")
    }
    
    func stopTimer() {
        activityTimer.invalidate()
    }
    
    func stopActivityAnimation() {
        utility.removeActivityIndicator()
        stopTimer()
    }
    
    func showAlert(message: String) {
        if isViewAppeared {
            utility.showAlert(self, title: "nRF HomeKit", message: message)
        }
    }
    
    // MARK: - Navigation
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

extension LightbulbViewController: SelectAccessaryDelegate {
    func selectedAccessary(accessary: HMAccessory!) {
        print("selectedAccessary \(accessary.name)")
        logMessages.addLogText("selected accessory: \(accessary.name)")
        clearLightbulb()
        //this delegate is called before viewWillAppear() therefore setting this flag here
        //otherwise Alert box will not appear
        isViewAppeared = true
        addNewAccessory(accessary)
    }    
}

extension LightbulbViewController: LightbulbProtocol {
    
    func didReceiveBrightness(value: Int) {
        print("didReceiveBrightness: \(value)")
        self.brightnessValue = value
        //scale down Brightness value from 0..100 (brightness characteristic) to 0..1 (brightness slider for ColorWheel)
        let brightness:Float = Float(max(0.0, min(1.0, Float(Float(self.brightnessValue) / 100.0))))
        print("Brightness value after scaling down \(brightness)")
        self.brightnessSlider.value = brightness
        self.brightnessValueLabel.text = String(self.brightnessValue)
        self.colorWheel.brightness = brightness
        self.colorWheel.updateImage()
        self.enableLightbulbControls()
        self.stopActivityAnimation()
        logMessages.addLogText("    Brightness: \(self.brightnessValue)")
    }
    
    func didReceiveHue(value: Int) {
        print("didReceiveHue: \(value)")
        self.hueValue = value
        self.hueValueLabel.text = String(self.hueValue)
        logMessages.addLogText("    Hue: \(self.hueValue)")
    }
    
    func didReceiveSaturation(value: Int) {
        print("didReceiveSaturation: \(value)")
        self.saturationValue = value
        self.saturationValueLabel.text = String(self.saturationValue)
        logMessages.addLogText("    Saturation: \(self.saturationValue)")
    }
    
    func didReceivePowerState(value: Int) {
        print("didReceivePowerState: \(value)")
        self.powerstateValue = value
        self.powerSegmentedControl.selectedSegmentIndex = self.powerstateValue
        if self.powerstateValue == 0 {
            self.disableLightbulbColorControls()
        }
        logMessages.addLogText("    Powerstate: \(self.powerstateValue)")
    }
    
    func didPowerStateChanged(powerState: Int) {
        print("didPowerStateChanged \(powerState)")
        self.switchPowerState(powerState)
    }
    
    func didFoundServiceAndCharacteristics(isAllFound: Bool) {
        print("didFoundLightServiceAndCharacteristics: \(isAllFound)")
        if isAllFound == true {
            lightbulbNameLabel.textColor = UIColor.blackColor()
            lightbulbNameLabel.text = lightbulbAccessoryName
            isLightbulbServiceFound = true
            light.readValues()
        }
        else {
            logMessages.addLogText("Accessory is not Lightbulb")
            clearLightbulb()
            showAlert("Accessory is not Lightbulb")
        }
    }
    
    func didReceiveLogMessage(message: String) {
        print("didReceiveLogMessage: \(message)")
        logMessages.addLogText(message)
    }
    
    func didReceiveErrorMessage(message: String) {
        print("didReceiveErrorMessage: \(message)")
        logMessages.addLogText(message)
        showAlert(message)
        clearLightbulb()
    }
    
    func didReceiveAccessoryReachabilityUpdate(accessory:HMAccessory!) {
        print("didReceiveAccessoryReachabilityUpdate: \(accessory)")
        addNewAccessory(accessory)
    }
}

extension LightbulbViewController: ISColorWheelDelegate {
    
    func colorWheelDidChangeColor(colorWheel:ISColorWheel) {
        let color = colorWheel.currentColor()
        var hue:CGFloat = 0.0
        var saturation:CGFloat = 0.0
        var brightness:CGFloat = 0.0
        var alpha:CGFloat = 0.0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        //Scaling Hue (0 to 360), Saturation (0 to 100) and Brightness (0 to 100)
        hueValue = Int(max(0, min(360, Float(hue * 360))))
        saturationValue = Int(max(0, min(100, Float(saturation * 100))))
        brightnessValue = Int(max(0, min(100, Int(brightness * 100))))
        print("colorWheelDidChangeColor Hue: \(hueValue) Sat: \(saturationValue) Bri: \(brightnessValue), Alpha: \(alpha)")
        
        if brightnessSlider.enabled == true {
            if light.isAccessoryConnected() {
                print("\(lightbulbAccessoryName) is reachable")
                hueValueLabel.text = String(hueValue)
                saturationValueLabel.text = String(saturationValue)
                if shouldChangeHue() {
                    print("changing Hue")
                    light.writeToHue(hueValue)
                }
                if shouldChangeSaturation() {
                    print("changing Saturation")
                    light.writeToSaturation(saturationValue)
                }
            }
            else {
                print("\(lightbulbAccessoryName) is not reachable")
                self.logMessages.addLogText("\(lightbulbAccessoryName) is not reachable")
                clearLightbulb()
            }
        }
    }
    
    func shouldChangeHue() -> Bool {
        //compare old value with new if there is difference of 20 return yes else no
        if abs(hueValue - oldHueValue) >= 20 {
            oldHueValue = hueValue
            return true
        }
        return false
    }
    
    func shouldChangeSaturation() -> Bool {
        //compare old value with new if there is difference of 10 return yes else no
        if abs(saturationValue - oldSaturationValue) >= 10 {
            oldSaturationValue = saturationValue
            return true
        }
        return false
    }
}

