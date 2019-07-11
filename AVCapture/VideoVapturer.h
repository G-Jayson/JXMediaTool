//
//  VideoVapturer.h
//  AVCapture
//
//  Created by G-Jayson on 2019/7/2.
//  Copyright © 2019 G-Jayson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol VideoCapturerDelegate <NSObject>

/**
 * 摄像头采集数据输出回调
 @param sampleBuffer 采集的数据
 */
- (void)videoCaptureOutputDataCallback:(CMSampleBufferRef)sampleBuffer;

@end



@interface VideoCapturerParam : NSObject

/**  摄像头位置，默认为前置摄像头 AVCaptureDevicePositionFront  **/
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
/**  视频分辨率 默认 AVCaptureSessionPreset1280x720  **/
@property (nonatomic, assign) AVCaptureSessionPreset sessionPreset;
/**  帧 单位为 帧/秒，默认为15帧/秒  **/
@property (nonatomic, assign) NSInteger frameRate;
/**  摄像头方向 默认为当前手机屏幕方向  **/
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;

@end



@interface VideoVapturer : NSObject


@property (nonatomic, weak) id<VideoCapturerDelegate> delagate;
/**  预览图层,把这个图层加在view上并且为这个图层设置frame就能播放  **/
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
/**  视频采集参数  **/
@property (nonatomic, strong) VideoCapturerParam *capturerParam;

/**
 * 初始化视频采集器
 @param param 视频采集参数
 @param error 错误回调
 */
- (instancetype)initWithCaptureParam:(VideoCapturerParam *)param
                               error:(NSError **)error;

/**
 * 开始视频采集
 */
- (NSError *)startCpture;



/**
 * 停止视频采集
 */
- (NSError *)stopCapture;



/**
 * 动态调整帧率
 @param frameRate 帧率
 */
- (NSError *)adjustFrameRate:(NSInteger)frameRate;



/**
 * 翻转摄像头
 */
- (NSError *)reverseCamera;



/**
 * 修改视频分辨率
 @param sessionPreset 分辨率
 */
- (void)changeSessionPreset:(AVCaptureSessionPreset)sessionPreset;


@end

NS_ASSUME_NONNULL_END
