//
//  Toaster.swift
//  LiveVision
//
//  Created by kunii on 2019/08/30.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import UIKit

/// トースターのように指定画面下から、指定した文字列をポップさせる
struct Toaster {
    /// 表示中ならtrue
    static var isPopping: Bool {
        return baseView.superview != nil
    }
    
    /// トースターからポップするパンの役割　角丸矩形で影つきにする
    static private let baseView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 150))
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = .zero
        view.addSubview(textLabel)
        return view
    }()
    
    /// 文字列を表示するためのラベル
    /// 設定された文字列を32〜16ポイント文字の範囲でラベル内に収まるように調整し表示する
    /// 収めきれない場合は末尾を…表示
    static private let fontSize:CGFloat = 32
    static private let textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    /// トースターのように指定画面下から、指定した文字列をポップさせる
    ///
    /// - Parameters:
    ///   - view: ポップさせる先の画面
    ///   - text: ポップさせる文字列
    static func pop(from view:UIView, text:String) {
        let upDuration:TimeInterval = 0.3
        let showDuration:TimeInterval = 2.0
        let downDuration:TimeInterval = 0.3
        
        //  先行するアニメーションはキャンセル
        baseView.layer.removeAllAnimations()
        
        //  表示先に合わせたトースト画面やラベルの位置・サイズ調整
        //  横幅は表示先より両端16ポイント小さくする
        baseView.frame.size.width = view.bounds.size.width - (16 * 2)
        baseView.frame.origin.y = view.frame.maxY
        baseView.center.x = view.center.x
        textLabel.frame = baseView.bounds.insetBy(
            dx: baseView.layer.cornerRadius, dy: baseView.layer.cornerRadius)
        textLabel.frame.size.height = fontSize * 1.5
        
        //  文字列を設定しトースト画面を表示先に取り付ける
        textLabel.text = text
        view.addSubview(baseView)
        
        //  すぐに、上るアニメーションを実行
        UIView.animate(withDuration: upDuration,
                       delay: 0.0,
                       options: .allowUserInteraction,
                       animations: {
                        self.baseView.frame.origin.y -= self.baseView.frame.size.height - 8
        }, completion: { (finished ) in
            if !finished { return }
            
            //  しばらく待って下がるアニメーションを実行
            UIView.animate(withDuration: downDuration,
                           delay: showDuration,
                           options:.allowUserInteraction,
                           animations: {
                            self.baseView.frame.origin.y += self.baseView.frame.size.height
            }, completion: { (finished ) in
                if !finished { return }
                
                //  トースト画面を表示先から取り外す
                self.baseView.removeFromSuperview()
            })
        })
    }
}
