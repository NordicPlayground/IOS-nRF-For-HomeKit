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

class AddAccessoryTableViewController: UITableViewController, HMAccessoryBrowserDelegate {
    
    var selectedHome:HMHome?
    var accessories = [HMAccessory]()
    var accessoryBrowser: HMAccessoryBrowser!
    var utility = Utility.sharedInstance
    var errorMessage: HMErrorCodeMessage = HMErrorCodeMessage()
    var logMessages:Logger?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initAccessoryBrowser()
    }
    
    func initAccessoryBrowser() {
        accessoryBrowser = HMAccessoryBrowser()
        accessoryBrowser.delegate = self
        startAccessoriesScanning()
    }
    
    func startAccessoriesScanning() {
        print("startAccessoriesScanning")
        accessoryBrowser.startSearchingForNewAccessories()
    }
    
    func stopAccessoriesScanning() {
        if accessoryBrowser != nil {
            print("stopAccessoriesScanning")
            accessoryBrowser.stopSearchingForNewAccessories()
        }
        utility.removeActivityIndicator()
    }
    
    func addNewAccessory(accessory: HMAccessory!) {
        utility.displayActivityIndicator(view, msg:"Pairing")
        if let selectedHome = selectedHome {
            selectedHome.addAccessory(accessory, completionHandler: { (error:NSError?) -> Void in
                if error != nil {
                    print("Error in adding accessory \(self.errorMessage.getHMErrorDescription(error!.code))")
                    self.utility.removeActivityIndicator()
                    if let logMessages = self.logMessages {
                        logMessages.addLogText("Error in adding accessory \(self.errorMessage.getHMErrorDescription(error!.code))")
                    }
                    self.utility.showAlert(self, title: "Error in adding accessory", message: self.errorMessage.getHMErrorDescription(error!.code))
                }
                else {
                    print("Accessory is added successfully")
                    self.utility.removeActivityIndicator()
                }
            })

        }
    }
    
    //Delegate method of HMAccessoryBrowser
    func accessoryBrowser(browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        print("didRemoveNewAccessory Accessory is removed: \(accessory.name) reloading tableview")
        removeAccessoryFromTableView()
    }

    func removeAccessoryFromTableView() {
        accessories.removeAtIndex((tableView.indexPathForSelectedRow?.row)!)
        tableView.reloadData()
    }
    
    @IBAction func donePressed(sender: UIBarButtonItem) {
        stopAccessoriesScanning()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - HMAccessoryBrowserDelegate protocol
    
    //delegate is called after starting Accessory Scanning
    func accessoryBrowser(browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        print("didFindNewAccessory \(accessory.name)")
        if let logMessages = self.logMessages {
            logMessages.addLogText("New Accessory: \(accessory.name)")
        }
        accessories.append(accessory)
        tableView.reloadData()
    }


    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if accessories.count == 0 {
            print("numberOfRowsInSection: accessories.count is zero:")
            utility.displayEmptyTableMessage(tableView, msg: utility.NO_ACCESSORY_FOUND_IN_ADD_ACCESSORY)
        }
        else {
            print("numberOfRowsInSection: accessories.count is not zero: \(accessories.count)")
            utility.removeEmptyTableMessage()
        }
        return accessories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AddingAccessoryCell", forIndexPath: indexPath) as! AddAccessoryTableViewCell
        // Configure the cell...
        let accessory:HMAccessory = accessories[indexPath.row]
        cell.accessoryTitle?.text = accessory.name
        print("New Accessory Caletgory: \(accessory.category.categoryType)")
        cell.accessoryCategoryImage.image = utility.getAccessoryCategoryImage(accessory.category.categoryType)        
        cell.identifyButton.tag = indexPath.row

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("didSelectRowAtIndex \(indexPath.row)")
        addNewAccessory(accessories[indexPath.row])
    }
    
    
    // MARK: - IBAction Identify Pressed
    
    @IBAction func identifyPressed(sender: UIButton) {
        print("identifyPressed \(sender.tag)")
        // selected row index is saved in button tag property in tablView cellForRowAtIndexPath
        let rowIndex = sender.tag
        let selectedAccessory:HMAccessory = accessories[rowIndex];
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


}
