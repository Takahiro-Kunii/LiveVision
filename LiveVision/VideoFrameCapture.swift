//
//  VideoFrameCapture.swift
//  LiveVision
//
//  Created by kunii on 2019/09/07.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

/// カメラからのライブ画像を受け取りCIImageに変換して連携する
class VideoFrameCapture: NSObject {
    weak var delegate:VideoFrameCaptureDelegate?
    
    let output = AVCaptureVideoDataOutput()

    /// ライブ画像処理用のシリアルキューを用意した
    let queue = DispatchQueue(label: "video capture")
    
    /// ライブ画像受け取り準備
    func prepare() {
        //  output.videoSettings = [:]  //  デフォルトを指定
        //  String(kCVPixelBufferPixelFormatTypeKey):kCVPixelFormatType_32BGRA
        //  やkCVPixelFormatType_420YpCbCr8BiPlanarFullRangeを指定してもエラーにはならないが
        output.setSampleBufferDelegate(self, queue:queue)
        for connection in output.connections {
            //  可能なら手ぶれ補正
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputからの委譲に対応する
extension VideoFrameCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //  CMSampleBufferDataIsReadyでチェックする必要があるか不明（いらないと思うが）
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//            let ciImage = CIImage(cvImageBuffer: pixelBuffer)
//            if let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) {
//                let uiImage = UIImage(cgImage: cgImage)
//            }
            delegate?.videoFrameCapture(self, cvPixelBuffer:pixelBuffer)
        }
    }
}

/// ライブ画像受け取り後の動作を委譲する
@objc protocol VideoFrameCaptureDelegate {
    
    /// 画像を受け取った
    ///
    /// - Parameters:
    ///   - videoFrameCapture: 送り元
    ///   - cvPixelBuffer: ライブ画像
    func videoFrameCapture(_ videoFrameCapture:VideoFrameCapture, cvPixelBuffer:CVPixelBuffer)
}

