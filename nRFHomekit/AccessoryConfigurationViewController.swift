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

class AccessoryConfigurationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var selectedHome:HMHome?
    var selectedAccessory:HMAccessory?
    var utility = Utility.sharedInstance
    var accessoryRoom:HMRoom?
    var selectedRow:Int?
    
    @IBOutlet weak var accessoryNameTextField: UITextField!
    @IBOutlet weak var roomsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roomsTableView.delegate = self
        roomsTableView.dataSource = self
        roomsTableView.separatorColor = UIColor.blackColor()
        
        if let selectedAccessory = selectedAccessory {
            accessoryNameTextField.text = selectedAccessory.name
            accessoryRoom = selectedAccessory.room
        }

    }
    
    func assignAccessoryToRoom(room: HMRoom) {
        if let selectedHome = selectedHome {
            if let selectedAccessory = selectedAccessory {
                selectedHome.assignAccessory(selectedAccessory, toRoom: room, completionHandler: { (error: NSError?) -> Void in
                    if error != nil {
                        print("Error in assigning room to accessory")
                        self.utility.showAlert(self, title: "Error in Assigning Room", message: error?.localizedDescription)
                    }
                    else {
                        print("Room has been assigned to accessory successfully")
                    }
                })
            }
        }
        
    }
    
    @IBAction func removeAccessoryPressed(sender: UIBarButtonItem) {
        if let selectedHome = selectedHome {
            if let selectedAccessory = selectedAccessory {
                utility.displayActivityIndicator(view, msg: "Removing")
                selectedHome.removeAccessory(selectedAccessory, completionHandler: { (error: NSError?) -> Void in
                    if error != nil {
                        self.utility.showAlert(self, title: "Error Removing Accessory", message: error?.localizedDescription)
                    }
                    else {
                        print("Accessory removed successfully")
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                })
            }
        }
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let selectedHome = selectedHome {
            if selectedHome.rooms.count == 0 {
                utility.displayEmptyTableMessageAtTop(tableView, msg: utility.NO_ROOM_FOUND_IN_ACCESSORY_CONFIG)
            }
            else {
                utility.removeEmptyTableMessage()
            }
            return selectedHome.rooms.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AccessoryInRoom", forIndexPath: indexPath)
        
        if let selectedHome = selectedHome {
            let room = selectedHome.rooms[indexPath.row]
            cell.textLabel?.text = room.name
            
            if let selectedRow = selectedRow {
                if indexPath.row == selectedRow {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            }
            else {
                if let accessoryRoom = accessoryRoom {
                    if room.name == accessoryRoom.name {
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("didSelectRowAtIndex \(indexPath.row)")
        selectedRow = indexPath.row
        if let selectedHome = selectedHome {
            let selectedRoom = selectedHome.rooms[selectedRow!]
            assignAccessoryToRoom(selectedRoom)
        }
        tableView.reloadData()        
    }
    
    // MARK: - TextField Done button Pressed
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        accessoryNameTextField.resignFirstResponder()
        if accessoryNameTextField.text != "" {
            if let selectedAccessory = selectedAccessory {
                selectedAccessory.updateName(accessoryNameTextField.text!, completionHandler: { (error: NSError?) -> Void in
                    if error != nil {
                        print("Error in updating Accessory name: \(error?.localizedDescription)")
                        self.utility.showAlert(self, title: "Error in updating Accessory name", message: error?.localizedDescription)
                    }
                    else {
                        print("Accessory name updated successfully")
                    }
                })
                
            }
        }
        return true
    }
}
