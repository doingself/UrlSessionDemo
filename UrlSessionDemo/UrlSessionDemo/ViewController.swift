//
//  ViewController.swift
//  UrlSessionDemo
//
//  Created by rigour on 2017/12/19.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        SycRequest.shared.shouldLog = true
        SycRequest.shared.get(urlStr: "http://www.baidu.com/s?ie=UTF-8&wd=urlsession", param: nil) { (result) in
            // result is any
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

