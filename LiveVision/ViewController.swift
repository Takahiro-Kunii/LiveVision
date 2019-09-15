//
//  ViewController.swift
//  LiveVision
//
//  Created by kunii on 2019/08/26.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var monitorView: LiveCameraView!
    
    private var liveCamera = LiveCamera()
    private var barCodeReader = MetadataReader()

    override func viewDidLoad() {
        super.viewDidLoad()

        monitorView.session = liveCamera.session
        liveCamera.prepare()
        
        liveCamera.add(output:barCodeReader.output) {
            didAdd in
            if didAdd {
                self.barCodeReader.delegate = self
                self.barCodeReader.prepare()
            }
        }
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

// MARK: - MetadataReaderDelegate対応
extension ViewController: MetadataReaderDelegate {
    
    /// メタデータが認識された
    ///
    /// - Parameters:
    ///   - reader: メタデータを認識したオブジェクト
    ///   - codedata: メタデータ
    func didRecognizeMetadata(reader: MetadataReader, codedata: AVMetadataMachineReadableCodeObject) {
        guard let text = codedata.stringValue else {
            //  メタデータに文字列がなかったので何もしない
            return
        }
        DispatchQueue.main.async {
            if !Toaster.isPopping {
                Toaster.pop(from:self.view, text:text)
            }
        }
    }
    
}

