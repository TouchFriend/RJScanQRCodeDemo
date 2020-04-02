//
//  RJScanQRCodePreviewViewConfiguration.h
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/23.
//  Copyright © 2019 RJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface RJScanQRCodePreviewViewConfiguration : NSObject

+ (instancetype)defaultConfiguration;

/********* 扫描框frame *********/
@property (nonatomic, assign) CGRect rectFrame;
/********* 扫描框边框颜色 默认白色 *********/
@property (nonatomic, strong) UIColor *rectBorderColor;
/********* 扫描框四个角颜色 默认白色 *********/
@property (nonatomic, strong) UIColor *rectCornerColor;
/********* 扫描线颜色 默认白色 *********/
@property (nonatomic, strong) UIColor *scanningLineColor;
/********* 提示标题 *********/
@property (nonatomic, copy) NSString *tipTitle;


@end

NS_ASSUME_NONNULL_END
