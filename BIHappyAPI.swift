//
//  BIHappyAPI.swift
//  BIHappy.eu
//
//  Created by Wesley de Groot on 12-10-16.
//  Copyright © 2016 WDGWV. All rights reserved.
//

// Just So Swifty!
import Foundation

// Import WebKit for use of WKWebView and UIWebView
import WebKit

// Import UIKit for all the UI* functions
import UIKit

/**
 **BIHappy Europe™** *API*
 
 The official BIHappy Europe™ API
 
 **Version:** 0.0.1
 
 **Status:** Beta
 
 **Website:** https://www.bihappy.eu/#api
 
 **Supported permissions:** user, manageAccount/profile, notifications
 
 **Supported functions:** Login, Userlist, Profile images
 
     let BIHappy = BIHappyAPI.sharedInstance
         BIHappy.registerKEY("myAPIkeyGoesHere");
         // In the API settings you can change Sandbox Mode
 
         // Ask via BIHappy.eu (default)
         BIHappy.login(permissions: ["profile"]) { result in
             if (result) {
                 print("Welcome \(BIHappy.user)")
             } else {
                 print("Failed")
             }
         }
 
      // Native example (if default doesn't fit)
      // (even the official app is using above example)
      if (BIHappy.login(username: "Username",
                        password: "Password)) {
         let tok = BIHappy.grabToken(); // valid: 24h
      }
 
 **Please allow a connection to:** *https://www.bihappy.eu/api/001/\**
 */
public class BIHappyAPI: NSObject, UIWebViewDelegate, WKNavigationDelegate {
    /**
     This is the shared instance of the BIHappy API
     */
    static let sharedInstance = BIHappyAPI()
    
    /**
     Disable direct calling of the class
     
     private override.
     */
    private override init() {
        self.apiURL = "\(self.apiURL)/\(self.apiVer)"
    }
    
    /**
     The API Version
     
     For registering your API Version.
     */
    private let apiVer: String = "001"
    
    /**
     The API KEY
     
     set your key via `BIHappyAPI().registerKEY(YOURKEYHERE);`
     
     defaults to: 098f6bcd4621d373cade4e832627b4f6
     
     *Please note:* Temporary key will be banned for **24h** after **5** calls.
     */
    private var apiKEY: String = UserDefaults.standard.value(forKey: "BIHappyAPIKey") as! String? ?? "098f6bcd4621d373cade4e832627b4f6"
    
    /**
     The API URL
     
     defaults to: https://www.bihappy.eu/api/
     */
    private var apiURL: String = "https://www.bihappy.eu/api"

    //TODO: Remove this...
    /**
     The Action library (**Deprecated**) (**Removal in final version**)
     
     Translating actions to the correct URL for this api version
     */
    private let actions: [String: String] = [
        "login":            "/user/login", // + /withPermissions/requestedPermissions
        "logout":           "/user/logout",
        "session":          "/user/session", // Get session token
        "profile":          "/user/profile", // Get current profile
        "notifications":    "/user/notifications",
        "readnotification": "/user/notification/%s/read",
        "viewprofile":      "/user/profile/of/%s",
        "finduser":         "/user/find",
        "changePassword":   "/user/changepassword" // Post, only selected platforms
    ]
    
    /**
     BIHappy API (POST) Do we got the data?
     */
    private var BIHAPIPOSTGotData: Bool = false
    
    /**
     BIHappy API (POST) Which data?
     */
    private var BIHAPIPOSTData: [String: String] = [:]
    
    /**
     BIHappy API (GET) Do we got the data?
     */
    private var BIHAPIGETGotData: Bool = false
    
    /**
     BIHappy API (GET) Which data?
     */
    private var BIHAPIGETData: [String: String] = [:]
    
    /**
     BIHappy API waiting for login?
     */
    private var BIHAPILogin: Bool = false
    
    /**
     BIHappy API is the login successfull?
     */
    private var BIHAPIisLoggedin: Bool = false
    
    /**
     BIHappy API token
     */
    private var BIHappyToken: String = UserDefaults.standard.value(forKey: "BIHappyAPIToken") as! String? ?? "INVALID_TOKEN_FOR_USER"
    
    /**
     BIHappy API use WKWebView? (default: true)
     */
    private let useWKWebView: Bool = true
    
    /**
     Had registered a key?
     */
    private var BIHappyKeyRegistered: Bool = false
    
    /**
     BIHappy API which user is logged in?
     */
    public var user: String = UserDefaults.standard.value(forKey: "BIHappyAPIUser") as! String? ?? "None"
    
    /**
     BIHappy API's NSCache for images
     */
    private let BIHappyImageCache = NSCache<NSString, UIImage>()
    
    /**
     BIHappy API's Temporary Directory
     */
    private let BIHappyTemporaryDirectory = NSTemporaryDirectory()
    
    /**
     BIHappy API's Integrated insecure characters (for URLs)
     */
    private let BIHappyInsecureCharacters = [";", "/", "?", ":", "@", "=", "&", "\"", "<", ">", "#", "%", "{", "}", "|", "\\", "^", "~", "[", "]", "`", "$", "!", "*", "'", "(", ")", ","]
    
    /**
     Translates JSON to a Dictionary
     
     - parameter text: the plain text JSON String
     - returns: JSON translated to Dictionary
     */
    private func convertStringToDictionary(text: String) -> [String: AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    private func BIHAPIGet(action: String) -> [String: String] {
        // ?
        return ["GET": "GET"]
    }
    
    /**
     BIHappy API (POST)
     
     - parameter action: which action do we use
     - parameter post: data we'll need to send
     - returns: Array of data
     */
    private func BIHAPIPost(action: String, post: [String: String]) -> [String: String] {
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        // print("URL=\(apiURL)\(apiKEY)\(actions[action]!)")
        
        // Create empty post string
        var postString:String = "";
        
        // Add values
        for (name, value) in post {
            postString = postString.appending("\(name)=\(value)&")
        }
        
        // Add dummy value
        postString = postString.appending("via=BIHappyAPIinterface")
        
        // Create the request
        var request = URLRequest(url: URL(string: "\(apiURL)\(apiKEY)\(actions[action]!)")!)

        // Set HTTP Method to POST
        request.httpMethod = "POST"
        
        // encode for posting...
        request.httpBody = postString.data(using: .utf8)
        
        // do post it
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { // if we got no data
                // general error
                self.BIHAPIPOSTData = ["Status": "Error: \(String(describing: error))"]
                
                // tell the loop that we got some data
                self.BIHAPIPOSTGotData = true
                
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // WE DIDN'T GET A: HTTP/1.0 200 found
                self.BIHAPIPOSTData = ["Status": "Error \(httpStatus.statusCode)"]
                
                // tell the loop that we got some data
                self.BIHAPIPOSTGotData = true
                
                return
            }
            
            // there is a response
            let responseString = String(data: data, encoding: .utf8)
            
            // convert to [string: string]
            self.BIHAPIPOSTData = self.convertStringToDictionary(text: responseString!)! as! [String : String]
            
            // tell the loop that we got some data
            self.BIHAPIPOSTGotData = true
        }
        
        // (run) the task!
        task.resume()
        
        // waiting for data...
        while (!self.BIHAPIPOSTGotData) {
            // waiting
        }
        
        // return data
        return self.BIHAPIPOSTData
    }
    
    /**
     Make a screenshot from the current active window
     
     - returns: UIImage
     */
    private func screenShotMethod() -> UIImage {
        // get the key window's layer!
        let layer = UIApplication.shared.keyWindow!.layer
        
        // get the scale
        let scale = UIScreen.main.scale
        
        // create a imagecontext
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        // render the layer!
        layer.render(in: UIGraphicsGetCurrentContext()!)
        
        // render a screenshot
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        
        // we're done with UIGraphics
        UIGraphicsEndImageContext()
        
        // Return our loved screenshot
        return screenshot!
    }
    
    /**
     BIHappy Login
     
     - parameter permissions: ...
     - returns: bool true/false
     */
    public func login(permissions: [String], completionHandler: @escaping (Bool) -> ()) {
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        // Local development server.
        if (needToLogin()) {
            // translate our permissions
            let permissions = permissions.joined(separator: ",")
            
            // Create LOCAL a URLRequest for handling the API
            //let req = URLRequest(url: NSURL(string: "http://127.0.0.1:8000/?withPermissions=\(permissions.joined(separator: ","))") as! URL)
            
            // Create a URLRequest for handling the API
            let req = URLRequest(url: NSURL(string: "\(apiURL)/user/login/withPermissions/\(permissions)")! as URL)

            // Init a empty view controller for use of the blur and webview.
            let vc = UIViewController.init(nibName: nil, bundle: nil)
            
                // we want a screenshot as background
                vc.view.backgroundColor = UIColor(patternImage: screenShotMethod())
            
            // init UIBlurEffect
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
            
            // set the blur
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView.frame = vc.view.bounds
                blurEffectView.alpha = 0.5
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
                // and we append a blur effect to the background
                vc.view.addSubview(blurEffectView)
            
            // What do we want for our webview.
            
            // The border's height
            let borderHeight: CGFloat = 100
            
            // The border's spacing (from the side of the screen)
            let borderSide: CGFloat   = 40
            
            // create a super x (x-position on screen)
            let x: CGFloat            = vc.view.bounds.origin.x + borderSide
            
            // create a super y (y-position on screen)
            let y: CGFloat            = vc.view.bounds.origin.y + borderHeight
            
            // create our width
            let width: CGFloat        = vc.view.bounds.size.width - (borderSide * 2)
            
            // create our height
            let height: CGFloat       = vc.view.bounds.size.height - (borderHeight * 2)
            
            // Do we use a WKWebView (defaults to true)
            if (self.useWKWebView) {
                // Init the WKWebView
                let wk = WKWebView.init(frame: CGRect(x: x, y: y, width: width, height: height))
                
                    // Load a HTMLString (when the users see 'loading'
                    wk.loadHTMLString("<center><h1>Loading...</h1></center>", baseURL: nil)
                
                    // Load the request for the API
                    wk.load(req)
                
                    // The screen isn't opaque
                    wk.isOpaque = false
                
                    // The background is clear (transparent)
                    wk.backgroundColor = UIColor.clear
                
                    // the delegate is BIHappyAPI
                    wk.navigationDelegate = self
                
                    // Disable the scrolling
                    wk.scrollView.isScrollEnabled = false
                
                    // Add the WKWebView to our 'new' UIViewController
                    vc.view.addSubview(wk)
            } else {
                // Init the UIWebView
                
                let wv = UIWebView.init(frame: CGRect(x: x, y: y, width: width, height: height))
                
                    // Load a HTMLString (when the users see 'loading'
                    wv.loadHTMLString("<center><h1>Loading...</h1></center>", baseURL: nil)
                
                    // Load the request for the API
                    wv.loadRequest(req)
                
                    // The screen isn't opaque
                    wv.isOpaque = false
                
                    // The background is clear (transparent)
                    wv.backgroundColor = UIColor.clear
                
                    // the delegate is BIHappyAPI
                    wv.delegate = self
                
                    // Disable the scrolling
                    wv.scrollView.isScrollEnabled = false
                
                    // Add the UIWebView to our 'new' UIViewController
                    vc.view.addSubview(wv)
            }
            
            // Present our 'new' UIViewController
            UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true, completion: nil)
        } else {
            // Grab info, if needed
            self.BIHappyToken     = UserDefaults.standard.value(forKey: "BIHappyAPIToken") as! String? ?? "INVALID_TOKEN_FOR_USER"
            
            // Tell the API we're logged in
            self.BIHAPIisLoggedin = true
            
            // Tell the waiter we're logged in
            self.BIHAPILogin      = true
        }
        
        DispatchQueue.global().async {
            while !self.BIHAPILogin {
                // wait
            }
            
            DispatchQueue.main.async {
                let formatter = DateFormatter()
                formatter.locale = NSLocale.current
                formatter.dateFormat = "yyyymmddHHmmss"
                
                let date = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                
                let calculator = Int(formatter.string(from: date!))! // 7890000 = 3 months (fails on newyear).
                
                UserDefaults.standard.set(self.BIHappyToken, forKey: "BIHappyAPIToken")
                UserDefaults.standard.set("\(calculator)", forKey: "BIHappyAPIValid")
                UserDefaults.standard.set("\(self.user)", forKey: "BIHappyAPIUser")
                
                UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                completionHandler(self.BIHAPIisLoggedin)
            }
        }
    }
    
    /**
     BIHappy Login
     
     - parameter username: username
     - parameter password: password
     - returns: bool true/false
     */
    public func login(username: String, password: String) -> Bool {
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        let token = BIHAPIPost(action: "login", post: [
            "username": username,
            "password": password
            ])
        
        self.BIHappyToken = token["status"]!
        
        if (self.isValidToken(token: token["status"]!)) {
            // token is valid
            return true
        } else {
            return false
        }
    }
    
    /**
     Is this token valid:
     
     a valid token does not starts with:
     - ERROR
     - NONE
     - DENIED
     
     - parameter token: token
     - returns: bool true/false
     */
    private func isValidToken(token: String) -> Bool {
        return (token != "ERROR" && token != "NONE" && token != "DENIED")
    }
    
    /**
     BIHappy grabToken
     
     - returns: token whenever it is valid or invalid!
     */
    public func grabToken() -> String {
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        if (self.BIHAPILogin) {
            // ok
            if (!self.isValidToken(token: self.BIHappyToken)) {
                // Loading token...
                // Please wait...
                print("Something went wrong!")
                return "ERROR"
            } else {
                return self.BIHappyToken
            }
        } else {
            return self.BIHappyToken
        }
    }
    
    /**
     get the profile image of a user in your image view.
     no need for threads, this function will take care of it.
     
     - parameter forID: user id
     - parameter at: at which imageview?
     */
    public func getProfileImage(forID: Int, at: UIImageView) {
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        // define our image URL
        let imageURL = "https://www.bihappy.eu/images/profile_images/\(forID).png"
        
        // Load image from imageCache
        if let cacheImage = BIHappyImageCache.object(forKey: imageURL as NSString!) as UIImage? {
            // To be sure, run on the mainthread if the command is runned outside a main tread
            DispatchQueue.main.async {
                // set the image
                at.image = cacheImage
            }
            return
        }
        
        // Download image? or get it from the cache (async), and save it.
        DispatchQueue.global(qos: .background).async {
            do {
                // create the image url
                let fileStore = "\(self.BIHappyTemporaryDirectory)\(forID).png"
                
                // Does it exists?
                if (FileManager().fileExists(atPath: fileStore)) {
                    // get the file attibutes
                    let fm = try FileManager().attributesOfItem(atPath: fileStore)
                    
                    // get the filetime
                    let fileTime = fm[FileAttributeKey.creationDate] as? Date
                    
                    // add 0 to timeinterval!
                    let ourTime  = Date().addingTimeInterval(0)
                    
                    // is it valid?
                    if (round((fileTime?.timeIntervalSince(ourTime))!) < 86400) {
                        // Can we unwrap it?
                        if let image = UIImage(contentsOfFile: fileStore) {
                            // Send it to the main queue
                            DispatchQueue.main.async {
                                // set the image
                                at.image = image
                                
                                // save to memory
                                self.BIHappyImageCache.setObject(image, forKey: (imageURL as NSString!))
                                
                                // useless return
                                return
                            }
                            
                            // we did return, so stop loading this function
                            return
                        }
                    }
                    // else { } // IMAGE NEED A REFRESH, DON'T RETURN
                }
                
                // can we download?
                let _imageData = try Data.init(contentsOf: URL(string: imageURL)!)
                
                // can we write, with the "?" we suppress errors, errors will not help us saving
                try? _imageData.write(to: URL(fileURLWithPath: fileStore), options: .atomic)
                
                // display the image
                let imageContents = UIImage.init(data: _imageData)
                
                // the mainqueue
                DispatchQueue.main.async {
                    // if the image is not nil
                    if (imageContents != nil) {
                        //save to memory
                        self.BIHappyImageCache.setObject(imageContents!, forKey: (imageURL as NSString!))
                        
                        // and set image
                        at.image = imageContents
                    }
                }
            }
            catch { }
        }
    }

    /**
     filter those nasty characters from url's
     
     - parameter url: the url with possible weird characters
     
     - returns: a clean string
     */
    private func URLtoSafeName(url: String) -> String {
        // make the URL changeable
        var _changeable = url
        
        // loop trough the insecure characters
        for change in self.BIHappyInsecureCharacters {
            // replace them
            _changeable = change.replacingOccurrences(of: change, with: "-")
        }
        
        // return our safe string
        return _changeable
    }
    
    /**
     register BIHappy API key for use.
     
     *want to test first*? **temporary key**:
     
     `098f6bcd4621d373cade4e832627b4f6`
     
     *Please note:* Temporary key will be banned for **24h** after **5** calls (per-IP).
     
     - parameter key: your personal BIHappy API key
     */
    public func registerKEY(key: String) -> Void {
        if (key != "") {
            if (key == "098f6bcd4621d373cade4e832627b4f6") {
                print("[BIHappy API] WARNING: USING A DEVELOPER KEY, PLEASE REGISTER YOUR OWN KEY AT:")
                print("[BIHappy API] https://www.bibappy.eu/#api")
            }
            self.apiKEY = key
            self.apiURL = self.apiURL.appending("/\(self.apiKEY)")
            self.BIHappyKeyRegistered = true
            UserDefaults.standard.set(key, forKey: "BIHappyAPIKey")
        } else {
            self.registerKEY(key: "098f6bcd4621d373cade4e832627b4f6")
        }
    }
    
    /**
     **BIHappy Forum**
     
     
     All parameters are optional!
     
     - parameter sub: the subforum where you want to fetch the topics of
     
     - parameter topic: the topic where you want fetch the contents of
     
     - returns: a `Array<Any>` with the contents
     */
    public func loadForum(sub: String? = nil, topic: String? = nil) -> Array<Any> {
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        if (sub == nil && topic == nil) {
            print("Load forum Subs")
            let json = BIApiGetAsText(from: "\(self.apiURL)/forum/main")
//            print(json)
            let data = convertStringToDictionary(text: json)
//            print(data)
            return (data?["data"])! as! Array<Any>
        } else if (sub != nil && topic == nil) {
            print("Load Subs")
            let json = BIApiGetAsText(from: "\(self.apiURL)/forum/sub/id/\(String(describing: sub))")
            //            print(json)
            let data = convertStringToDictionary(text: json)
            //            print(data)
            return (data?["data"])! as! Array<Any>
        } else if (sub != nil && topic != nil) {
            print("Load topic + reactions")
            let json = BIApiGetAsText(from: "\(self.apiURL)/forum/topic/id/\(String(describing: topic))")
            //            print(json)
            let data = convertStringToDictionary(text: json)
            //            print(data)
            return (data?["data"])! as! Array<Any>
        } else {
            print("⚠ Invalid call")
        }
        return Array<Any>()
        
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("[WV] Wekit error: \(error.localizedDescription)")
        self.BIHappyToken     = "ERROR"
        self.BIHAPIisLoggedin = false
        self.BIHAPILogin      = true
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[WK] Wekit error: \(error.localizedDescription)")
        self.BIHappyToken     = "ERROR"
        self.BIHAPIisLoggedin = false
        self.BIHAPILogin      = true
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.style.background='transparent';")
        
        webView.evaluateJavaScript("window.BIHappyUsername") { username, error in
            if (error == nil && String(describing: username) != "nil" && String(describing: username) != "Optional()" && String(describing: username) != "") {
                self.user = String(describing: username!)
                UserDefaults.standard.set("\(self.user)", forKey: "BIHappyAPIUser")
                // print("User = \(self.user)")
            }
        }
        
        webView.evaluateJavaScript("window.BIHappyAPIKey") { userToken, error in
            if (error == nil) {
                if (String(describing: userToken) != "Optional(NONE)" && String(describing: userToken) != "nil" && String(describing: userToken) != "Optional()" && String(describing: userToken) != "") {
                    if (String(describing: userToken) != "ERROR" && String(describing: userToken) != "DENIED") {
                        self.BIHappyToken     = String(describing: userToken!)
                        self.BIHAPIisLoggedin = true
                        self.BIHAPILogin      = true
                    } else {
                        self.BIHappyToken     = String(describing: userToken!)
                        self.BIHAPIisLoggedin = false
                        self.BIHAPILogin      = true
                    }
                }
            } else {
                print("Unexpected error=\(String(describing: error))")
                self.BIHappyToken     = "ERROR"
                self.BIHAPIisLoggedin = false
                self.BIHAPILogin      = true
            }
        }
    }
    
    public func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.stringByEvaluatingJavaScript(from: "document.body.style.background='transparent';")
        
        let userName = webView.stringByEvaluatingJavaScript(from: "window.BIHappyUsername")
        if (userName != "ERROR" && userName != "DENIED" && userName != "NONE") {
            self.user = userName!
        }
        
        let userToken = webView.stringByEvaluatingJavaScript(from: "window.BIHappyAPIKey")
        if (userToken != "ERROR" && userToken != "DENIED" && userToken != "NONE") {
            self.BIHappyToken     = userToken!
            self.BIHAPIisLoggedin = true
            self.BIHAPILogin      = true
        } else {
            self.BIHappyToken     = userToken!
            self.BIHAPIisLoggedin = false
            self.BIHAPILogin      = true
        }
    }
    
    private func BIApiGetAsText(from: String) -> String {
        #if DEBUG
            print("ℹ️️ Load URL: \(from)")
        #endif
        
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        // if the string is a URL
        if let myURL = URL(string: from) {
            do {
                // try to load it...
                let myHTMLString = try NSString(contentsOf: myURL, encoding: String.Encoding.utf8.rawValue)
                
                // convert to string and return
                return myHTMLString as String
            }
            catch let error as NSError {
                // shit a error
                return "Error: \(error.localizedDescription)"
            }
        } else {
            // this is no url?
            return "Error: \(from) doesn't seems to be an URL"
        }
    }
    
    public func getAllusers() -> Array<Any> {
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        let data = convertStringToDictionary(text: BIApiGetAsText(from: "\(self.apiURL)/user/list"))
        return (data?["data"])! as! Array<Any>
    }
    
    private func needToLogin() -> Bool {
        // if no key is registered, register last, or default api key!
        if (!BIHappyKeyRegistered) {
            // register key (last, or default api key)
            self.registerKEY(key: self.apiKEY)
        }
        
        // [BIHappyAPIToken: xxxxxxxxxxxxxx]
        // [BIHappyAPIValid: YYYYMMDDHHmmss]
        
        //                                                                                   YYYYMMDDHHIISS
        let validTo = UserDefaults.standard.value(forKey: "BIHappyAPIValid") as! String? ?? "00000000000000"
        let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.dateFormat = "yyyyMMddHHmmss"
        
        if (formatter.string(from: Date()) < validTo) {
            // Seems valid. check & go.
            let BIHappiTok = UserDefaults.standard.value(forKey: "BIHappyAPIToken") as! String? ?? "INVALID_TOKEN_FOR_USER" // Default api key?!
            
            // Check URL
            let checkAtURL = "\(apiURL)/check/token/token/\(BIHappiTok)"
            
            // Is the token still valid?, if not nothing will work!
            if (BIApiGetAsText(from: checkAtURL) == "VALID") {
                
                // no need for login
                return false
            }
        }
        
        // user must re-login
        return true
    }
}

/**
 **BIHappy Europe™** *API*
 
 The official BIHappy Europe™ API
 
 **Class:** DataStore
 
 **Version:** 0.0.1
 
 **Status:** Beta

 */
public class BIHappyDataStore {
    static let sharedInstance = BIHappyDataStore()
    
    public var currentUser: Any = ""
    
    private init () { }
}
