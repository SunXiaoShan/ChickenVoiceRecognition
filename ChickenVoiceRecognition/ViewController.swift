//
//  ViewController.swift
//  ChickenVoiceRecognition
//
//  Created by Phineas.Huang on 02/02/2018.
//  Copyright © 2018 SunXiaoShan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let TAG_MAP = 112
    let TAG_WEB = 113
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var contentView: UIScrollView!
    
    let chickenVoiceRecognitionMn : ChickenVoiceRecognitionManager = ChickenVoiceRecognitionManager()
    let locationMn : LocationManager = LocationManager()
    let webViewMn : WebViewManager = WebViewManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        chickenVoiceRecognitionMn.delegate = self
        chickenVoiceRecognitionMn.isEnabled()

        addDismissKeyboardEvent()
        imageStatus.image = CommonDefine().getWaitChickenImage()
        chickenVoiceRecognitionMn.recordButtonTapped("en_US")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }

    @IBAction func actionClickButton(_ sender: Any) {
        guard chickenVoiceRecognitionMn.isEnabled() else {
            print("")
            return
        }
        chickenVoiceRecognitionMn.recordButtonTapped("en_US")
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func removeCurrentMap() {
        let map:UIView? = contentView.viewWithTag(TAG_MAP)
        map?.removeFromSuperview()
    }
    
    private func showCurrentLocationMap() {
        removeCurrentMap()
        
        locationMn.moveToCurrentLocation()
        
        let map = locationMn.getMapView(contentView.frame.size)
        map.tag = TAG_MAP
        contentView.addSubview(map)
    }
    
    private func addDismissKeyboardEvent() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    private func showWebView(_ string: String) {
        let web = webViewMn.getWebView(contentView.frame.size)
        webViewMn.loadWebView(string)
        web.tag = TAG_WEB
        contentView.addSubview(web)
    }
    
    private func removeWebView() {
        let web:UIView? = contentView.viewWithTag(TAG_WEB)
        web?.removeFromSuperview()
    }
    
}

extension ViewController : ChickenVoiceRecognitionDelegate {
    func ChickenVRManagerStart(_ manager: ChickenVoiceRecognitionManager) {
        button.setTitle("Stop Recording", for: .normal)
        //textView.text = "This is the UITextView"
    }
    
    func ChickenVRManagerTimeout(_ manager: ChickenVoiceRecognitionManager, _ ret: String) {
        print("timeout : \(ret)")
        button.setTitle("Start Recording", for: .normal)
    }
    
    func ChickenVRManagerOnFinal(_ manager: ChickenVoiceRecognitionManager, _ ret: String) {
        print("final : \(ret)")
        button.setTitle("Start Recording", for: .normal)
        textView.text = ret
        handleVoiceRecognitionResult(ret)
    }
    
    func ChickenVRManagerWaitKeyword(_ manager: ChickenVoiceRecognitionManager) {
        imageView.backgroundColor = UIColor.green
        imageStatus.image = CommonDefine().getWaitChickenImage()
    }
    
    func ChickenVRManagerWaitCommand(_ manager: ChickenVoiceRecognitionManager) {
        imageView.backgroundColor = UIColor.blue
        imageStatus.image = CommonDefine().getCommandChickenImage()
    }
    
    func handleVoiceRecognitionResult(_ resource : String) {
        removeCurrentMap()
        removeWebView()
        
        let search_key = "search"
        if resource.lowercased().hasPrefix(search_key) == true {
            if (resource.count >= search_key.count + 1) {
                var newSTR = resource.dropFirst(search_key.count + 1)
                let swiftyString = newSTR.replacingOccurrences(of: " ", with: "+")
                handleWebViewSearch(String(swiftyString))
            }

        } else if resource.lowercased().range(of:"where am i") != nil {
            handleWhereAmICommand()
        }
    }
    
    func handleWhereAmICommand() {
        showCurrentLocationMap()
    }
    
    func handleWebViewSearch(_ context : String) {
        showWebView(context)
    }
}
