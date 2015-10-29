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

class RoomConfigurationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var accessoriesTableView: UITableView!
    
    var accessoriesInRoom: [HMAccessory]?
    var selectedHome:HMHome?
    var selectedRoom:HMRoom?
    var utility = Utility.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Accessories in Room: \(accessoriesInRoom?.count)")
        accessoriesTableView.delegate = self
        accessoriesTableView.dataSource = self
        accessoriesTableView.separatorColor = UIColor.blackColor()
        
        if let selectedRoom = selectedRoom {
            roomNameTextField.text = selectedRoom.name
        }
        
    }
    
    @IBAction func removeRoomPressed(sender: UIBarButtonItem) {
        if let selectedHome = selectedHome {
            if let selectedRoom = selectedRoom {
                selectedHome.removeRoom(selectedRoom, completionHandler: { (error: NSError?) -> Void in
                    if error != nil {
                        self.utility.showAlert(self, title: "Error Removing Room", message: error?.localizedDescription)
                    }
                    else {
                        print("Room removed successfully")
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                })
            }
        }
    }
    
    // MARK: - TextField Done button Pressed
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        roomNameTextField.resignFirstResponder()
        if roomNameTextField.text != "" {
            if let selectedRoom = selectedRoom {
                selectedRoom.updateName(roomNameTextField.text!, completionHandler: { (error: NSError?) -> Void in
                    if error != nil {
                        print("Error in updating Room name: \(error?.localizedDescription)")
                        self.utility.showAlert(self, title: "Error in updating Room name", message: error?.localizedDescription)
                    }
                    else {
                        print("Room name updated successfully")
                    }
                })
            }
        }
        return true
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let accessoriesInRoom = accessoriesInRoom {
            if accessoriesInRoom.count == 0 {
                utility.displayEmptyTableMessageAtTop(tableView, msg: utility.NO_ACCESSORY_FOUND_IN_ROOM_CONFIG)
            }
            else {
                utility.removeEmptyTableMessage()
            }
            return accessoriesInRoom.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AccessoriesInRoomCell", forIndexPath: indexPath)
        cell.textLabel?.text = accessoriesInRoom![indexPath.row].name
        return cell
    }


}
