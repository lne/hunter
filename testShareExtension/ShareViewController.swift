//
//  ShareViewController.swift
//  testShareExtension
//
//  Created by weidongfeng on 2019/07/08.
//  Copyright © 2019 weidongfeng. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {
    let suiteName: String = "group.thanks.hunter001"
    let keyName: String = "sessionID"

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        print("didSelectPost")
        fetchSessionID()
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.

        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        let extensionItem: NSExtensionItem = self.extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = extensionItem.attachments?.first as! NSItemProvider
        
        let puclicURL = String(kUTTypeURL)  // "public.url"
        // shareExtension 
        if itemProvider.hasItemConformingToTypeIdentifier(puclicURL) {
            itemProvider.loadItem(forTypeIdentifier: puclicURL, options: nil, completionHandler: { (item, error) in
                // NSURLを取得する
                if let url: NSURL = item as? NSURL {
                    NSLog(url.absoluteString!)
                }
                //self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            })
        }
    }

    // ---------------------------------------------
    // Fetch session ID from UserDefaults
    // ---------------------------------------------
    private func fetchSessionID() -> String {
        // fetch Data
        let sharedDefaults: UserDefaults = UserDefaults(suiteName: suiteName)!
        let sessionID = sharedDefaults.object(forKey: keyName)
        print("fetchSessionID : \(sessionID!)")
        return "\(sessionID!)"
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

    override func viewDidLoad() {
        print("viewDidLoad")
        let context = self.extensionContext!
        
        // NOTE: 天どんに1アカウントもログイン情報が存在しない！
        if currentSessionID() != nil {
            let alert = UIAlertController(title: "天どん", message: "ログインしていないと使えません、ごめんね。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
                context.completeRequest(returningItems: nil, completionHandler: nil)
            }))
            present(alert, animated: true, completion: nil)
        }
        else {
            super.viewDidLoad()

            self.title = "感謝×HUNTER";
            
            // Edit post button name
            let c: UIViewController = self.navigationController!.viewControllers[0]
            c.navigationItem.rightBarButtonItem!.title = "投稿"

            // Edit text
            let textView = self.textView
            textView?.attributedText = NSAttributedString(string: "abc", attributes:nil)
        }
    }
    
    private func currentSessionID() -> String? {
        return nil
    }
}
