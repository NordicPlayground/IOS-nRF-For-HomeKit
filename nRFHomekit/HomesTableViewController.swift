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

class HomesTableViewController: UITableViewController {
    
    var homeManager:HomeKitManager?
    var homes:[HMHome]!
    var homeNameTextField: UITextField!
    var utility = Utility.sharedInstance
    
    var isPrimaryHomeSwitchOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HomeTableViewController: viewDidLoad")
        homeManager = HomeKitManager()
        if let homeManager = homeManager {
            homeManager.delegate = self
        }
    }   
    
    @IBAction func addHomePressed(sender: UIBarButtonItem) {
        showHomeAlertController("Add New Home", homeName: "")
    }
    
    func showHomeAlertController(alertTitle:String, homeName:String) {
        let addHomeAlert = UIAlertController(title: "Add Home", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        addHomeAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        addHomeAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("OK Pressed")
            if self.self.homeNameTextField.text != "" {
                self.addNewHome()
            }
        }))
        
        addHomeAlert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.placeholder = "Please Type Home Name"
            self.homeNameTextField = textField
        }
        
        presentViewController(addHomeAlert, animated: true, completion: nil)
    }
    
    
    func addNewHome() {
        let homeName = homeNameTextField.text
        if homeName != "" {
            homeManager?.addNewHome(homeName!)
        }
    }
    
    func isPrimaryHome() -> Bool {
        let home = homes[(tableView.indexPathForSelectedRow?.row)!]
        return (homeManager?.isPrimaryHome(home))!
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let homes = homes {
            if homes.count == 0 {
                utility.displayEmptyTableMessage(tableView, msg: utility.NO_HOME_FOUND_IN_SETTINGS)
            }
            else {
                utility.removeEmptyTableMessage()
            }
            return homes.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HomeCell", forIndexPath: indexPath) 
        
        // Configure the cell...
        let home:HMHome = homes[indexPath.row]
        cell.textLabel?.text = home.name
        if let homeManager = homeManager {
            if homeManager.isPrimaryHome(home) {
                cell.detailTextLabel?.text = "Primary Home"
            }
            else {
                cell.detailTextLabel?.text = ""
            }
        }
        
        return cell
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let homeConfigVC = segue.destinationViewController as! HomeConfigurationViewController
        homeConfigVC.selectedHome = homes[(tableView.indexPathForSelectedRow?.row)!]
        if let homeManager = homeManager {
            homeConfigVC.homeManager = homeManager
        }        
    }
}

extension HomesTableViewController: HomeKitManagerDelegate {
    
    func didInitializedHomeManager() {
        print("didInitializedHomeManager")
        if let homeManager = homeManager {
            homes = homeManager.getAllHomes()
            tableView.reloadData()
        }        
    }
    
    func didAddedNewHome() {
        print("didAddedNewHome")
        homes = homeManager?.getAllHomes()
        utility.removeEmptyTableMessage()
        tableView.reloadData()
    }
    
    func didReceiveError(error: NSError!) {
        print("didReceiveError: \(error.localizedDescription)")
        utility.showAlert(self, title: "Error", message: error.localizedDescription)
    }
    
    func didSetPrimaryHome() {
        print("didSetPrimaryHome")
        tableView.reloadData()
    }
    
    func didUpdateHomeName() {
        print("didUpdateHomeName")
        if let homeManager = homeManager {
            homes = homeManager.getAllHomes()
            tableView.reloadData()
        }
    }
    
    func didRemoveHome() {
        print("didRemoveHome")
        homes = homeManager?.getAllHomes()
        tableView.reloadData()
    }
}
