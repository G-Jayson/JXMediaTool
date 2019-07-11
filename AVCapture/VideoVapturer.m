//
//  VideoVapturer.m
//  AVCapture
//
//  Created by G-Jayson on 2019/7/2.
//  Copyright © 2019 G-Jayson. All rights reserved.
//

#import "VideoVapturer.h"
#import <UIKit/UIKit.h>



@implementation VideoCapturerParam

- (instancetype)init {
    self = [super init];
    if (self) {
        _devicePosition = AVCaptureDevicePositionFront;
        _sessionPreset = AVCaptureSessionPreset1280x720;
        _frameRate = 15;
        _videoOrientation = AVCaptureVideoOrientationPortrait;
        
        switch ([UIDevice currentDevice].orientation) {
            case UIDeviceOrientationPortrait:
            case UIDeviceOrientationPortraitUpsideDown:
                _videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
                
            case UIDeviceOrientationLandscapeRight:
                _videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
                
            case UIDeviceOrientationLandscapeLeft:
                _videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
                
            default:
                break;
        }
    }
    
    return self;
}

@end



@interface VideoVapturer () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate>

/**  采集会话  **/
@property (nonatomic, strong) AVCaptureSession *captureSession;
/**  采集输入设备 也就是摄像头  **/
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
/**  采集输出  **/
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
/**  预览图层，把这个图层放在view上就能播放  **/
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
/**  输出连接  **/
@property (nonatomic, strong) AVCaptureConnection *captureConnection;
/**  是否已经c在采集  **/
@property (nonatomic, assign) BOOL isCapturing;

@end


@implementation VideoVapturer


- (void)dealloc {
    NSLog(@"___%s___", __func__);
}


- (instancetype)initWithCaptureParam:(VideoCapturerParam *)param
                               error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (self = [super init]) {
        NSError *errorMeaasge = nil;
        self.capturerParam = param;
        
        
        /**************************  设置输入设备  *************************/
        // ---  获取所有摄像头  ---
        NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        // ---  获取当前方向摄像头  ---
        NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", _capturerParam.devicePosition]];
        
        if (captureDeviceArray.count == 0) {
            errorMeaasge = [self p_errorWithDomain:@"VideoCapture:: Get Camera Faild!"];
            return nil;
        }
        
        // ---  转化为输入设备  ---
        AVCaptureDevice *camera = captureDeviceArray.firstObject;
        self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera
                                                                        error:&errorMeaasge];
        
        if (errorMeaasge) {
            errorMeaasge = [self p_errorWithDomain:@"VideoCapture:: AVCaptureDeviceInput init error!"];
            return nil;
        }
        
        
        /**************************  设置输出设备  *************************/
        // ---  设置视频输出  ---
        self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        NSDictionary *videoSetting = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey, nil];  // pixel 像素  // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange 表示输出的视频格式为NV12
        [self.captureVideoDataOutput setVideoSettings:videoSetting];
        
        // ---  设置输出串行队列和数据回调  ---
        dispatch_queue_t outputQueue = dispatch_queue_create("VideoCaptureOutputQueue", DISPATCH_QUEUE_SERIAL);
        // ---  设置代理  ---
        [self.captureVideoDataOutput setSampleBufferDelegate:self queue:outputQueue];
        // ---  丢弃延迟的帧  ---
        self.captureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        
        
        /**************************  初始化会话  *************************/
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.usesApplicationAudioSession = NO;
        
        // ---  添加输入设备到会话  ---
        if ([self.captureSession canAddInput:self.captureDeviceInput]) {
            [self.captureSession addInput:self.captureDeviceInput];
        }
        else {
            [self p_errorWithDomain:@"VideoCapture:: Add captureVideoDataInput Faild!"];
            NSLog(@"VideoCapture:: Add captureVideoDataInput Faild!");
            return nil;
        }
        
        // ---  添加输出设备到会话  ---
        if ([self.captureSession canAddOutput:self.captureVideoDataOutput]) {
            [self.captureSession addOutput:self.captureVideoDataOutput];
        }
        else {
            [self p_errorWithDomain:@"VideoCapture:: Add captureVideoDataOutput Faild!"];
            return nil;
        }
        
        
        
        // ---  设置分辨率  ---
        if ([self.captureSession canSetSessionPreset:self.capturerParam.sessionPreset]) {
            self.captureSession.sessionPreset = self.capturerParam.sessionPreset;
        }
        
        
        /**************************  初始化连接  *************************/
        self.captureConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // ---  设置摄像头镜像，不设置的话前置摄像头采集出来的图像是反转的  ---
        if (self.capturerParam.devicePosition == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring) { // supportsVideoMirroring 视频是否支持镜像
            self.captureConnection.videoMirrored = YES;
        }
        
        self.captureConnection.videoOrientation = self.capturerParam.videoOrientation;
        
        self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        self.videoPreviewLayer.connection.videoOrientation = self.capturerParam.videoOrientation;
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        if (error) {
            *error = errorMeaasge;
        }
        
        
        // ---  设置帧率  ---
        [self adjustFrameRate:self.capturerParam.frameRate];
    }
    
    return self;
}



/**
 * 开始采集
 */
- (NSError *)startCpture {
    if (self.isCapturing) {
        return [self p_errorWithDomain:@"VideoCapture:: startCapture faild: is capturing"];
    }
    
    // ---  摄像头权限判断  ---
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (videoAuthStatus != AVAuthorizationStatusAuthorized) {
        return [self p_errorWithDomain:@"VideoCapture:: Camera Authorizate faild!"];
    }
    
    [self.captureSession startRunning];
    self.isCapturing = YES;
    
    kLOGt(@"开始采集视频");
    
    return nil;
}



/**
 * 停止采集
 */
- (NSError *)stopCapture {
    if (!self.isCapturing) {
        return [self p_errorWithDomain:@"VideoCapture:: stop capture faild! is not capturing!"];
    }
    
    [self.captureSession stopRunning];
    self.isCapturing = NO;
    
    kLOGt(@"停止采集视频");
    
    return nil;
}



/**
 * 设置帧率
 @prama frameRate 帧率
 */
- (NSError *)adjustFrameRate:(NSInteger)frameRate {
    NSError *error = nil;
    AVFrameRateRange *frameRateRange = [self.captureDeviceInput.device.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0];
    
    NSLog(@"帧率设置范围: min: %f ,  max: %f", frameRateRange.minFrameRate, frameRateRange.maxFrameRate);
    
    if (frameRate > frameRateRange.maxFrameRate || frameRate < frameRateRange.minFrameRate) {
        return [self p_errorWithDomain:@"VideoCapture:: Set FrameRate faild! out of rang"];
    }
    
    [self.captureDeviceInput.device lockForConfiguration:&error];
    self.captureDeviceInput.device.activeVideoMinFrameDuration = CMTimeMake(1, (int)self.capturerParam.frameRate);
    self.captureDeviceInput.device.activeVideoMaxFrameDuration = CMTimeMake(1, (int)self.capturerParam.frameRate);
    [self.captureDeviceInput.device unlockForConfiguration];
    
    return error;
}



/**
 * 翻转摄像头
 */
- (NSError *)reverseCamera {
    // ---  获取所有摄像头  ---
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    // ---  获取当前摄像头方向  ---
    AVCaptureDevicePosition currentPosition = self.captureDeviceInput.device.position;
    AVCaptureDevicePosition toPosition = AVCaptureDevicePositionUnspecified;
    
    if (currentPosition == AVCaptureDevicePositionBack || currentPosition == AVCaptureDevicePositionUnspecified) {
        toPosition = AVCaptureDevicePositionFront;
    } else {
        toPosition = AVCaptureDevicePositionBack;
    }
    
    NSArray *captureDeviceArr = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", toPosition]];
    
    if (captureDeviceArr.count == 0) {
        return [self p_errorWithDomain:@"VideoCapture:: reverseCamera faild! get new camera faild!"];
    }
    
    NSError *error = nil;
    
    // ---  添加翻转动画  ---
    CATransition *animation = [CATransition animation];
    animation.duration = 1.0;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = @"oglFlip";
    
    AVCaptureDevice *camera = captureDeviceArr.firstObject;
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:camera
                                                                           error:&error];
    
    animation.subtype = kCATransitionFromRight;
    [self.videoPreviewLayer addAnimation:animation forKey:nil];
    
    
    // ---  修改输入设备  ---
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.captureDeviceInput];
    if ([self.captureSession canAddInput:newInput]) {
        [self.captureSession addInput:newInput];
        self.captureDeviceInput = newInput;
    }
    
    [self.captureSession commitConfiguration];
    
    
    // ---  重新获取连接并设置方向  ---
    self.captureConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    // ---  设置摄像头镜像，不设置的话前置摄像头采集出来的图像是反转的  ---
    if (toPosition == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring) {
        self.captureConnection.videoMirrored = YES;
    }
    
    self.captureConnection.videoOrientation = self.capturerParam.videoOrientation;
    
    return nil;
}



/**
 * 修改分辨率
 */
- (void)changeSessionPreset:(AVCaptureSessionPreset)sessionPreset {
    if (self.capturerParam.sessionPreset == sessionPreset) {
        return;
    }
    
    
    self.capturerParam.sessionPreset = sessionPreset;
    if ([self.captureSession canSetSessionPreset:self.capturerParam.sessionPreset]) {
        [self.captureSession setSessionPreset:self.capturerParam.sessionPreset];
        NSLog(@"%@", kLOGt(@"分辨率切换成功"));
    }
}



#pragma mark ————— AVCaptureVideoDataOutputSampleBufferDelegate —————

/**
 * 摄像头采集数据回调
 @prama output       输出设备
 @prama sampleBuffer 帧缓存数据，描述当前帧信息
 @prama connection   连接
 */
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if ([self.delagate respondsToSelector:@selector(videoCaptureOutputDataCallback:)]) {
        [self.delagate videoCaptureOutputDataCallback:sampleBuffer];
    }
}



- (NSError *)p_errorWithDomain:(NSString *)domain {
    NSLog(@"%@", domain);
    return [NSError errorWithDomain:domain code:1 userInfo:nil];
}



@end
