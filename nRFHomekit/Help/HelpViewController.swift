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

class HelpViewController: UIViewController, UITextViewDelegate {
    
    let helpText = NSMutableAttributedString()
    let githubURL = NSURL(string:"https://github.com/NordicSemiconductor/")
    let nordicDeveloperZoneURL = NSURL(string:"https://devzone.nordicsemi.com/questions/")

    @IBOutlet weak var helpTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        helpTextView.delegate = self
        showAttributedText()
    }
    
    func showAttributedText() {
        // Get the current version of the app
        let version:String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        
        // Define string attributes
        let paragraphFont = UIFont(name: "Georgia", size: 14.0) ?? UIFont.systemFontOfSize(14.0)
        let paragraphAttribute = [NSFontAttributeName:paragraphFont]
        
        let headingFont = UIFont(name: "Georgia", size: 18.0) ?? UIFont.systemFontOfSize(18.0)
        let headingAttribute = [NSFontAttributeName:headingFont]
        
        //let italicFont = UIFont(name: "Georgia-Italic", size: 14.0) ?? UIFont.italicSystemFontOfSize(14.0)
        //let italicFontAttribute = [NSFontAttributeName:italicFont]
        
        //let boldFont = UIFont(name: "Georgia-Bold", size: 14.0) ?? UIFont.boldSystemFontOfSize(14.0)
        //let boldFontAttribute = [NSFontAttributeName:boldFont]
        
        let headingWithVersionString = "nRF For HomeKit Version " + version + "\n"
        let para1String = "The nRF For HomeKit works with Nordic Semiconductor's Bluetooth Low Energy SDK for HomeKit and it uses Apple IOS HomeKit API. It contains many HomeKit Services: LightBulb, Lock, GarageDoor, Switch, Outlet, and Fan. The Device Firmware Update (DFU) is also included, allows one to upload the application image over-the-air (OTA).\n"
        
        let headingAboutUsageString = "How to use the app\n"
        let para2String = " 1- First enable Keychain from IOS device Settings -> iCloud -> Keychain -> iCloud Keychain.\n 2- In app main page, tap to Settings icon and there add Homes, Rooms and Accessories.\n 3- In order to add new accessory, user has to provide the correct 8 digits passcode.\n 4- Once Home and accessory are added, You can control accessory from Siri or from this app.\n 5-  In order to control the accessory from this app, You select the appropriate Service from the app main page e.g. Lock.\n 6- Add already paired accessories by pressing SelectDevice button.\n 7- After selecting the appropriate accessory, the controls will be enabled and user can control the accessory and can see the Log.\n 8- In order to remove Accessory, Room or Home, tap to Settings icon in app main page.\n"
        
        let headingAboutResetPairing = "Reset Homekit\n"
        let para3String = "In order to reset HomeKit database in your IOS device: Goto IOS device Settings -> Privacy -> HomeKit and press Reset HomeKit Configuration...\n"
        
        let headingAboutUsefulLinks = "Some Useful Links\n"
        let para4String = "Source code of the Nordic Semiconductor apps are available on Github and you can ask questions on Nordic Developer Zone.\n"

        
        // Create locally formatted strings
        let attrString1 = NSAttributedString(string: headingWithVersionString, attributes:headingAttribute)
        let attrString2 = NSAttributedString(string: para1String, attributes:paragraphAttribute)
        let attrString3 = NSAttributedString(string: headingAboutUsageString, attributes:headingAttribute)
        let attrString4 = NSAttributedString(string: para2String, attributes:paragraphAttribute)
        let attrString5 = NSAttributedString(string: headingAboutResetPairing, attributes:headingAttribute)
        let attrString6 = NSAttributedString(string: para3String, attributes:paragraphAttribute)
        let attrString7 = NSAttributedString(string: headingAboutUsefulLinks, attributes:headingAttribute)
        let attrString8 = NSAttributedString(string: para4String, attributes:paragraphAttribute)

        
        // Add locally formatted strings to paragraph
        helpText.appendAttributedString(attrString1)
        helpText.appendAttributedString(attrString2)
        helpText.appendAttributedString(attrString3)
        helpText.appendAttributedString(attrString4)
        helpText.appendAttributedString(attrString5)
        helpText.appendAttributedString(attrString6)
        helpText.appendAttributedString(attrString7)
        helpText.appendAttributedString(attrString8)

        
        // Define paragraph styling
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.firstLineHeadIndent = 15.0
        paraStyle.paragraphSpacingBefore = 10.0
        paraStyle.lineSpacing = 5.0
        paraStyle.alignment = NSTextAlignment.Justified
        
        // Apply paragraph styles to paragraph
        helpText.addAttribute(NSParagraphStyleAttributeName, value: paraStyle, range: NSRange(location: 0,length: helpText.length))
        
        addFontColorToParagraph(para1String)
        addFontColorToParagraph(para2String)
        addFontColorToParagraph(para3String)
        addFontColorToParagraph(para4String)
        
        
        addUrlLink("Github", linkURL: githubURL!)
        addUrlLink("Nordic Developer Zone", linkURL: nordicDeveloperZoneURL!)
        
        helpTextView.attributedText = helpText

    }
    
    func addFontColorToParagraph(paragraphText: NSString) {
        let subStringRange:NSRange! = getRange(helpText.string, stringToSearch: paragraphText)
        if subStringRange != nil {
            print("subString Found")
            helpText.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkGrayColor(), range: subStringRange)
        }
        else {
            print("subdtring Not Found")
        }
    }
    
    func addUrlLink(linkText: NSString, linkURL: NSURL) {
        let linkTextRange:NSRange! = getRange(helpText.string, stringToSearch: linkText)
        if linkTextRange != nil {
            print("URL text Found")
            helpText.addAttribute(NSLinkAttributeName, value: linkURL, range: linkTextRange)
        }
        else {
            print("URL Text Not Found")
        }

    }
    
    func getRange(fullText:NSString, stringToSearch:NSString) -> NSRange! {
        var stringRange:NSRange
        var subString:NSString = ""
        for var index=0; index <= fullText.length-stringToSearch.length; index++  {
            stringRange = NSMakeRange(index, stringToSearch.length)
            subString = fullText.substringWithRange(stringRange)
            if (stringToSearch == subString) {
                return stringRange;
            }
        }
        return nil;
    }
    
    // Delegate of Protocol UITextViewDelegate
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        // In order to open webpage within app, a viewcontroller with UIWebView need to be added
        // and return must be false so that URL will not open separately in Safari Browser
        
        let text:NSString = textView.text as NSString
        var linktext = text.substringWithRange(characterRange)
        if linktext == "Github" {
            linktext = "App Source Code"
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let webVC = storyboard.instantiateViewControllerWithIdentifier("IDWebViewController") as! WebViewController
        webVC.webPageURL = URL
        webVC.webPageTitle = linktext
        navigationController?.pushViewController(webVC, animated: true)
        return false
    }
    
}

