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
