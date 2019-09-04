//
//  HunterViewController.swift
//  hunter001
//
//  Created by weidongfeng on 2019/08/26.
//  Copyright © 2019 weidongfeng. All rights reserved.
//
import UIKit
import WebKit
import SafariServices

class HunterViewController: SFSafariViewController, WKNavigationDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let webPage = "https://kanshahunter.com/"
        let safariVC = SFSafariViewController(url: NSURL(string: webPage)! as URL)
        present(safariVC, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func safariViewController(SFSafariViewController, didCompleteInitialLoad: Bool)
    先頭のURLの読み込みが終わったことを通知します
    
    func safariViewController(SFSafariViewController, activityItemsFor: URL, title: String?)
    ユーザーのアクションボタンのタップを通知します
    
    func safariViewControllerDidFinish(SFSafariViewController)
    SFSafariViewControllerを閉じたことを通知します
    
}
