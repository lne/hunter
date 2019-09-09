//
//  AppDelegate.swift
//  hunter001
//
//  Created by weidongfeng on 2019/07/07.
//  Copyright © 2019 weidongfeng. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let suiteName: String = "group.thanks.hunter001"
    let keyName: String = "sessionID"

    var window: UIWindow?
    var viewController: ViewController!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.viewController.showHomePage()
        print("url : \(url.absoluteString)")
        print("scheme : \(url.scheme!)")
        print("host : \(url.host!)")
        print("query : \(url.query!)")
        if (url.query != nil) {
            let sessionID = url.query!.split(separator: "=").last
            print("sessionID : \(sessionID!)")
            saveSessionID(sessionID: "\(sessionID!)")
            fetchSessionID()
        }
        return true
    }
    
    // ---------------------------------------------
    // Save session ID to UserDefaults
    // ---------------------------------------------
    private func saveSessionID(sessionID: String) {
        print("saveSessionID")
        // Save Data
        let sharedDefaults: UserDefaults = UserDefaults(suiteName: suiteName)!
        sharedDefaults.set(sessionID, forKey: keyName)
        sharedDefaults.synchronize()
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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

