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
    let keyName: String = "shareData"

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.

        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        let extensionItem: NSExtensionItem = self.extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = extensionItem.attachments?.first as! NSItemProvider
        
        let puclicURL = String(kUTTypeURL)  // "public.url"
        
        
        
        
        // shareExtension で NSURL を取得
        if itemProvider.hasItemConformingToTypeIdentifier(puclicURL) {
            itemProvider.loadItem(forTypeIdentifier: puclicURL, options: nil, completionHandler: { (item, error) in
                // NSURLを取得する
                if let url: NSURL = item as? NSURL {
                    NSLog(url.absoluteString!)
                    // ----------
                    // 保存処理
                    // ----------
                    let sharedDefaults: UserDefaults = UserDefaults(suiteName: self.suiteName)!
                    sharedDefaults.set(url.absoluteString!, forKey: self.keyName)  // そのページのURL保存
                    sharedDefaults.synchronize()
                }
                //self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            })
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "感謝×HUNTER";
        
        let c: UIViewController = self.navigationController!.viewControllers[0]
        c.navigationItem.rightBarButtonItem!.title = "投稿"
    }
}
