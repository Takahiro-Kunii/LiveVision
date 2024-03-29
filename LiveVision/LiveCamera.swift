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
    weak var delegate:LiveCameraDelegate!
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
    @objc dynamic private(set) var captureInputDevice:AVCaptureDeviceInput!
    private var keyValueObservations = [NSKeyValueObservation]()
    
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
            self.delegate?.liveCameraIsnotAvailable?(self)
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
                self.delegate?.liveCameraFailed?(self)
                return
            }
            self.addObservers()
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
            self.removeObservers()
        }
    }
    
    /// 出力装置を追加
    ///
    /// - Parameters:
    ///   - output: 追加する出力装置
    ///   - completeHandler: 追加できたかどうかをレポートする
    ///     completeHandler(Bool)
    ///     引数のBool値がtrueなら追加されたことを意味し、falseなら追加されなかったことを意味する
    func add(output:AVCaptureOutput, completeHandler:((Bool)->Void)? = nil) {
        self.sessionQueue.async {
            if self.session.isRunning {
                completeHandler?(false)
                return
            }
            self.session.beginConfiguration()
            let canAdd = self.session.canAddOutput(output)
            if canAdd {
                self.session.addOutput(output)
            }
            completeHandler?(canAdd)
            self.session.commitConfiguration()
        }
    }
}

// MARK: - 見張り機能
extension LiveCamera {
    
    /// 装置の不具合や停止・再開通知のハンドラを用意し最低限の対応をする
    /// KVOで以下の変化を見張る
    ///     sessionのisRunning
    ///     自身のcaptureInputDevice.device.systemPressureState
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            
            //  動作状態をデリゲートに連絡
            self.delegate?.liveCameraDidChange?(self, sessionRunning:isSessionRunning)
        }
        keyValueObservations.append(keyValueObservation)
        
        let systemPressureStateObservation = self.observe(\.captureInputDevice.device.systemPressureState, options: .new) { _, change in
            guard let systemPressureState = change.newValue else { return }
            self.setRecommendedFrameRateRangeForPressureState(systemPressureState: systemPressureState)
        }
        keyValueObservations.append(systemPressureStateObservation)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError, object: session)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: .AVCaptureSessionInterruptionEnded, object: session)
    }
    
    /// 通知ハンドラ、KVO見張りの削除
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    /// なんらかの不具合が生じた。不具合が復帰可能な場合再始動する
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        NSLog("Capture session runtime error: \(error)")
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isRunning {
                    //  動作中だったなら再開させる
                    self.session.startRunning()
                    self.isRunning = self.session.isRunning
                }
            }
        } else {
            //  未対応
        }
    }
    
    /// ここでやっているのは一例　ビデオフレームレートを下げることで、取り込む処理のシステムへの圧迫を緩めている
    private func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            NSLog("WARNING: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
            reduceCaptureDeviceFrameRate()
        } else if pressureLevel == .shutdown {
            NSLog("Session stopped running due to shutdown system pressure level.")
        }
    }
    
    /// フレームレートを毎秒15-20に変更する
    private func reduceCaptureDeviceFrameRate() {
        guard let captureDevice = self.captureInputDevice?.device else { return }
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
            captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
            captureDevice.unlockForConfiguration()
        } catch {
            NSLog("Could not lock device for configuration: \(error)")
        }
    }
    
    /// ユーザーがコントロールセンターで音楽を再生してしまった等で呼び出される。状況によっては再始動できる
    @objc func sessionWasInterrupted(notification: NSNotification) {
        guard let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) else {
                return
        }
        NSLog("Capture session was interrupted with reason \(reason)")
        
        if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
            //  取り返すことも可能
            NSLog("audio/video device in use by another client.")
        } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
            NSLog("video device not available with multiple foreground apps.")
        } else if reason == .videoDeviceNotAvailableDueToSystemPressure {
            NSLog("Session stopped running due to shutdown system pressure level.")
        }
    }
    
    /// 割り込みが終わった
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        NSLog("Capture session interruption ended")
    }
}

// MARK: - LiveCamera用デリゲート定義
@objc protocol LiveCameraDelegate : NSObjectProtocol {
    
    /// セッション状態の変化を連絡する
    ///
    /// - Parameters:
    ///   - camera: 呼び出し元
    ///   - sessionRunning: セッションの状態
    @objc optional func liveCameraDidChange(_ camera:LiveCamera, sessionRunning:Bool)
    
    /// 権利確認で利用不可と返された時呼ばれる
    ///
    /// - Parameter camera: 呼び出し元
    @objc optional func liveCameraIsnotAvailable(_ camera:LiveCamera)
    
    /// 失敗した時呼ばれる
    ///
    /// - Parameter camera: 呼び出し元
    @objc optional func liveCameraFailed(_ camera:LiveCamera)
}


// MARK: - AVCaptureDeviceに独自のデフォルトデバイス選択機能と、各種設定機能を追加
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

