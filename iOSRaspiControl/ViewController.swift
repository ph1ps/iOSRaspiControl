//
//  ViewController.swift
//  iOSRaspiControl
//
//  Created by Philipp Gabriel on 22.12.16.
//  Copyright © 2016 Philipp Gabriel. All rights reserved.
//

import UIKit
//import SwiftSocket
import Toaster

class ViewController: UIViewController {
    
    //TODO use outlet collection
    @IBOutlet weak var line1Toggle: UISwitch!
    @IBOutlet weak var line2Toggle: UISwitch!
    @IBOutlet weak var line3Toggle: UISwitch!
    
    @IBOutlet weak var waterfallSpeed: UISlider!
    @IBOutlet weak var lightshowSpeed: UISlider!
    
    @IBOutlet weak var waterfallActivity: UIActivityIndicatorView!
    @IBOutlet weak var lightshowActivity: UIActivityIndicatorView!
    
    var pins = [Int: UISwitch]()
    
    var ip: [String] = []
    var toast: Toast? = nil
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion != .motionShake { return }
        
        sendRequest(with: "waterfall\(0)", completion: nil)
        sendRequest(with: "lightshow\(0)", completion: nil)
        
        self.processResponse(lightshow: nil, waterfall: false, pin: true)
        self.processResponse(lightshow: false, waterfall: nil, pin: true)
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pins[7] = line1Toggle
        pins[11] = line2Toggle
        pins[12] = line3Toggle
        
        self.updateValues()
        Timer.scheduledTimer(withTimeInterval: TimeInterval(2), repeats: true) { _ in
            self.updateValues()
        }

        //TODO implement the IP selection with UDP broadcasting
        /*let client = UDPClient(address: "172.17.27.255", port: 3000)
        client.enableBroadcast()
        
        for _ in 1...3 {
            let tesst = client.recv(16)
            let data = String.init(bytes: tesst.0!, encoding: .ascii)
            ip.append(data!)
            print(data!)
        }
        
        client.close()*/
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        }
        
        return nil
    }

    
    func updateValues() {
        sendRequest(with: "status") { response in
            
            guard let bools = self.convertToDictionary(text: response) else {
                return
            }
            
            let lightshow = bools["lightshow"] as? Bool
            let waterfall = bools["waterfall"] as? Bool
            var pin = false
            
            if let lightshow = lightshow, let waterfall = waterfall {
                pin = lightshow || waterfall
            }
            
            self.processResponse(lightshow: lightshow, waterfall: waterfall, pin: !pin)
            
            for (key, value) in bools {
                guard let number = Int(key) else { continue }
                self.pins[number]?.isOn = value as! Bool
            }

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
    
    func sendRequest(with request: String, completion: ((String) -> Void)?) {
        let endpoint = "http://172.17.27.131:3000/" + request

        
        guard let url = URL(string: endpoint) else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = NSURLRequest(url: url)
        let session = URLSession(configuration: .default)

        let task = session.dataTask(with: urlRequest as URLRequest) { (data, response, error) in
            DispatchQueue.main.async {
                guard let data = data else { return }
                completion?(String(data: data, encoding: .ascii) ?? "connection failed")
            }
        }
        task.resume()
    }
    
    @IBAction func lightshow(_ sender: Any) {
        sendRequest(with: "lightshow\(Int(lightshowSpeed.expValue()))") { response in
            self.processResponse(lightshow: true, waterfall: false, pin: false)
        }
    }
    
    @IBAction func waterfall(_ sender: Any) {
        sendRequest(with: "waterfall\(Int(waterfallSpeed.expValue()))") { response in
            self.processResponse(lightshow: false, waterfall: true, pin: false)
        }
    }
    
    @IBAction func toggle(_ sender: UISwitch) {
        
        guard let pin = pins.first(where: { (key, value) in value == sender }) else {
            return
        }
        sendRequest(with: "switch\(pin.key)", completion: nil)
    }
    
    //TODO rename
    @IBAction func buttonClick(_ sender: Any) {
        toast?.cancel()
        toast = nil
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        
        let text = "\(Int(sender.expValue())) τ/2"
        
        if toast == nil {
            toast = Toast(text: text, duration: TimeInterval.infinity)
            ToastView.appearance().backgroundColor = UIColor.white
            ToastView.appearance().textColor = view.backgroundColor
            toast?.show()
        }
        
        toast?.text = text
    }
}

extension UISlider {

    func expValue() -> Float {
        return powf(2, self.value / 100) //Scaling, values are not that high now
    }
}
