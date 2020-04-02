//
//  ViewController.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/20.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "ViewController.h"
#import "RJScanQRCode.h"
#import "RJGeneratorQRCodeViewController.h"

@interface ViewController () <RJScanQRCodeViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupInit];
//    self.navigationController.navigationBar.translucent = NO;
}

#pragma mark - 设置初始化
- (void)setupInit
{
    UIButton *scanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:scanBtn];
    scanBtn.bounds = CGRectMake(0, 0, 150, 50);
    scanBtn.center = CGPointMake(self.view.center.x, self.view.center.y - 40);
    [scanBtn setTitle:@"扫描二维码" forState:UIControlStateNormal];
    [scanBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [scanBtn setBackgroundColor:[UIColor orangeColor]];
    [scanBtn addTarget:self action:@selector(jumpBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *generateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:generateBtn];
    generateBtn.bounds = CGRectMake(0, 0, 150, 50);
    generateBtn.center = CGPointMake(self.view.center.x, self.view.center.y + 40);
    [generateBtn setTitle:@"生成二维码" forState:UIControlStateNormal];
    [generateBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [generateBtn setBackgroundColor:[UIColor orangeColor]];
    [generateBtn addTarget:self action:@selector(generatorBtnClick:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Target Methods

- (void)jumpBtnClick:(UIButton *)scanBtn
{
    RJScanQRCodePreviewViewConfiguration *configuration = [RJScanQRCodePreviewViewConfiguration defaultConfiguration];
    configuration.rectBorderColor = [UIColor whiteColor];
    configuration.rectCornerColor = [UIColor redColor];
    configuration.scanningLineColor = [UIColor redColor];
    configuration.tipTitle = @"将二维码/条形码放入框内即可自动扫描";
    RJScanQRCodeViewController *scanQRCodeVC = [[RJScanQRCodeViewController alloc] init];
    scanQRCodeVC.title = @"二维码/条形码";
    scanQRCodeVC.configuration = configuration;
    scanQRCodeVC.delegate = self;
    [self.navigationController pushViewController:scanQRCodeVC animated:YES];
}

- (void)generatorBtnClick:(UIButton *)generateBtn
{
    RJGeneratorQRCodeViewController *generatorQRCodeVC = [[RJGeneratorQRCodeViewController alloc] init];
    [self.navigationController pushViewController:generatorQRCodeVC animated:YES];
}

#pragma mark - RJScanQRCodeViewControllerDelegate Methods

- (void)scanningResult:(RJScanQRCodeViewController *)scanQRCodeViewController codeString:(NSString *)codeString
{
    NSLog(@"root获取到的二维码信息：%@", codeString);
    [scanQRCodeViewController.navigationController popViewControllerAnimated:YES];
}

@end
