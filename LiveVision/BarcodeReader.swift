//
//  BarcodeReader.swift
//  LiveVision
//
//  Created by kunii on 2019/09/07.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import Foundation
import Vision

class BarcodeReader {
    
    /// CVPixelBufferを受け取って検知したバーコード情報をreporterを通して処理する。
    /// バーコードが検知されなければreporterは呼ばれない。検知するしないに関わらず処理が終わるまではブロックする。
    ///
    /// - Parameters:
    ///   - cvPixelBuffer: 調べる画像
    ///   - reporter: 検知したバーコード情報を処理するクロージャ
    class func probe(cvPixelBuffer pixelBuffer: CVPixelBuffer, reporter:@escaping (VNBarcodeObservation)->Void) {
        probe(handler:{
            VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [.properties : ""])
        }, reporter:reporter)
    }

    /// probe(cvPixelBuffer:... のCIImage版
    /// CIImageを受け取って検知したバーコード情報をreporterを通して処理する。
    /// バーコードが検知されなければreporterは呼ばれない。検知するしないに関わらず処理が終わるまではブロックする。
    ///
    /// - Parameters:
    ///   - ciImage: 調べる画像
    ///   - reporter: 検知したバーコード情報を処理するクロージャ
    class func probe(ciImage:CIImage, reporter:@escaping (VNBarcodeObservation)->Void) {
        probe(handler:{
            VNImageRequestHandler(ciImage: ciImage, options: [.properties : ""])
        }, reporter:reporter)
    }

    /// probe(cvPixelBuffer:... のCGImage版
    /// CGImageを受け取って検知したバーコード情報をreporterを通して処理する。
    /// バーコードが検知されなければreporterは呼ばれない。検知するしないに関わらず処理が終わるまではブロックする。
    ///
    /// - Parameters:
    ///   - cgImage: 調べる画像
    ///   - reporter: 検知したバーコード情報を処理するクロージャ
    class func probe(cgImage: CGImage, reporter:@escaping (VNBarcodeObservation)->Void) {
        probe(handler:{
            VNImageRequestHandler(cgImage: cgImage, options: [.properties : ""])
        }, reporter:reporter)
    }

    /// 指定したVNImageRequestHandlerが検知したバーコード情報をreporterを通して処理する。
    /// バーコードが検知されなければreporterは呼ばれない。検知するしないに関わらず処理が終わるまではブロックする。
    ///
    /// - Parameters:
    ///   - handler: VNImageRequestHandlerを作成するクロージャ
    ///   - reporter: 検知したバーコード情報を処理するクロージャ
    class func probe(handler:()->VNImageRequestHandler, reporter:@escaping (VNBarcodeObservation)->Void) {
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            guard let results = request.results else {
                NSLog("VNDetectBarcodesRequest failed.")
                return
            }
            
            //  検出物ごとにVNBarcodeObservationか調べ、そうであればreporterで処理する
            for result in results {
                guard let barcode = result as? VNBarcodeObservation else { continue }
                reporter(barcode)
            }
        }
        
        let handler = handler()
        
        guard let _ = try? handler.perform([barcodeRequest]) else {
            NSLog("Could not perform barcode-request!")
            return
        }
    }
}


// MARK: - VNBarcodeObservationの拡張
extension VNBarcodeObservation {
    
    /// 自身の情報を文字列にする。description側はいじらない
    var report: String  {
        var string = "symbology: \(symbology.rawValue)"
        if let payloadStringValue = payloadStringValue {
            string += "\npayloadStringValue: \(payloadStringValue)"
        }
        if let desc = barcodeDescriptor as? CIQRCodeDescriptor {
            string += "\n" + desc.report
        }
        return string
    }
}

// MARK: - CIQRCodeDescriptorの拡張
extension CIQRCodeDescriptor {

    /// 自身の情報を文字列にする。description側はいじらない
    var report:String {
        var string = "Symbol-Version: \(symbolVersion)"
        string += "\nError-Correction-Level: \(errorCorrectionLevel)"
        if let content = String(data: errorCorrectedPayload, encoding: .utf8) {
            string += "\nPayload: \(content)"
        }
        return string
    }
}
