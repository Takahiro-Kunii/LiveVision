//
//  MetadataReader.swift
//  LiveVision
//
//  Created by kunii on 2019/08/29.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import Foundation
import AVFoundation

//  メタデータ読み取り
class MetadataReader: NSObject {
    weak var delegate:MetadataReaderDelegate?
    let output = AVCaptureMetadataOutput()
    
    /// メタデータ用のシリアルキューを用意した
    let queue = DispatchQueue(label: "Queue.metadata")
    
    /// 取り出したいメタデータの種類を限定したいときは指定する
    /// 例）types = [.ean13, .qr]
    var types:[AVMetadataObject.ObjectType] = []
    
    /// 読み取り準備
    ///  outputをセッションに設定してからおこなうこと
    ///  セッションの入力側も設定済みでないといけない
    func prepare() {
        output.setMetadataObjectsDelegate(self, queue:queue)
        
        var availableTypes = output.availableMetadataObjectTypes
        //  typesが空でないなら、typesで指定される種類と利用可能な種類でANDをとる
        if types.count > 0 {
            availableTypes = Array(Set(availableTypes).intersection(Set(types)))
        }
        output.metadataObjectTypes = availableTypes
    }
}

// MARK: - AVCaptureMetadataOutputからの委譲に対応する
extension MetadataReader: AVCaptureMetadataOutputObjectsDelegate {
    /// メタデータ認識通知
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for data in metadataObjects {
            if let codedata = data as? AVMetadataMachineReadableCodeObject {
                delegate?.didRecognizeMetadata(reader: self, codedata: codedata)
            }
        }
    }
}

/// メタデータ認識後の動作を委譲する
@objc protocol MetadataReaderDelegate {
    
    /// メタデータを認識した
    ///
    /// - Parameters:
    ///   - reader: メタデータを認識した装置
    ///   - codedata: 認識したメタデータ
    func didRecognizeMetadata(reader:MetadataReader, codedata:AVMetadataMachineReadableCodeObject)
}

