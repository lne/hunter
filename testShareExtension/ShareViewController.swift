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

class ShareViewController: SLComposeServiceViewController, TypeViewDelegate, CategoryViewDelegate {

    
    let suiteName: String = "group.thanks.hunter001"
    let keyName: String = "token"
    let typeItem: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
    let categoryItem: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
    
    var typeVC: TypeViewController!
    var types: Array<String> = ["一般", "専門"]
    var categories: Array<String> = ["一般総合", "ファッション", "３", "４", "５", "６", "７", "８", "９"]

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

    
    // Just for test
    private func test() {

        post()
        //let textView = self.textView
        //textView?.attributedText = NSAttributedString(string: fetchURL(), attributes:nil)
        
    }
    
    // ---------------------------------------------
    // Post after click post button
    // ---------------------------------------------
    private func post() {
        let extensionItem: NSExtensionItem = self.extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = extensionItem.attachments?.first ?? NSItemProvider()
        
        let puclicURL = String(kUTTypeURL)  // "public.url"
        
        // Post process
        if itemProvider.hasItemConformingToTypeIdentifier(puclicURL) {
            itemProvider.loadItem(forTypeIdentifier: puclicURL, options: nil, completionHandler: { (item, error) in
                // Get URL and do post
                if let nsURL: NSURL = item as? NSURL {
                    let url = nsURL.absoluteString ?? ""
                    self.post(url: url)
                }
            })
        }
        
        // Tells the host app to complete the app extension request with an array of result items
        //self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    // ---------------------------------------------
    // Post with url
    // ---------------------------------------------
    private func post(url: String) {
        let content  = fetchContent()
        let type     = fetchType()
        let category = fetchCategory()
        // TBD: do real post request.
        let textView = self.textView
        textView?.attributedText = NSAttributedString(string: url + content + category + type, attributes:nil)
    }
    
    // ---------------------------------------------
    // Fetch content for post
    // ---------------------------------------------
    private func fetchContent() -> String {
        // Get content from view
        let content = self.contentText ?? ""
        return content
    }

    // ---------------------------------------------
    // Fetch type for post
    // ---------------------------------------------
    private func fetchType() -> String {
        // Get type
        // TBD
        return ""
    }

    // ---------------------------------------------
    // Fetch category id for post
    // ---------------------------------------------
    private func fetchCategory() -> String {
        // Get category id
        // TBD
        return ""
    }

    // ---------------------------------------------
    // Fetch session ID from UserDefaults
    // ---------------------------------------------
    private func fetchSessionID() -> String {
        // fetch Data from UserDefaults
        let sharedDefaults: UserDefaults = UserDefaults(suiteName: suiteName)!
        let sessionID = sharedDefaults.object(forKey: keyName)
        print("fetchSessionID : \(sessionID!)")
        return "\(sessionID!)"
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.

        // Initialize typeItem
        typeItem.title = "投稿先"
        typeItem.value = types.first
        typeItem.tapHandler = showTypeView

        // Initialize categoryItem
        categoryItem.title = "カテゴリ"
        categoryItem.value = categories.first
        categoryItem.tapHandler = showCategoryView

        return [typeItem, categoryItem]
    }
    
    // ---------------------------------------------
    // Show TypeView (Tap Handler)
    // ---------------------------------------------
    private func showTypeView() {
        let controller = TypeViewController()
        controller.data = types
        controller.selectedValue = typeItem.value
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    // ---------------------------------------------
    // Show CategoryView (Tap Handler)
    // ---------------------------------------------
    private func showCategoryView() {
        let controller = CategoryViewController()
        controller.data = categories
        controller.selectedValue = categoryItem.value
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    // ---------------------------------------------
    // TypeView Delegate Function
    // ---------------------------------------------
    func hideTypeView(viewController: TypeViewController, selectedValue: String) {
        typeItem.value = selectedValue
        popConfigurationViewController()
    }

    // ---------------------------------------------
    // CategoryView Delegate Function
    // ---------------------------------------------
    func hideCategoryView(viewController: CategoryViewController, selectedValue: String) {
        categoryItem.value = selectedValue
        popConfigurationViewController()
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
            self.extensionContext?.cancelRequest(withError: NSError(domain:"", code: -1, userInfo:nil))
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
            
            // test
            test()
        }
    }
    
    private func currentSessionID() -> String? {
        return nil
    }
}
