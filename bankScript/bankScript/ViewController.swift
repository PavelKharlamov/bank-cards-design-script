//
//  ViewController.swift
//  bankScript
//
//  Created by Pavel on 10.07.2020.
//  Copyright © 2020 Pavel. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import PromiseKit

class ViewController: UIViewController {
    
    var prefixes = [String]()
    let path = "https://mrbin.io/bins/display"
    
    var data: [String: Any] = [:]
    
    let dispatchGroup = DispatchGroup()
    let dispatchQueue = DispatchQueue(label: "request")
    let dispatchSemaphore = DispatchSemaphore(value: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        data = JsonData().data.convertToDictionary()!
        
        dispatchQueue.async {
            for bins in self.data {
                self.dispatchGroup.enter()
                self.request(bin: bins.key)
            }
        }
        
        dispatchGroup.notify(queue: dispatchQueue) {
            print("END")
        }
    }
    
    func request(bin: String?) {
        guard bin != nil else {
            print("Found nil bin code for request!")
            return
        }
        
        let body: [String: String] = [
            "bin" : bin!
        ]
        
        AF.request(self.path, method: .post, parameters: body, encoding: JSONEncoding.default).responseJSON { response in switch response.result {
        case .success(let JSON):
            let response = JSON as! NSDictionary
            if response.value(forKey: "name") as! String != "Your Bank" {
                let en = response.value(forKey: "nameEn") as! String
                for pref in self.prefixes {
                    if en == pref {
                        self.dispatchSemaphore.signal()
                        return
                    }
                }
                
                //print(response)
                self.createTestModel(by: response, key: bin!)
                
                self.prefixes.append(response.value(forKey: "nameEn") as! String)
                
                self.dispatchSemaphore.signal()
                self.dispatchGroup.leave()
            } else {
                self.dispatchSemaphore.signal()
                self.dispatchGroup.leave()
            }
        case .failure(let error):
            self.dispatchSemaphore.signal()
            self.dispatchGroup.leave()
            }
        }
        self.dispatchSemaphore.wait()
    }
    
    func createTestModel(by response: NSDictionary, key: String) {
        let backgroundGradient = response.value(forKey: "backgroundGradient") as! [String]
        
        let testModel = """
        testedView.apply {
        setBankLogoUrl("https://mrbin.io/bins/\(response.value(forKey: "logo") as! String)"
        setBackground("\(backgroundGradient[0])", "\(backgroundGradient[1])")
        setHolderName("Hanna Siôr")
        setTextColor("\(response.value(forKey: "textColor") as! String)")
        setNumber("\(key)")
        }
        sleep()
        takeScreen("\(response.value(forKey: "nameEn") as! String)")
        
        
        
        """
        print(testModel)
    }
}
