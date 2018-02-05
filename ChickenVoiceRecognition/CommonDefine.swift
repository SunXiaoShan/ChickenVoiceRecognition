//
//  CommonDefine.swift
//  ChickenVoiceRecognition
//
//  Created by Phineas.Huang on 05/02/2018.
//  Copyright © 2018 SunXiaoShan. All rights reserved.
//

import UIKit

// reference: https://www.flaticon.com
class CommonDefine: NSObject {
    private func getWaitChickenName() -> String {
        return "003-chicken-2"
    }
    
    private func getCommandChickenName() -> String {
        return "005-chicken"
    }
    
    private func getImageView(_ name:String) -> UIImage {
        return UIImage(named: name)!
    }
    
    func getWaitChickenImage() -> UIImage {
        return getImageView(getWaitChickenName())
    }
    
    func getCommandChickenImage() -> UIImage {
        return getImageView(getCommandChickenName())
    }
}
