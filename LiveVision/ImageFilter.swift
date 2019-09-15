//
//  ImageFilter.swift
//  LiveVision
//
//  Created by kunii on 2019/09/07.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import Foundation
import CoreImage

/// フィルター用共通メソッドを提供
protocol ImageFilter {
    func make(from image:CIImage) -> CIImage?
}

struct Filter {
    
    /// ガウスぼかしフィルタ
    class GaussianBlur: ImageFilter {
        /// ガウスブラーをかける前に、元画像の大きさを変更する比率
        private let scale: CGFloat = 0.2
        
        /// ガウスブラー量
        private var sigma: Double = 10
        
        /// 受け取った画像をscale倍してsigmaで指定されるガウスブラーをかけた画像を戻す
        /// sigma分、内側にクロップもする。これをしないとガウスブラーによって白くなった部分が残るから
        ///
        /// - Parameter image: 元画像
        /// - Returns: 加工済み画像
        func make(from image:CIImage) -> CIImage? {

            //  切り取り矩形を計算
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            let delta = CGFloat(sigma)
            var area = image.extent.applying(transform).insetBy(dx: delta, dy: delta)
            area.rounding()     //  小数点以下を排除しないとCALayerのcontentsに指定した時にがたついてしまう
            return image
                .applyingFilter("CIAffineTransform", parameters: [  //  スケーリング
                    kCIInputTransformKey : transform
                    ])
                .applyingGaussianBlur(sigma: sigma)                 //  ガウスブラー
                .cropped(to: area)                                  //  切り取り
        }

        /// 0-1の範囲をガウスブラーの0-30に対応させて、make(from:)での効果を指定する
        ///
        /// - Parameter ratio: 効果の比率 0-1
        func set(ratio:Float) {
            sigma = Double(ratio) * 30
        }
    }
    
    /// セピアトーンにするフィルタ　旧式の書き方
    class SepiaToneOld: ImageFilter {
        
        /// セピアトーンをかける
        private let filter:CIFilter? = {
            if let filter = CIFilter(name:"CISepiaTone") {
                filter.setValue(1.0, forKey:kCIInputIntensityKey)
                return filter
            }
            return nil
        }()
        
        /// 受け取った画像にセピアトーンをかけた画像を戻す
        ///
        /// - Parameter image: 元画像
        /// - Returns: 加工済み画像
        func make(from image:CIImage) -> CIImage? {
            // セピアトーンをかける
            filter?.setValue(image, forKey: kCIInputImageKey)
            let filterdImage = filter?.outputImage
            filter?.setValue(nil, forKey: kCIInputImageKey)
            return filterdImage
        }
        
        /// 0-1の範囲をセピアトーンの量とし、make(from:)での効果を指定する
        ///
        /// - Parameter ratio: 効果の比率 0-1
        func set(ratio:Float) {
            filter?.setValue(ratio, forKey:kCIInputIntensityKey)
        }
    }
    
    /// ガウスぼかしフィルタ　旧式の書き方
    class GaussianBlurOld: ImageFilter {
        /// ガウスブラーをかける前に、元画像の大きさを変更する比率
        private let scale: CGFloat = 0.2

        /// ガウスブラー量
        private var redius: CGFloat = 20
        
        /// 元画像の大きさを変更する
        private lazy var scalefilter:CIFilter? = {
            if let filter = CIFilter(name:"CIAffineTransform") {
                let transform = CGAffineTransform(scaleX: scale, y: scale)
                filter.setValue(transform, forKey: kCIInputTransformKey)
                return filter
            }
            return nil
        }()

        /// ガウスブラーをかける
        private lazy var filter:CIFilter? = {
            if let filter = CIFilter(name:"CIGaussianBlur") {
                filter.setValue(redius, forKey:kCIInputRadiusKey)
                return filter
            }
            return nil
        }()
        
        /// 画像を切り取る
        private let cropfilter = CIFilter(name:"CICrop")
        
        /// 受け取った画像をscale倍してsigmaで指定されるガウスブラーをかけた画像を戻す
        /// sigma分、内側にクロップもする。これをしないとガウスブラーによって白くなった部分が残るから
        ///
        /// - Parameter image: 元画像
        /// - Returns: 加工済み画像
        func make(from image:CIImage) -> CIImage? {
            
            //  切り取り矩形を計算
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            let delta = CGFloat(redius)
            var area = image.extent.applying(transform).insetBy(dx: delta, dy: delta)
            area.rounding()     //  小数点以下を排除しないとCALayerのcontentsに指定した時にがたついてしまう
            cropfilter?.setValue(area, forKey: "inputRectangle")

            //  スケーリング
            scalefilter?.setValue(image, forKey: kCIInputImageKey)
            let scaledImage = scalefilter?.outputImage
            scalefilter?.setValue(nil, forKey: kCIInputImageKey)
            
            //  ガウスブラー
            filter?.setValue(scaledImage, forKey: kCIInputImageKey)
            let filterdImage = filter?.outputImage
            filter?.setValue(nil, forKey: kCIInputImageKey)
            
            //  切り取り
            cropfilter?.setValue(filterdImage, forKey: kCIInputImageKey)
            let cropedImage = cropfilter?.outputImage
            cropfilter?.setValue(nil, forKey: kCIInputImageKey)
            
            return cropedImage
        }
        
        /// 0-1の範囲をガウスブラーの0-30に対応させて、make(from:)での効果を指定する
        ///
        /// - Parameter ratio: 効果の比率 0-1
        func set(ratio:Float) {
            redius = CGFloat(ratio) * 30
            filter?.setValue(redius, forKey:kCIInputRadiusKey)
        }
    }
}

// MARK: - CGRect拡張
extension CGRect {
    
    /// origin、size全ての値で小数点以下を丸める。
    /// sizeに関しては最小サイズが1より小さくならないように保証する
    mutating func rounding() {
        origin.x = round(origin.x)
        origin.y = round(origin.y)
        size.width = round(max(size.width, 1))
        size.height = round(max(size.height, 1))
    }
}
