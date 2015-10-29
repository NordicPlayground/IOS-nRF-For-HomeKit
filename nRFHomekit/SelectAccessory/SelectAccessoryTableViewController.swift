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

protocol SelectAccessaryDelegate {
    func selectedAccessary(accessary: HMAccessory!)
}

class SelectAccessoryTableViewController: UITableViewController, HomeKitManagerDelegate {
    
    var delegate:SelectAccessaryDelegate?
    var pairedAccessories = [HMAccessory]()
    var homeManager:HomeKitManager!
    var myHome: HMHome!
    var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    var logMessages:Logger?
    var isAlertVisible:Bool = false
    var utility = Utility.sharedInstance
    var isViewAppeared = true
    var emptyTableMsg:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emptyTableMsg = utility.NO_ACCESSORY_IN_PRIMARY_HOME
        initHome()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        isViewAppeared = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        isViewAppeared = false
    }


    func initHome() {
        homeManager = HomeKitManager()
        homeManager.delegate = self
    }
    
    func getPairedAccessories() {
        if myHome != nil {
            if myHome.accessories.count == 0 {
                emptyTableMsg = utility.NO_ACCESSORY_IN_PRIMARY_HOME
            }
            else {
                for accessory in myHome.accessories {
                    print("Found Paired Accessory: \(accessory.name)")
                    if let logMessages = self.logMessages {
                        logMessages.addLogText("Paired Accessory: \(accessory.name)")
                    }
                    pairedAccessories.append(accessory)
                }
            }
            tableView.reloadData()
        }
        else {
            print("No home exist")
        }
    }
    
    func showAlert(message: String) {
        if isViewAppeared {
            utility.showAlert(self, title: "nRF HomeKit", message: message)
        }
    }
        
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if pairedAccessories.count == 0 {
            utility.displayEmptyTableMessage(tableView, msg: emptyTableMsg!)
        }
        else {
            utility.removeEmptyTableMessage()
        }
        return pairedAccessories.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScanCell", forIndexPath: indexPath) as! SelectAccessoryTableViewCell

        // Configure the cell...
        let accessory:HMAccessory = pairedAccessories[indexPath.row]
        cell.accessoryTitle?.text = accessory.name
        
        print("New Accessory Caletgory: \(accessory.category.categoryType)")
        cell.accessoryCategoryImage.image = utility.getAccessoryCategoryImage(accessory.category.categoryType)
        
        cell.identifyButton.tag = indexPath.row

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("didSelectRowAtIndex \(indexPath.row)")
        if let delegate = self.delegate {
            delegate.selectedAccessary(pairedAccessories[indexPath.row])
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - IBAction Cancel Pressed
    @IBAction func cancelPressed(sender: UIBarButtonItem) {
        print("cancelPressed")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - IBAction Identify Pressed
    
    @IBAction func identifyPressed(sender: UIButton) {
        print("identifyPressed \(sender.tag)")
        // selected row index is saved in button tag property in tablView cellForRowAtIndexPath
        let rowIndex = sender.tag
        let selectedAccessory:HMAccessory = pairedAccessories[rowIndex];
        selectedAccessory.identifyWithCompletionHandler { (error: NSError?) -> Void in
            if error == nil {
                print("successfully send identify command")
                if let logMessages = self.logMessages {
                    logMessages.addLogText("\(selectedAccessory.name) received Identify")
                }
                
            }
            else {
                print("Error in sending Identify command: \(self.errorMessage.getHMErrorDescription(error!.code))")
                if let logMessages = self.logMessages {
                    logMessages.addLogText("Error: \(self.errorMessage.getHMErrorDescription(error!.code)) in Identify to \(selectedAccessory.name) ")
                }
            }
        }
    }
    
    // MARK: - HomeKitManagerDelegate protocol
    
    func didReceiveError(error: NSError!) {
        print("didReceiveError")
        if error != nil {
            if let logMessages = self.logMessages {
                logMessages.addLogText("Error in adding Home \(self.errorMessage.getHMErrorDescription(error.code))")
            }
            self.showAlert("Error in adding Home \(self.errorMessage.getHMErrorDescription(error.code))")
        }
    }
    func didAddedNewHome() {}
    func didSetPrimaryHome() {}
    func didUpdateHomeName() {}
    func didRemoveHome() {}
    func didInitializedHomeManager() {
        myHome = homeManager.getPrimaryHome()
        if myHome != nil {
            getPairedAccessories()
        }
        else {
            print("There is no Primary Home")
            emptyTableMsg = utility.NO_HOME_FOUND_IN_SELECT_DEVICE
            tableView.reloadData()
        }

    }

}
