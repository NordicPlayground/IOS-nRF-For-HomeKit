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

class HomeConfigurationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var homeManager:HomeKitManager?
    var selectedHome:HMHome?
    var rooms:[HMRoom]!
    var accessories:[HMAccessory]!
    var roomNameTextField:UITextField!
    var utility = Utility.sharedInstance
    
    @IBOutlet weak var roomTableView: UITableView!
    @IBOutlet weak var accessoryTableView: UITableView!
    
    @IBOutlet weak var homeNameTextField: UITextField!
    @IBOutlet weak var setPrimaryHomeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let selectedHome = selectedHome {
            rooms = selectedHome.rooms
            accessories = selectedHome.accessories
            print("SelectedHomeName: \(selectedHome.name), Rooms: \(rooms.count), Accessories: \(accessories.count)")
            homeNameTextField.text = selectedHome.name
            if selectedHome.primary {
                setPrimaryHomeSwitch.on = true
                setPrimaryHomeSwitch.enabled = false
            }
            else {
                setPrimaryHomeSwitch.on = false
                setPrimaryHomeSwitch.enabled = true
            }
        }
        roomTableView.delegate = self
        roomTableView.dataSource = self
        roomTableView.separatorColor = UIColor.blackColor()
        
        accessoryTableView.delegate = self
        accessoryTableView.dataSource = self
        accessoryTableView.separatorColor = UIColor.blackColor()        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        refreshTables()
    }
    
    
    @IBAction func setPrimaryHomeValueChanged(sender: UISwitch) {
        if setPrimaryHomeSwitch.on == true {
            if let homeManager = homeManager {
                print("setting selected home to Primary Home")
                homeManager.setPrimaryHome(selectedHome!)
            }
        }
    }
    
    @IBAction func deleteHomePressed(sender: UIBarButtonItem) {
        if let homeManager = homeManager {
            homeManager.removeHome(selectedHome!)
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func showAddRoomAlert() {
        let addRoomAlert = UIAlertController(title: "Add Room", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        addRoomAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        addRoomAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("OK Pressed")
            if self.roomNameTextField.text != "" {
                self.addRoom(self.roomNameTextField.text!)
            }
            
        }))
        
        addRoomAlert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.placeholder = "Please Type Room Name"
            self.roomNameTextField = textField
        }
        
        presentViewController(addRoomAlert, animated: true, completion: nil)
    }
    
    func addRoom(roomName:String) {
        selectedHome?.addRoomWithName(roomName, completionHandler: { (room:HMRoom?, error:NSError?) -> Void in
            if error != nil {
                print("Error adding Room: \(error?.localizedDescription)")
                self.utility.showAlert(self, title: "Error in Adding Room", message: error?.localizedDescription)
            }
            else {
                print("Added Room successfully")
                //TODO In IOS 8, it takes a bit longer to update rooms and therefore not showing newly added Room in the RoomTable
                //Also didUpdateHomeManager delegate is called. There is need to implement logic to listen it and then update Rooms
                self.refreshRoomsTable()
            }
        })
    }
    
    func refreshTables() {
        refreshRoomsTable()
        refreshAccessoriesTable()
    }
    
    func refreshRoomsTable() {
        if let selectedHome = selectedHome {
            rooms = selectedHome.rooms
        }
        roomTableView.reloadData()
    }
    
    func refreshAccessoriesTable() {
        if let selectedHome = selectedHome {
            accessories = selectedHome.accessories
        }
        accessoryTableView.reloadData()
    }


    
    @IBAction func addRoomPressed(sender: UIButton) {
        showAddRoomAlert()
    }
        
    // MARK: - TextField Done button Pressed
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        homeNameTextField.resignFirstResponder()
        if homeNameTextField.text != "" {
            homeManager?.updateHomeName(selectedHome!, name: homeNameTextField.text!)
        }
        return true
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SegueConfigureAccessory" {
            let accessoryConfig = segue.destinationViewController as! AccessoryConfigurationViewController
            accessoryConfig.selectedHome = selectedHome
            accessoryConfig.selectedAccessory = accessories[(accessoryTableView.indexPathForSelectedRow?.row)!]
        }
        else if segue.identifier == "SegueAddAccessory" {
            print("SegueAddAccessory")
            let navVC = segue.destinationViewController as! UINavigationController
            let addAccVC = navVC.topViewController as! AddAccessoryTableViewController
            addAccVC.selectedHome = selectedHome
        }
        else if segue.identifier == "SegueConfigureRoom" {
            let roomConfigVC = segue.destinationViewController as! RoomConfigurationViewController
            let selectedRoom = rooms[(roomTableView.indexPathForSelectedRow?.row)!]
            roomConfigVC.accessoriesInRoom = selectedRoom.accessories
            roomConfigVC.selectedRoom = selectedRoom
            roomConfigVC.selectedHome = selectedHome
        }
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == roomTableView {
            print("Room.count: \(rooms.count)")
            if rooms.count == 0 {
                utility.displayEmptyRoomsTableMessage(tableView, msg: utility.NO_ROOM_FOUND_IN_HOME_SETTINGS, width:200, height:60)
            }
            else {
                utility.removeEmptyRoomsTableMessage()
            }
            return rooms.count
        }
        else if tableView == accessoryTableView {
            print("Accessories.count: \(accessories.count)")
            if accessories.count == 0 {
                utility.displayEmptyAccessoriesTableMessage(tableView, msg: utility.NO_ACCESSORIES_FOUND_IN_HOME_SETTINGS, width:200, height:60)
            }
            else {
                utility.removeEmptyAccessoriesTableMessage()
            }
            return accessories.count
        }
        else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView == roomTableView {
            let cell = tableView.dequeueReusableCellWithIdentifier("RoomsCell", forIndexPath: indexPath)
            cell.textLabel?.text = rooms[indexPath.row].name
            return cell
        }
        else if tableView == accessoryTableView {
            let cell = tableView.dequeueReusableCellWithIdentifier("AccessoriesCell", forIndexPath: indexPath)
            cell.textLabel?.text = accessories[indexPath.row].name
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("", forIndexPath: indexPath)
            return cell
        }       
        
  }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("didSelectRowAtIndex \(indexPath.row)")

    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30
    }

}

