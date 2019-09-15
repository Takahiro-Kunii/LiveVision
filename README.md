# 目的
AVCaptureSessionを使ったカメラからのライブ画像の取り込みとその利用を理解する。

#  各ブランチについて
|ブランチ名|説明|
|:--|:--|
|master|AVCaptureMetadataOutputを使ったバーコード読み取り|
|use-vision|VisionフレームワークのVNBarcodeObservationを使ったバーコード読み取り|
|filtering|use-visionの応用例。バーコード読み取りの代わりにCIFilterによる画像加工を行なっている|
|barcode-vision-blur|use-visionとfilteringの合成|

## master
AVCaptureSessionからの出力にAVCaptureMetadataOutputを指定し、バーコード検出を行なっている。
同時にカメラからのライブ画像を表示するためにAVCaptureVideoPreviewLayerを利用。
検出したバーコード値はペーストボードにコピーしているので、他のアプリでペースト可能。QRコードも読み取れる。
理解を助けるために、極力単純にしたstep-1、step-2のタグを用意し、それぞれで稼働するようにしている。
step-1：AVCaptureSessionでカメラを動かしAVCaptureVideoPreviewLayerライブ画像を表示する
step-2：AVCaptureMetadataOutputを加えバーコード検出を行なう

## use-vision
VNBarcodeObservationでは静止画像を使う、そのためAVCaptureVideoDataOutputを使ってAVCaptureSessionからのらカメラライブ画像のフレームを取り出し、利用している。

## filtering
use-visionのAVCaptureVideoDataOutput応用例としてCoreImageフレームワークのCIFilterを使ったカメラライブ画像のリアルタイム加工。
画面をドラッグする事で、中心部からの距離に応じてブラー量がリアルタイムに変わるようにしている。

## barcode-vision-blur
filteringで行なった画像加工とuse-visionでのバーコード検出を行なっている。画面ドラッグは廃止。
