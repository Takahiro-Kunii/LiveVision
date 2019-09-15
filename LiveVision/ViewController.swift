//
//  ViewController.swift
//  LiveVision
//
//  Created by kunii on 2019/09/15.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var monitorView: LiveCameraView!
    
    private var liveCamera = LiveCamera()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        monitorView.session = liveCamera.session
        liveCamera.prepare()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        liveCamera.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        liveCamera.stop()
        super.viewWillDisappear(animated)
    }
    
}

