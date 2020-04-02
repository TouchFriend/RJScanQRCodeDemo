//
//  RJScanQRCodePreviewViewConfiguration.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/23.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "RJScanQRCodePreviewViewConfiguration.h"

@implementation RJScanQRCodePreviewViewConfiguration

+ (instancetype)defaultConfiguration
{
    return [[self alloc] init];
}

- (UIColor *)rectBorderColor
{
    if (_rectBorderColor == nil)
    {
        _rectBorderColor = [UIColor whiteColor];
    }
    return _rectBorderColor;
}

- (UIColor *)rectCornerColor
{
    if (_rectCornerColor == nil)
    {
        _rectCornerColor = [UIColor whiteColor];
    }
    return _rectCornerColor;
}

- (UIColor *)scanningLineColor
{
    if (_scanningLineColor == nil)
    {
        _scanningLineColor = [UIColor whiteColor];
    }
    return _scanningLineColor;
}

- (NSString *)tipTitle
{
    if (_tipTitle == nil)
    {
        _tipTitle = @"将二维码/条形码放入框内即可自动扫描";
    }
    return _tipTitle;
}

@end
