//
//  RJScanQRCodePreviewView.h
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/21.
//  Copyright © 2019 RJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RJScanQRCodePreviewViewProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@class RJScanQRCodePreviewView, RJScanQRCodePreviewViewConfiguration;

@protocol RJScanQRCodePreviewViewDelegate <NSObject>

@optional


/**
 点击手电筒

 @param previewView 预览view
 @param torchSwitchButton 手电筒切换按钮
 */
- (void)scanQRCodePreviewView:(RJScanQRCodePreviewView *)previewView didClickedTorchSwitch:(UIButton *)torchSwitchButton;

@required

@end

@interface RJScanQRCodePreviewView : UIView <RJScanQRCodePreviewViewProtocol>

/**
 对象方法创建 RJScanQRCodePreviewView

 @param frame frame
 @param delegate 代理
 @param configuration 配置信息
 @return 实例
 */
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<RJScanQRCodePreviewViewDelegate>)delegate configuration:(RJScanQRCodePreviewViewConfiguration *)configuration;

/**
 类方法创建 RJScanQRCodePreviewView

 @param frame frame
 @param delegate 代理
 @param configuration 配置信息
 @return 实例
 */
+ (instancetype)previewViewWithFrame:(CGRect)frame delegate:(id<RJScanQRCodePreviewViewDelegate>)delegate configuration:(RJScanQRCodePreviewViewConfiguration *)configuration;

/********* 扫描框frame *********/
@property (readonly, nonatomic, assign) CGRect rectFrame;
/********* 代理 *********/
@property (nonatomic, weak) id<RJScanQRCodePreviewViewDelegate> delegate;
/********* 提示语 *********/
@property (readonly, nonatomic, weak) UILabel *tipLbl;

- (CGRect)getInterestRect;

- (void)startScanning;

- (void)stopScanning;

- (void)showTorchSwitch;

- (void)hidenTorchSwitch;

- (void)showIndicatorView;

- (void)hidenIndicatorView;

@end

NS_ASSUME_NONNULL_END
