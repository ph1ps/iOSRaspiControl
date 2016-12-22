//
//  ViewController.swift
//  iOSRaspiControl
//
//  Created by Philipp Gabriel on 22.12.16.
//  Copyright © 2016 Philipp Gabriel. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let client = TCPClient(address: "www.apple.com", port: 80)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

