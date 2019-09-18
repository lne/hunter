//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by dongfeng.wei on 2019/09/08.
//  Copyright © 2019 Cohcoh Co., Ltd. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Foundation

// JSON parser
typealias Codable = Decodable & Encodable

// Http error parsing by JSONDecoder
struct HttpError: Codable {
    let errors: Array<String>
}

// Categories parsing by JSONDecoder
struct CategoryCodable: Codable {
    let id: Int
    let name: String
    let adult: Bool
}

// Post types parsing by JSONDecoder
struct TypeCodable: Codable {
    let type: String
    let name: String
    let resource_path: String
}

// Remain post times parsing by JSONDecoder
struct RemainCodable: Codable {
    let remain: Int
}

// *********************************************
// ShareViewController
// *********************************************
class ShareViewController: SLComposeServiceViewController,
                           TypeViewDelegate, CategoryViewDelegate {
    
    let suiteName: String = "group.thanks.hunter001"
    let keyName: String   = "token"
    let host: String      = "https://stage.kanshahunter.com"
    let env: String       = "stage"

    let typesBaseURL      = "/api/v1/categories"
    let postBaseURL       = "/api/v1/posts"
    let remainBaseURL     = "/api/v1/users/post_remain"
    let general           = "general"
    let professional      = "professional"

    let unselected        = "(未選択)"
    let selectTypeFiest   = "(投稿先を選択してください)"
    let myTitle           = "感謝×HUNTER"
    let typeItemTitle     = "投稿先"
    let categoryItemTitle = "カテゴリ"
    let errorMsgLogin     = "ログインしてから投稿してください。"
    let errorMsgServer    = "サーバに接続できませんでした。"
    let errorMsgLimited   = "投稿は一日に3回までとなっております。明日のご投稿をお待ちしております。"
    let errorMsgURL       = "投稿するURLを選択してください。"
    let strPlaceholder    = "(説明を入力してください)"
    let strBeforePostBtn  = "投稿(残"
    let strAfterPostBtn   = "回)"

    let typeItem: SLComposeSheetConfigurationItem     = SLComposeSheetConfigurationItem()
    let categoryItem: SLComposeSheetConfigurationItem = SLComposeSheetConfigurationItem()
    
    var typeDictionary: Dictionary                    = [String: String]()
    var typeArray: Array<String>                      = []
    var categoryGeneralDictionary: Dictionary         = [String: Int]()
    var categoryGeneralArray: Array<String>           = []
    var categoryProfessionalDictionary: Dictionary    = [String: Int]()
    var categoryProfessionalArray: Array<String>      = []
    var remainPostTimes: Int         = 0
    var token: String                = ""
    var shareURL: String?            = nil
    var loadingErrorMessage: String? = nil
    

    // ---------------------------------------------
    // Validation of post contents
    // ---------------------------------------------
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        var valid: Bool = remainPostTimes > 0
        // Category selected
        valid = valid && fetchCategoryID() > 0
        // Token exists
        valid = valid && token.count > 0
        // Content exists
        let content = fetchContent()
        valid = valid && !content.isBlank
        // URL exists
        valid = valid && validURL()
        return valid
    }
    
    // ---------------------------------------------
    // Validation of post contents
    // ---------------------------------------------
    private func validURL() -> Bool {
        if shareURL != nil {
            return true
        }
        let extensionItem: NSExtensionItem = self.extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = extensionItem.attachments?.first ?? NSItemProvider()
        let puclicURL = String(kUTTypeURL)  // "public.url"
        let hasURL = itemProvider.hasItemConformingToTypeIdentifier(puclicURL)

        return hasURL
    }

    // ---------------------------------------------
    // To add configuration options via table cells at the bottom of the sheet,
    // return an array of SLComposeSheetConfigurationItem here.
    // ---------------------------------------------
    override func configurationItems() -> [Any]! {
        // Initialize typeItem
        typeItem.title = typeItemTitle
        typeItem.value = unselected
        typeItem.tapHandler = showTypeView
        
        // Initialize categoryItem
        categoryItem.title = categoryItemTitle
        categoryItem.value = selectTypeFiest
        categoryItem.tapHandler = showCategoryView
        
        return [typeItem, categoryItem]
    }

    // ---------------------------------------------
    // Send post request after click post button
    // ---------------------------------------------
    override func didSelectPost() {
        post()
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
            // When publicURL exists
            itemProvider.loadItem(forTypeIdentifier: puclicURL, options: nil, completionHandler: { (item, error) in
                // Get URL and do post
                if let nsURL: NSURL = item as? NSURL {
                    let url = nsURL.absoluteString ?? ""
                    self.post(url: url)
                }
            })
        } else if shareURL != nil {
            // When shareURL exists
            self.post(url: shareURL!)
        } else {
            cancel()
        }
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
            cancel()
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
        if env == "stage" {
            req.addValue("QVJJR0FUT1U=", forHTTPHeaderField: "X-KANSHA")
        }

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
            errorMessage = parseHttpError(data: data, httpError: httpError)
        }
        return errorMessage
    }

    // ---------------------------------------------
    // Parse http error
    // ---------------------------------------------
    private func parseHttpError(data: Data?, httpError: Error?) -> String? {
        var errorMessage: String?
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

    // ---------------------------------------------
    // Validate contents
    // ---------------------------------------------
    private func validate() {
        validateContent()
    }

    // ---------------------------------------------
    // Event on text changed
    // ---------------------------------------------
    override func textViewDidChange(_ textView: UITextView) {
        validate()
    }

    // ---------------------------------------------
    // Initialize on loading view
    // ---------------------------------------------
    override func loadView() {
        super.loadView()

        // Initialize basic values
        initialize()
    }
    
    // ---------------------------------------------
    // Show error when view will appear
    // ---------------------------------------------
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
        self.placeholder = strPlaceholder
        
        // Edit post button name
        let c: UIViewController = self.navigationController!.viewControllers[0]
        let title = strBeforePostBtn + String(remainPostTimes) + strAfterPostBtn
        c.navigationItem.rightBarButtonItem!.title = title

        // Init share URL and textView
        initShareURL()
        let textView = self.textView
        textView?.attributedText = NSAttributedString(string: "", attributes: nil)
    }

    // ---------------------------------------------
    // Initialize shareURL
    // ---------------------------------------------
    private func initShareURL() {
        let text: String = self.contentText
        do {
            let regex = try NSRegularExpression(pattern: "^https?://.+", options: [])
            let resultNum = regex.numberOfMatches(in: text, options: NSRegularExpression.MatchingOptions(rawValue: 0) , range: NSMakeRange(0, text.count))
            if resultNum >= 1 {
                shareURL = text
            }
        } catch {
            shareURL = nil
        }
    }

    // ---------------------------------------------
    // Show error by UIAlertController
    // ---------------------------------------------
    func showError(message: String) {
        let alert = UIAlertController(title: myTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
            self.cancel()
            
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // ---------------------------------------------
    // Show error before share view
    // ---------------------------------------------
    func showLoadingError() {
        if loadingErrorMessage != nil {
            showError(message: loadingErrorMessage!)
        }
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
        var generalURL: String = ""
        var professionalURL: String = ""
        // Init type
        let types = getTypes()
        for type in types {
            typeArray.append(type.name)
            typeDictionary[type.name] = type.type
            if type.type == general {
                generalURL = host + type.resource_path
            } else if type.type == professional {
                professionalURL = host + type.resource_path
            }
        }

        // Init category
        if generalURL.count > 0 {
            let categoryGeneralValues = getCategories(stringUrl: generalURL)
            categoryGeneralArray = categoryGeneralValues.0
            categoryGeneralDictionary = categoryGeneralValues.1
        }
        if professionalURL.count > 0 {
            let categoryProfessionalValues  = getCategories(stringUrl: professionalURL)
            categoryProfessionalArray = categoryProfessionalValues.0
            categoryProfessionalDictionary = categoryProfessionalValues.1
        }

        // Init remain post times
        remainPostTimes = getRemainTimes()

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
            errorMessage = errorMsgLogin
        } else {
            let categoryInvalid = categoryGeneralArray.count == 0 ||
                categoryProfessionalArray.count == 0
            if categoryInvalid {
                errorMessage = errorMsgServer
            } else if remainPostTimes == 0 {
                errorMessage = errorMsgLimited
            } else if !validURL() {
                errorMessage = errorMsgURL
            }
        }
        return errorMessage
    }

    // ---------------------------------------------
    // Get remainTimes from server
    // ---------------------------------------------
    func getRemainTimes() -> Int {
        var times = 0
        let stringUrl = host + remainBaseURL
        
        let url = URL(string: stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        
        let token = fetchToken()
        req.addValue(token, forHTTPHeaderField: "v1-token")
        if env == "stage" {
            req.addValue("QVJJR0FUT1U=", forHTTPHeaderField: "X-KANSHA")
        }
        let session = URLSession.shared
        let (data, response, _) = session.synchronousDataTask(with: req)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        if statusCode == 200 && data != nil {
            let decoder: JSONDecoder = JSONDecoder()
            do {
                let remainCodable = try decoder.decode(RemainCodable.self, from: data!)
                times = remainCodable.remain
            } catch {
                times = 0
            }
        }
        
        return times
    }

    // ---------------------------------------------
    // Get categories from server
    // ---------------------------------------------
    func getTypes() -> [TypeCodable] {
        var types: [TypeCodable] = []
        let stringUrl = host + typesBaseURL
        
        let url = URL(string: stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        
        let token = fetchToken()
        req.addValue(token, forHTTPHeaderField: "v1-token")
        if env == "stage" {
            req.addValue("QVJJR0FUT1U=", forHTTPHeaderField: "X-KANSHA")
        }
        let session = URLSession.shared
        let (data, response, _) = session.synchronousDataTask(with: req)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        if statusCode == 200 && data != nil {
            let decoder: JSONDecoder = JSONDecoder()
            do {
                types = try decoder.decode([TypeCodable].self, from: data!)
                
            } catch {
                types = []
            }
        }
        
        return types
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
        if env == "stage" {
            req.addValue("QVJJR0FUT1U=", forHTTPHeaderField: "X-KANSHA")
        }

        let session = URLSession.shared
        let (data, response, _) = session.synchronousDataTask(with: req)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        
        if statusCode == 200 && data != nil {
            let decoder: JSONDecoder = JSONDecoder()
            do {
                jsonCategories = try decoder.decode([CategoryCodable].self, from: data!)
                
            } catch {
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
