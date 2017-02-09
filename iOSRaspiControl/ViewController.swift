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
    
    //TODO use outlet connection
    @IBOutlet weak var line1Toggle: UISwitch!
    @IBOutlet weak var line2Toggle: UISwitch!
    @IBOutlet weak var line3Toggle: UISwitch!
    
    @IBOutlet weak var waterfallSpeed: UISlider!
    @IBOutlet weak var lightshowSpeed: UISlider!
    
    @IBOutlet weak var waterfallActivity: UIActivityIndicatorView!
    @IBOutlet weak var lightshowActivity: UIActivityIndicatorView!
    
    var pins = [Int: UISwitch]()
    
    var ip: [String] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pins[7] = line1Toggle
        pins[11] = line2Toggle
        pins[12] = line3Toggle
        
        updateToggles()
        
        //TODO implement the IP selection with UDP broadcasting
        /*let client = UDPClient(address: "172.17.27.255", port: 3000)
        client.enableBroadcast()
        
        for _ in 1...3 {
            let tesst = client.recv(16)
            let data = String.init(bytes: tesst.0!, encoding: .ascii)
            ip.append(data!)
            print(data!)
        }
        
        client.close()
        print("holaa")*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateToggles() {
        for (key, value) in pins {
            nodeBackend(with: "status\(key)", completion: { response in
                value.isOn = response == "1" ? true : false
            })
        }
    }
    
    func processResponse(lightshow: Bool?, waterfall: Bool?, pin: Bool?) {
    
        if let lightshow = lightshow {
            lightshow ? self.lightshowActivity.startAnimating() : self.lightshowActivity.stopAnimating()
        }
        
        if let waterfall = waterfall {
            waterfall ? self.waterfallActivity.startAnimating() : self.waterfallActivity.stopAnimating()
        }
        
        if let pin = pin {
            self.pins.values.forEach { $0.isEnabled = pin }
        }
        
    }
    
    func nodeBackend(with request: String, completion: ((String) -> Void)?) {
        let todoEndpoint = "http://172.17.27.131:3000/" + request
        
        print(todoEndpoint)
        
        guard let url = URL(string: todoEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = NSURLRequest(url: url)
        let session = URLSession(configuration: .default)

        let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                guard let data = data else { return }
                completion?(String(data: data, encoding: .ascii) ?? "connection failed")
            }
        })
        task.resume()
    }
    
    @IBAction func lightshow(_ sender: Any) {
        nodeBackend(with: "lightshow\(Int(lightshowSpeed.value))", completion: { response in
            self.processResponse(lightshow: true, waterfall: false, pin: false)
            print(response)
        })
    }
    
    @IBAction func waterfall(_ sender: Any) {
        nodeBackend(with: "waterfall\(Int(waterfallSpeed.value))", completion: { response in
            self.processResponse(lightshow: false, waterfall: true, pin: false)
            print(response)
        })
    }
    
    @IBAction func toggle(_ sender: UISwitch) {
        let pin = pins.first(where: { (key, value) in value == sender })!
        
        nodeBackend(with: "switch\(pin.key)", completion: { response in
            sender.isOn = response == "1" ? true : false
        })
    }
    
    @IBAction func stopWaterfall(_ sender: Any) {
        nodeBackend(with: "waterfall\(0)", completion: { _ in
            self.processResponse(lightshow: nil, waterfall: false, pin: true)
            self.updateToggles()
        })
    }
    
    @IBAction func stopLightshow(_ sender: Any) {
        nodeBackend(with: "lightshow\(0)", completion: { _ in
            self.processResponse(lightshow: false, waterfall: nil, pin: true)
            self.updateToggles()
        })
    }
}
