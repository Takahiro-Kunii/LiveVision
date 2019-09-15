//
//  CirclePopLabel.swift
//  LiveVision
//
//  Created by kunii on 2019/09/12.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import UIKit

/// トースターのように指定画面背後から、指定した文字列を円形のラベルでポップさせる
class CirclePopLabel: UIView {
    /// 表示中ならtrue
    var isPopping: Bool {
        return superview != nil
    }
    
    /// 文字列を表示するためのラベル
    /// 最大3行で表示する
    /// おさめきれない場合、文字を小さくする
    private var label: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 3
        l.adjustsFontSizeToFitWidth = true
        return l
    }()
    
    /// トースターのように指定画面背後から、指定した文字列を円形のラベルでポップさせる
    ///
    /// - Parameters:
    ///   - from: ポップさせる画面を潜ませる画面
    ///   - text: ポップさせる文字列
    func pop(from aboveView:UIView, text:String) {
        let upDuration:TimeInterval = 0.3
        let showDuration:TimeInterval = 2.0
        let downDuration:TimeInterval = 0.3
        
        //  貼り付け先を得る
        guard let superView = aboveView.superview else { return }
        
        //  先行するアニメーションはキャンセル
        layer.removeAllAnimations()
        
        //  表示先に合わせたトースト画面やラベルの位置・サイズ調整
        frame = aboveView.frame
        backgroundColor = .white
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
        layer.cornerRadius = bounds.size.width / 2
        
        //  ポップする方向を決める　縦横、長い方にポップ
        var direction = CGSize.zero
        if superView.bounds.width > superView.bounds.height {
            direction.width = -(bounds.size.width - 20)
        } else {
            direction.height = -(bounds.size.height - 20)
        }
        
        //  ラベルは親より両端10ポイント小さくする
        label.frame = bounds.insetBy(dx: 10, dy: 10)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
        
        //  文字列を設定しトースト画面を表示先に取り付ける
        label.text = text
        superView.insertSubview(self, belowSubview: aboveView)
        
        //  すぐに、上るアニメーションを実行
        UIView.animate(withDuration: upDuration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: -1, options: .allowUserInteraction, animations: {
            self.center = CGPoint(x: self.center.x + direction.width, y: self.center.y + direction.height)
        }) { finished in
            //  しばらく待って下がるアニメーションを実行
            UIView.animate(withDuration: downDuration, delay: showDuration, options: .allowUserInteraction, animations: {
                self.center = CGPoint(x: self.center.x - direction.width, y: self.center.y - direction.height)
            }) { finished in
                self.removeFromSuperview()
            }
        }
    }
    
    func hide() {
        //  アニメーションはキャンセル
        layer.removeAllAnimations()
        removeFromSuperview()
    }
}

