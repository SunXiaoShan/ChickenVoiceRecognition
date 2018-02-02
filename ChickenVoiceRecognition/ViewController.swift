//
//  ViewController.swift
//  ChickenVoiceRecognition
//
//  Created by Phineas.Huang on 02/02/2018.
//  Copyright © 2018 SunXiaoShan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var textView: UITextView!
    let mn : ChickenVoiceRecognitionManager = ChickenVoiceRecognitionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mn.delegate = self
        mn.isEnabled()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }

    @IBAction func actionClickButton(_ sender: Any) {
        guard mn.isEnabled() else {
            print("")
            return
        }
        mn.recordButtonTapped("en_US")
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

extension ViewController : ChickenVoiceRecognitionDelegate {
    func ChickenVRManagerStart(_ manager: ChickenVoiceRecognitionManager) {
        button.setTitle("Stop Recording", for: .normal)
        textView.text = "This is the UITextView"
    }
    
    func ChickenVRManagerTimeout(_ manager: ChickenVoiceRecognitionManager, _ ret: String) {
        print("timeout : \(ret)")
        button.setTitle("Start Recording", for: .normal)
    }
    
    func ChickenVRManagerOnFinal(_ manager: ChickenVoiceRecognitionManager, _ ret: String) {
        print("final : \(ret)")
        button.setTitle("Start Recording", for: .normal)
        textView.text = ret
    }
}
