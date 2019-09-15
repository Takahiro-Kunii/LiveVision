//
//  LiveCamera.swift
//  LiveVision
//
//  Created by kunii on 2019/08/26.
//  Copyright © 2019 Takahiro Kunii. All rights reserved.
//

import Foundation
import AVFoundation

class LiveCamera: NSObject {
    ///  利用可能か不可（権限がない・設定で失敗）かを判断する
    ///
    /// - notAuthorized: 権限をもらえなかった
    /// - notConfigured: 必要な装置を構成できなかった
    /// - available: 利用可能
    enum Condition {
        case notAuthorized
        case notConfigured
        case available
    }
    private(set) var condition = Condition.notAuthorized
    
    ///  ライブカメラ用セッション
    let session = AVCaptureSession()
    
    /// セッション用のシリアルキュー
    /// セッションの各処理は長い時間かかる場合があるので、UI用のスレッドで実行させてはいけない
    let sessionQueue = DispatchQueue(label: "session queue")
    
    /// セッション中ならtrueとする
    /// 自身のアプリ以外の要因でセッションが止められた場合、自動復帰するかどうかを判断するのにも使う
    private(set) var isRunning = false
    
    ///  現在構成されている画像取り込み用装置
    private(set) var captureInputDevice:AVCaptureDeviceInput!
    
    /// 開始前に最低1回は呼び出す(くり返し呼んでもいいが、デバイスが設定されるのは一度だけ)
    /// 画像取り込み用として装置を使う権限があるか確認
    /// 権限がありセッションに必要な装置が構成できてなければ構成する
    func prepare() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:       // 権限がある
            if condition == .notAuthorized {    //  権限なしからの変更時は装置を構成させる
                condition = .notConfigured
            }
            break
        case .notDetermined:    //  まだユーザーに確認が取れていないので、確認する
            //  requestAccessで確認画面が表示され、権限が承認されたなら
            //  completionHandlerが呼ばれる。
            //  承認された・承認されなかったを確認してからsessionQueueを動かす
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {
                granted in
                self.condition = granted ? .notConfigured : .notAuthorized
                self.sessionQueue.resume()
            })
        default:
            condition = .notAuthorized
        }
        
        /// 一度も設定されていないなら構成処理を実行
        /// 上記 .notDeterminedでのsuspend()操作によって
        /// 権限があるかないか確認されていない場合は、確認が取れてから動作するようになっている
        sessionQueue.async {
            if self.condition == .notConfigured {
                self.session.beginConfiguration()
                self.configure()
                self.session.commitConfiguration()
            }
        }
    }
    
    /// 背面カメラを画像取り込み用装置に設定する。可能ならオートフォーカス、オート露出にする
    private func configure() {
        session.sessionPreset = .photo  //  写真モード指定
        guard let input = configuredInput() else {
            NSLog("Default video device is unavailable.")
            return
        }
        if !session.canAddInput(input) {
            NSLog("Couldn't add video device input to the session.")
            return
        }
        session.addInput(input)
        captureInputDevice = input
        condition = .available
    }
    
    ///  構成済みの画像取り込み用装置を返す
    ///
    /// - Returns: 用意した装置。用意できなかったらnil
    private func configuredInput() -> AVCaptureDeviceInput? {
        guard let captureDevice = AVCaptureDevice.defaultCaptureDevice else {
            return nil
        }
        captureDevice.configure()
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            return input
        } catch {
            NSLog("Couldn't create video device input: \(error)")
        }
        return nil
    }
    
    /// セッション開始
    func start() {
        if isRunning { return }   //  既に動作している
        isRunning = true
        sessionQueue.async {
            //  ここに来た時点で.availableでないなら動作できない
            if self.condition != .available {
                self.isRunning = false
                return
            }
            self.session.startRunning()
            self.isRunning = self.session.isRunning     //  最終的に動作してるかどうかはここで確定
        }
    }
    
    //  セッション停止
    func stop() {
        if !self.isRunning { return }   //  既に停止している
        isRunning = false
        self.sessionQueue.async {
            self.session.stopRunning()
            self.isRunning = self.session.isRunning     //  最終的に停止してるかどうかはここで確定
        }
    }
}

extension AVCaptureDevice {
    ///  未指定時の画像取り込み用装置を返す
    class var defaultCaptureDevice: AVCaptureDevice? {
        //  デフォルトのカメラでいいなら以下のAPIを使う
        //  AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        return session.devices.first
    }
    
    /// 可能ならオートフォーカス・オート露出を設定
    func configure() {
        /// フォーカスや露出の画面上の参照位置　（0-1.0）で正規化
        let referencePoint = CGPoint(x:0.5, y:0.5)
        do {
            try lockForConfiguration()
            
            /// オートフォーカス可能なら設定
            let focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
            if isFocusPointOfInterestSupported && isFocusModeSupported(focusMode) {
                focusPointOfInterest = referencePoint
                self.focusMode = focusMode
            }
            
            /// オート露出可能なら設定
            let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            if isExposurePointOfInterestSupported && isExposureModeSupported(exposureMode) {
                self.exposureMode = exposureMode
                exposurePointOfInterest = referencePoint
            }
            
            unlockForConfiguration()
        } catch {
            NSLog("Could not lock device for configuration: \(error)")
        }
    }
}

