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

        let client = UDPClient(address: "172.17.27.255", port: 6969)
        client.enableBroadcast()
        let _ = client.send(string: "this is test")
        
        for _ in 1...3 {
            let tesst = client.recv(16)
            let data = String.init(bytes: tesst.0!, encoding: .ascii)
            print(data!)
        }
        
        client.close()
        print("holaa")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
