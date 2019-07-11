//
//  ViewController.m
//  AVCapture
//
//  Created by G-Jayson on 2019/7/1.
//  Copyright © 2019 G-Jayson. All rights reserved.
//

#import "ViewController.h"
#import "VideoVapturer.h"



@interface ViewController () <VideoCapturerDelegate>

/**  播放视图  **/
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *recordLayer;

/**  视频采集  **/
@property (nonatomic, strong) VideoVapturer *videoCapture;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // --- 初始化视频采集参数  ---
    VideoCapturerParam *param = [[VideoCapturerParam alloc] init];
    
    // ---  初始化视频采集器  ---
    self.videoCapture = [[VideoVapturer alloc] initWithCaptureParam:param error:nil];
    self.videoCapture.delagate = self;
    
    // ---  开始采集  ---
    [self.videoCapture startCpture];
    

    // ---  初始化预览View  ---
    self.recordLayer = self.videoCapture.videoPreviewLayer;
    self.recordLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    [self.view.layer addSublayer:self.recordLayer];
    
    
    UIButton *reverseCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    reverseCameraBtn.frame = CGRectMake(SCREEN_WIDTH - 60, SCREEN_HEIGHT - 105, 40, 40);
    [reverseCameraBtn setImage:[UIImage imageNamed:@"reverse"] forState:UIControlStateNormal];
    [reverseCameraBtn addTarget:self action:@selector(reverseCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reverseCameraBtn];
    
    
    for (int i = 0; i <= 3; i++) {
        NSString *sessionPreset = @"";
        if (i == 0) {
            sessionPreset = @"352";
        } else if (i == 1) {
            sessionPreset = @"1280";
        } else if (i == 2) {
            sessionPreset = @"1920";
        } else if (i == 3) {
            sessionPreset = @"3840";
        }
        
        UIButton *sessionPresetBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        sessionPresetBtn.frame = CGRectMake(20 + i * 70, SCREEN_HEIGHT - 100, 55, 30);
        sessionPresetBtn.layer.borderWidth = 1;
        sessionPresetBtn.layer.borderColor = UIColor.whiteColor.CGColor;
        sessionPresetBtn.layer.cornerRadius = 3;
        [sessionPresetBtn addTarget:self action:@selector(changeSessionPreset:) forControlEvents:UIControlEventTouchUpInside];
        [sessionPresetBtn setTitle:sessionPreset  forState:UIControlStateNormal];
        sessionPresetBtn.tag = sessionPreset.integerValue;
        [self.view addSubview:sessionPresetBtn];
    }
    
}


/**
 * 调整分辨率
 */
- (void)changeSessionPreset:(UIButton *)button {
    switch (button.tag) {
        case 3840:
            [self.videoCapture changeSessionPreset:AVCaptureSessionPreset3840x2160];
            break;
            
        case 1920:
            [self.videoCapture changeSessionPreset:AVCaptureSessionPreset1920x1080];
            break;
            
        case 1280:
            [self.videoCapture changeSessionPreset:AVCaptureSessionPreset1280x720];
            break;
            
        case 352:
            [self.videoCapture changeSessionPreset:AVCaptureSessionPreset352x288];
            break;
            
        default:
            break;
    }
}



/**
 * 切换摄像头
 */
- (void)reverseCamera:(UIButton *)button {
    NSError *error = [self.videoCapture reverseCamera];
    if (!error) {
        NSLog(@"切换摄像头成功");
    }
}


#pragma mark ————— VideoCapturerDelegate —————  视频采集回调
- (void)videoCaptureOutputDataCallback:(CMSampleBufferRef)sampleBuffer {
    NSLog(@"%@ sampleBuffer : %@ ", kLOGt(@"视频采集回调"), sampleBuffer);
}



@end
