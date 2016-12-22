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

        let port = 2345
        
        let client = UDPClient(address: "172.17.27.255", port: 6969)
        client.enableBroadcast()
        let _ = client.send(string: "\(port)")
        client.close()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

