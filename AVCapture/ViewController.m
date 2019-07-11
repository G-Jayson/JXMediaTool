//
//  ViewController.m
//  AVCapture
//
//  Created by G-Jayson on 2019/7/1.
//  Copyright © 2019 G-Jayson. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CaptureViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    UIButton *beginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [beginButton setTitle:@"开始采集" forState:UIControlStateNormal];
    beginButton.frame = CGRectMake(0, 0, 100, 40);
    beginButton.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2, CGRectGetHeight(self.view.bounds) / 2);
    [beginButton addTarget:self action:@selector(startCapture:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:beginButton];
}


- (void)startCapture:(UIButton *)button {
    // ---  查看摄像头权限  ---
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        //已经授权
        CaptureViewController *captureVC = [[CaptureViewController alloc] init];
        [self presentViewController:captureVC animated:YES completion:nil];
    } else {
        NSLog(@"未获取摄像头权限");
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
        }];
    }
}



@end

