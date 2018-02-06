//
//  WebViewManager.swift
//  ChickenVoiceRecognition
//
//  Created by Phineas.Huang on 06/02/2018.
//  Copyright © 2018 SunXiaoShan. All rights reserved.
//

import UIKit
import WebKit

class WebViewManager: NSObject {
    let myWebView :WKWebView = WKWebView()
    override init() {
        super.init()
        myWebView.navigationDelegate = self
    }
    
    open func getWebView(_ size: CGSize) -> WKWebView {
        myWebView.frame.size = size
        return myWebView
    }
    
    open func loadWebView(_ context : String) {
        let googleSearch = "https://google.com/search?q=\(context)"
        
        let eeurl = URL(string: googleSearch)
        if let url = URL(string: googleSearch) {
            myWebView.load(URLRequest(url: url))
        }
    }
}

extension WebViewManager : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Strat to load")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("finish to load")
    }
}
