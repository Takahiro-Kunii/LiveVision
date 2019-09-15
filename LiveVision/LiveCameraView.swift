//
//  LiveCameraView.swift
//  LiveVision
//
//  Created by kunii on 2019/08/26.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import UIKit
import AVFoundation

class LiveCameraView: UIView {
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check LiveCameraView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return captureVideoPreviewLayer.session
        }
        set {
            captureVideoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

// MARK: - デバイス回転への拡張
extension LiveCameraView {
    
    /// 現在のiOSデバイスの縦位置・横位置に表示側も連動させる
    func syncOrientation() {
        guard let connection = captureVideoPreviewLayer.connection else { return }
        guard connection.isVideoOrientationSupported else { return }
        var orientation = AVCaptureVideoOrientation.portrait
        if let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) {
            orientation = videoOrientation
        }
        connection.videoOrientation = orientation
    }
}

// MARK: - AVCaptureVideoOrientationの拡張
extension AVCaptureVideoOrientation {
    
    /// UIDeviceOrientation から AVCaptureVideoOrientation へ変換
    /// 変換不能の場合nil
    /// - Parameter deviceOrientation: 変換元
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    /// UIInterfaceOrientation から AVCaptureVideoOrientation へ変換
    /// 変換不能の場合nil
    /// - Parameter interfaceOrientation: 変換元
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }

    /// 自身の設定値を文字列にして返す
    var text: String {
        switch self {
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        default: return "unknown"
        }
    }
}
