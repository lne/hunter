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
import Foundation

typealias Codable = Decodable & Encodable

struct HttpError: Codable {
    let errors: Array<String>
}

struct CategoryCodable: Codable {
    let id: Int
    let name: String
    let adult: Bool
}

class ShareViewController: SLComposeServiceViewController,
                           TypeViewDelegate, CategoryViewDelegate {
    
    let suiteName: String = "group.thanks.hunter001"
    let keyName: String   = "token"
    let host: String      = "https://adbd88b6.ngrok.io/"
    let general           = "general"
    let professional      = "professional"
    let categoriesBaseURL = "api/v1/categories/"
    let postBaseURL       = "api/v1/posts"
    let unselected        = "(未選択)"
    let selectTypeFiest   = "(投稿先を選択してください)"
    let myTitle           = "感謝×HUNTER"

    let typeItem: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
    let categoryItem: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
    
    var typeDictionary: Dictionary = [String: String]()
    var typeArray: Array<String> = []
    var categoryGeneralDictionary: Dictionary = [String: Int]()
    var categoryGeneralArray: Array<String> = []
    var categoryProfessionalDictionary: Dictionary = [String: Int]()
    var categoryProfessionalArray: Array<String> = []
    var remainPostTimes: Int = 0
    var token: String = ""
    var loadingErrorMessage: String? = nil

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        var valid: Bool = remainPostTimes > 0
        // Category selected
        valid = valid && fetchCategoryID() > 0
        // Token exists
        valid = valid && token.count > 0
        let content = fetchContent()
        valid = valid && !content.isBlank
        return valid
    }

    // ---------------------------------------------
    // Send post request after click post button
    // ---------------------------------------------
    override func didSelectPost() {
        post()
    }
    
    // ---------------------------------------------
    // To add configuration options via table cells at the bottom of the sheet,
    // return an array of SLComposeSheetConfigurationItem here.
    // ---------------------------------------------
    override func configurationItems() -> [Any]! {
        // Initialize typeItem
        typeItem.title = "投稿先"
        typeItem.value = unselected
        typeItem.tapHandler = showTypeView
        
        // Initialize categoryItem
        categoryItem.title = "カテゴリ"
        categoryItem.value = selectTypeFiest
        categoryItem.tapHandler = showCategoryView
        
        return [typeItem, categoryItem]
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
        let categoryID = fetchCategoryID()
        
        // Send post request
        let errorMessage = postRequest(url: url, content: content, category_id: categoryID)
        
        if errorMessage != nil {
            let message: String? = errorMessage?.replacingOccurrences(of: "<br>", with: "")
            // Deal with error
            let context = self.extensionContext!
            let alert = UIAlertController(title: myTitle, message: message!, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
                context.completeRequest(returningItems: nil, completionHandler: nil)
            }))
            present(alert, animated: true, completion: nil)
        } else {
            self.extensionContext?.cancelRequest(withError: NSError(domain:"", code: -1, userInfo:nil))
        }
    }

    // ---------------------------------------------
    // Encode parameters for post
    // ---------------------------------------------
    func encodeParameters(params: [String: String]) -> String {
        let queryItems = params.map { URLQueryItem(name:$0, value:$1)}
        var components = URLComponents()
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }

    // ---------------------------------------------
    // Fetch content for post
    // ---------------------------------------------
    private func postRequest(url: String, content: String, category_id: Int) -> String? {
        // Make URL for posting
        let strPostTo = host + postBaseURL
        let strPostToEncoded = strPostTo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlPostTo = URL(string: strPostToEncoded)!

        // Make Request
        var req = URLRequest(url: urlPostTo)
        req.httpMethod = "POST"

        // Set token to http header
        req.addValue(token, forHTTPHeaderField: "v1-token")

        // Set http body
        let strCategoryID = String(category_id)
        let params: [String: String] = ["content": content, "url": url, "category_id": strCategoryID]
        let encodeParams = encodeParameters(params: params)
        req.httpBody = encodeParams.data(using: .utf8)

        // Send request
        let session = URLSession.shared
        let (data, response, httpError) = session.synchronousDataTask(with: req)
        
        // Parse response
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        var errorMessage: String?
        if statusCode != 201 {
            if data != nil {
                let decoder: JSONDecoder = JSONDecoder()
                do {
                    let json: HttpError = try decoder.decode(HttpError.self, from: data!)
                    errorMessage = json.errors.first ?? "Unknown error"
                    
                } catch let error as NSError {
                    errorMessage = error.localizedDescription
                }
            } else if (httpError != nil) {
                errorMessage = httpError?.localizedDescription
            }
        }
        return errorMessage
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
        let value: String = typeItem.value ?? ""
        let type: String = typeDictionary[value] ?? ""
        return type
    }

    // ---------------------------------------------
    // Fetch category id for post
    // ---------------------------------------------
    private func fetchCategoryID() -> Int {
        let type = fetchType()
        let category = categoryItem.value ?? ""
        var id: Int = 0
        if type == general {
            id = categoryGeneralDictionary[category] ?? 0
        } else {
            id = categoryProfessionalDictionary[category] ?? 0
        }
        return id
    }
    
    // ---------------------------------------------
    // Show TypeView (Tap Handler)
    // ---------------------------------------------
    private func showTypeView() {
        let controller = TypeViewController()
        controller.data = typeArray
        controller.selectedValue = typeItem.value
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    // ---------------------------------------------
    // Show CategoryView (Tap Handler)
    // ---------------------------------------------
    private func showCategoryView() {
        let controller = CategoryViewController()
        let typeKey = typeDictionary[typeItem.value]
        if typeKey == general {
            controller.data = categoryGeneralArray
        } else if typeKey == professional {
            controller.data = categoryProfessionalArray
        } else {
            return
        }
        controller.selectedValue = categoryItem.value
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    // ---------------------------------------------
    // TypeView Delegate Function
    // ---------------------------------------------
    func hideTypeView(viewController: TypeViewController, selectedValue: String) {
        if typeItem.value != selectedValue {
            typeItem.value = selectedValue
            categoryItem.value = unselected
        }
        popConfigurationViewController()
        validate()
    }

    // ---------------------------------------------
    // CategoryView Delegate Function
    // ---------------------------------------------
    func hideCategoryView(viewController: CategoryViewController, selectedValue: String) {
        categoryItem.value = selectedValue
        popConfigurationViewController()
        validate()
    }

    private func validate() {
        validateContent()
    }

    override func textViewDidChange(_ textView: UITextView) {
        validate()
    }

    override func loadView() {
        super.loadView()

        // Initialize basic values
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if loadingErrorMessage != nil {
            view.alpha = 0
            showLoadingError()
        }
    }

    // ---------------------------------------------
    // View did load
    // ---------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = myTitle;
        self.placeholder = "(説明を入力してください)"
        
        // Edit post button name
        let c: UIViewController = self.navigationController!.viewControllers[0]
        c.navigationItem.rightBarButtonItem!.title = "投稿(残1回)"

        // Edit text
        let textView = self.textView
        textView?.attributedText = NSAttributedString(string: "", attributes: nil)
    }
    
    func showLoadingError() {
//        let context = self.extensionContext!
        let alert = UIAlertController(title: myTitle, message: loadingErrorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
//            context.completeRequest(returningItems: nil, completionHandler: nil)
            self.cancel()
            
        }))
        present(alert, animated: true, completion: nil)
    }

    // ---------------------------------------------
    // Fetch token from UserDefaults
    // ---------------------------------------------
    private func fetchToken() -> String {
        // fetch Data
        let sharedDefaults: UserDefaults = UserDefaults(suiteName: suiteName)!
        let data = sharedDefaults.object(forKey: keyName)
        if data != nil {
            return data as! String
        } else {
            return ""
        }
    }

    // ---------------------------------------------
    // Initialize values
    // ---------------------------------------------
    private func initialize() {
        // Init type
        typeArray = ["一般", "専門"]
        typeDictionary = [typeArray.first!: general, typeArray.last!: professional]

        // Init category
        let categoriesURL = host + categoriesBaseURL
        let generalURL = categoriesURL + general
        let categoryGeneralValues = getCategories(stringUrl: generalURL)
        categoryGeneralArray = categoryGeneralValues.0
        categoryGeneralDictionary = categoryGeneralValues.1
        let professionalURL = categoriesURL + professional
        let categoryProfessionalValues  = getCategories(stringUrl: professionalURL)
        categoryProfessionalArray = categoryProfessionalValues.0
        categoryProfessionalDictionary = categoryProfessionalValues.1
        
        // Init remain post times
        remainPostTimes = 1
        
        // Init token
        token = fetchToken()
        
        // Check error
        loadingErrorMessage = getLoadingErrorMessage()
        
    }

    // ---------------------------------------------
    // Check loading error and return error message
    // ---------------------------------------------
    func getLoadingErrorMessage() -> String? {
        var errorMessage: String? = nil
        let tokenInvalid = token.count == 0
        if tokenInvalid {
            errorMessage = "ログインしてから投稿してください。"
        } else {
            let categoryInvalid = categoryGeneralArray.count == 0 ||
                categoryProfessionalArray.count == 0
            if categoryInvalid {
                errorMessage = "サーバに接続できませんでした。"
            }
        }
        return errorMessage
    }

    // ---------------------------------------------
    // Get categories from server
    // ---------------------------------------------
    private func getCategories(stringUrl: String) -> ([String], [String:Int]) {
        var jsonCategories: [CategoryCodable] = []
        
        let url = URL(string: stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        
        let token = fetchToken()
        req.addValue(token, forHTTPHeaderField: "v1-token")
        
        let session = URLSession.shared
        let (data, response, _) = session.synchronousDataTask(with: req)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        
        if statusCode == 200 && data != nil {
            let decoder: JSONDecoder = JSONDecoder()
            do {
                jsonCategories = try decoder.decode([CategoryCodable].self, from: data!)
                
            } catch {
                print(error.localizedDescription)
                jsonCategories = []
            }
        }
        
        var categoryDictionary: Dictionary = [String:Int]()
        var categoryArray: [String] = []
        for category in jsonCategories {
            categoryArray.append(category.name)
            categoryDictionary[category.name] = category.id
        }

        return (categoryArray, categoryDictionary)
    }
}

// *********************************************
// Extension of URLSession
// *********************************************
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

// *********************************************
// Extension of String
// *********************************************
extension String {
    var isBlank: Bool {
        return allSatisfy({ $0.isWhitespace })
    }
}
