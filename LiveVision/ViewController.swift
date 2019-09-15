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
    private var circlePopLabel = CirclePopLabel()
    
    private var liveCamera = LiveCamera()
    private var barCodeReader = MetadataReader()

    override func viewDidLoad() {
        super.viewDidLoad()

        monitorView.session = liveCamera.session
        
        liveCamera.delegate = self
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
//          UIApplication.shared.isIdleTimerDisabled = true     //  スリープさせない
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        UIApplication.shared.isIdleTimerDisabled = false
        liveCamera.stop()
        super.viewWillDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        monitorView.syncOrientation()
        circlePopLabel.hide()
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
            UIPasteboard.general.string = text      //  ペーストボードにコピーして別アプリでペーストできるようにする
            if !self.circlePopLabel.isPopping {
                self.circlePopLabel.pop(from:self.monitorView, text:text)
            }
        }
    }
    
}

// MARK: - LiveCameraDelegate対応
extension ViewController: LiveCameraDelegate {
    func liveCameraDidChange(_ camera:LiveCamera, sessionRunning:Bool) {
        DispatchQueue.main.async {
            if sessionRunning {
                self.monitorView.syncOrientation()
            }
        }
    }
    
    func liveCameraIsnotAvailable(_ camera:LiveCamera) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "LiveVision", message: "バーコードやQRコードを読み込みためには、設定アプリでカメラの利用を許可する必要があります", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "そのままでいい",
                                                    style: .cancel,
                                                    handler: nil))
            
            alertController.addAction(UIAlertAction(title: "設定する",
                                                    style: .`default`,
                                                    handler: { _ in
                                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                  options: [:],
                                                                                  completionHandler: nil)
            }))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func liveCameraFailed(_ camera:LiveCamera) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "LiveVision", message: "カメラの起動に失敗しました", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK",
                                                    style: .cancel,
                                                    handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension LiveCameraView {
    func circle() {
        captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        let mask = CALayer()
        mask.frame = bounds
        mask.cornerRadius = bounds.size.width / 2
        mask.backgroundColor = UIColor.black.cgColor
        self.layer.mask = mask
        
        let framelayer = CALayer()
        framelayer.frame = bounds
        framelayer.borderColor = UIColor.orange.cgColor
        framelayer.borderWidth = 4
        framelayer.cornerRadius = bounds.size.width / 2
        self.layer.addSublayer(framelayer)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        circle()
    }
    
}

