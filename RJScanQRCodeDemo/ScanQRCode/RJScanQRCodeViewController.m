//
//  RJScanQRCodeViewController.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/20.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "RJScanQRCodeViewController.h"
#import "RJQRCodeManager.h"
#import "RJScanQRCodePreviewView.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "RJScanQRCodePreviewViewConfiguration.h"
#import "RJScanQRCodeAuthorizationManager.h"

@interface RJScanQRCodeViewController () <RJScanQRCodePreviewViewDelegate>

@property (nonatomic, strong) RJQRCodeManager *qrCodeManager;
/********* 预览view *********/
@property (nonatomic, weak) RJScanQRCodePreviewView *previewView;

@end

@implementation RJScanQRCodeViewController

#pragma mark - Life Cycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupInit];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startScanning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopScanning];
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

#pragma mark - 设置初始化

- (void)setupInit
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    //检查相机权限
    [self checkCameraPermission];
    
    [self setupNavigationBar];
    //处理导航条不透明时，造成扫描框偏下的问题
    if (CGRectEqualToRect(self.configuration.rectFrame, CGRectZero))
    {
        CGRect frame = self.view.frame;
        CGFloat rectSide = fminf(frame.size.width, frame.size.height) * 2 / 3;
        CGFloat opaqueHeight = 0.0;
        if (self.navigationController && !self.navigationController.navigationBar.translucent) {
            opaqueHeight = CGRectGetHeight(self.navigationController.navigationBar.frame) + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        }
        self.configuration.rectFrame = CGRectMake((frame.size.width - rectSide) * 0.5, (frame.size.height - rectSide) * 0.5 - opaqueHeight, rectSide, rectSide);
    }
    
    RJScanQRCodePreviewView *previewView = [[RJScanQRCodePreviewView alloc] initWithFrame:self.view.bounds delegate:self configuration:self.configuration];
    [self.view addSubview:previewView];
    self.previewView = previewView;
    
    __weak typeof(self) weakSelf = self;
    RJQRCodeManager *manager = [[RJQRCodeManager alloc] initWithPreviewView:previewView completed:^(RJQRCodeManager * _Nonnull manager) {
//        [manager setInterestRect:previewView.rectFrame];
        [weakSelf startScanning];
    }];
    
    self.qrCodeManager = manager;

}

#pragma mark - NavigationBar

- (void)setupNavigationBar {
    UIBarButtonItem *photoItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStyleDone target:self action:@selector(pickerImage)];
    self.navigationItem.rightBarButtonItems = @[photoItem];
}

#pragma mark - RJScanQRCodePreviewViewDelegate Methods

- (void)scanQRCodePreviewView:(RJScanQRCodePreviewView *)previewView didClickedTorchSwitch:(UIButton *)torchSwitchButton
{
    torchSwitchButton.selected = !torchSwitchButton.selected;
    [self.qrCodeManager turnOnTorch:torchSwitchButton.selected];
}

#pragma mark - Override Methods

#pragma mark - Public Methods

#pragma mark - Private Methods

//检查相机权限
- (void)checkCameraPermission
{
    [RJScanQRCodeAuthorizationManager cameraAuthorizeWithCompletion:^(BOOL granted, BOOL firstTime) {
        if (granted)
        {
            
        }
        else if (!firstTime)
        {
            NSLog(@"没有相机权限");
            [RJScanQRCodeAuthorizationManager guideUserOpenAuthWithTitle:@"提示" message:@"没有相机权限，是否前往设置"];
        }
    }];
}

- (void)startScanning
{
    __weak typeof(self) weakSelf = self;
    [self.qrCodeManager startScanningWithResultBlock:^(NSString * _Nonnull resultStr) {
        NSLog(@"扫描结果：%@", resultStr);
        [weakSelf stopScanning];
        if ([weakSelf.delegate respondsToSelector:@selector(scanningResult:codeString:)])
        {
            [weakSelf.delegate scanningResult:weakSelf codeString:resultStr];
        }
    }];
}

- (void)stopScanning
{
    [self.qrCodeManager stopScanning];
}

//从相册选择二维码图片
- (void)pickerImage
{
    //检查相册权限
    [RJScanQRCodeAuthorizationManager photoAuthorizeWithCompletion:^(BOOL granted, BOOL firstTime) {
        if (granted)
        {
            __weak typeof(self) weakSelf = self;
            [self.qrCodeManager presentPhotoLibraryWithRootController:self resultBlock:^(NSString * _Nullable resultStr) {
                NSLog(@"从相册选择图片识别二维码：%@", resultStr);
                [weakSelf stopScanning];
                if ([weakSelf.delegate respondsToSelector:@selector(scanningResult:codeString:)])
                {
                    [weakSelf.delegate scanningResult:weakSelf codeString:resultStr];
                }
            }];
        }
        else if(!firstTime)
        {
            NSLog(@"没有相册权限");
            [RJScanQRCodeAuthorizationManager guideUserOpenAuthWithTitle:@"提示" message:@"没有相册权限，是否前往设置"];
        }
    }];
}

#pragma mark - Properties Methods
- (RJScanQRCodePreviewViewConfiguration *)configuration
{
    if (_configuration == nil)
    {
        _configuration = [RJScanQRCodePreviewViewConfiguration defaultConfiguration];
    }
    return _configuration;
}

@end
