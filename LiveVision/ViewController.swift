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
    private var videoFrameCapture = VideoFrameCapture()
    private var filter = Filter.GaussianBlur()
    private var ciContext = CIContext() //  毎回作るのは負荷が大きいのでここで作る

    override func viewDidLoad() {
        super.viewDidLoad()

        monitorView.session = liveCamera.session
        
        liveCamera.delegate = self
        liveCamera.prepare()
        
        liveCamera.add(output:videoFrameCapture.output) {
            didAdd in
            if didAdd {
                self.videoFrameCapture.delegate = self
                self.videoFrameCapture.prepare()
            }
        }
        
        //  パンジェスチャーでブラーノかかり具合を変化させる
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan(_:))))
    }
    
    /// パンジェスチャー中、画面中心からの指の位置を　0 - 1 の範囲に変換しfilterに設定する
    ///
    /// - Parameter gestureRecognizer: パンジェスチャー情報
    @objc func pan(_ gestureRecognizer:UIPanGestureRecognizer) {
        let translation = gestureRecognizer.location(in: view)
        let x = abs(translation.x - view.bounds.midX) / (view.bounds.size.width / 2)
        let y = abs(translation.y - view.bounds.midY) / (view.bounds.size.height / 2)
        filter.set(ratio:Float(max(x, y)))
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
        videoFrameCapture.syncOrientation()
        circlePopLabel.hide()
    }
}

// MARK: - VideoFrameCaptureDelegate対応
extension ViewController: VideoFrameCaptureDelegate {
    
    func videoFrameCapture(_ videoFrameCapture:VideoFrameCapture, cvPixelBuffer pixelBuffer:CVPixelBuffer) {
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        if let image = filter.make(from: ciImage) {
            if let cgImage = ciContext.createCGImage(image, from: image.extent) {
                DispatchQueue.main.async {
                    self.view.layer.contents = cgImage
                }
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
                self.videoFrameCapture.syncOrientation()
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

// MARK: - VideoFrameCapture拡張
extension VideoFrameCapture {
    
    /// 現在のiOSデバイスの縦位置・横位置に表示側も連動させる
    func syncOrientation() {
        guard let connection = output.connection(with: .video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        var orientation = AVCaptureVideoOrientation.portrait
        if let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) {
            orientation = videoOrientation
        }
        connection.videoOrientation = orientation
    }
}
