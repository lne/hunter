//
//  ViewController.swift
//  hunter001
//
//  Created by weidongfeng on 2019/07/07.
//  Copyright © 2019 weidongfeng. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class ViewController: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    public var safariVC: SFSafariViewController!
    private var needLogin: Bool = true
    
    override func viewDidLoad() {
        authorize()
        fetchSessionID()
        super.viewDidLoad()
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.viewController = self
//        let config = WKWebViewConfiguration()
//        config.allowsInlineMediaPlayback = true
        
//        // WKWebViewを生成
//        webView = WKWebView(frame:CGRect(x:0, y:0, width:self.view.bounds.size.width, height:self.view.bounds.size.height), configuration: config)
        
//        let urlString = "https://kanshahunter.com/"
//        let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
//        let url = NSURL(string: encodedUrlString!)
//        let request = NSURLRequest(url: url! as URL)
        
//        let userAgentStr = "My App WebView"
//        webView.customUserAgent = userAgentStr
//        webView.load(request as URLRequest)
        
//        self.view.addSubview(webView)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        var webPage: String
        if (needLogin) {
            webPage = "https://a74632eb.ngrok.io/users/login?app=ios"
        } else {
            webPage = "https://a74632eb.ngrok.io/"
        }
        safariVC = SFSafariViewController(url: NSURL(string: webPage)! as URL)
        safariVC.delegate = self
        safariVC.dismissButtonStyle = SFSafariViewController.DismissButtonStyle.close
        present(safariVC, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showHomePage() {
        print("showHomePage")
        safariVC.dismiss(animated: true, completion: nil)
        needLogin = false
    }
    
    // ---------------------------------------------
    // Fetch session ID from UserDefaults (Temporarily)
    // ---------------------------------------------
    private func fetchSessionID() -> String {
        let suiteName: String = "group.thanks.hunter001"
        let keyName: String = "sessionID"
        // fetch Data
        let sharedDefaults: UserDefaults = UserDefaults(suiteName: suiteName)!
        let sessionID = sharedDefaults.object(forKey: keyName)
        print("fetchSessionID : \(sessionID!)")
        return "\(sessionID!)"
    }
    
    private func authorize() -> Bool {
        let stringUrl = "https://a74632eb.ngrok.io/posts/new/general"
        let url = URL(string: stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        // First
        let jar = HTTPCookieStorage.shared
        let cookieHeaderField = ["Set-Cookie": "_session_id=\(fetchSessionID());Secure"] // Or ["Set-Cookie": "key=value, key2=value2"] for multiple cookies
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: cookieHeaderField, for: url)
        jar.setCookies(cookies, for: url, mainDocumentURL: url)
        

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        // nouse
        //req.addValue("_session_id=\(fetchSessionID())", forHTTPHeaderField: "Cookie")
        
        let (data, response, error) = URLSession.shared.synchronousDataTask(with: req)
        let httpResponse = response as? HTTPURLResponse
        print(httpResponse?.statusCode)
        let str: String? = String(data: data!, encoding: .utf8)
        print(str)
        if (error == nil) {
            return true
        } else {
            return false
        }
    }
}

extension URLSession {
    func synchronousDataTask(with url: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = self.dataTask(with: url) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}

// MARK: SFSafariViewControllerDelegate
extension ViewController: SFSafariViewControllerDelegate {
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        print("didCompleteInitialLoad")
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        print("safariViewControllerDidFinish")
        exit(0)
        //dispAlert()
    }
    // ボタンを押下した時にアラートを表示するメソッド
    @IBAction func dispAlert() {
        
        // ① UIAlertControllerクラスのインスタンスを生成
        // タイトル, メッセージ, Alertのスタイルを指定する
        // 第3引数のpreferredStyleでアラートの表示スタイルを指定する
        let alert: UIAlertController = UIAlertController(title: "アラート表示", message: "保存してもいいですか？", preferredStyle:  UIAlertController.Style.alert)
        
        // ② Actionの設定
        // Action初期化時にタイトル, スタイル, 押された時に実行されるハンドラを指定する
        // 第3引数のUIAlertActionStyleでボタンのスタイルを指定する
        // OKボタン
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("OK")
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("Cancel")
        })
        
        // ③ UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        safariVC.present(alert, animated: true, completion: nil)
    }
}
