//
//  NSBundle+RJScanQRCode.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/23.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "NSBundle+RJScanQRCode.h"
#import "RJScanQRCodeViewController.h"

@implementation NSBundle (RJScanQRCode)

+ (instancetype)rj_scanQRCodeBundle
{
    static NSBundle *scanQRCodeBundle = nil;
    if (scanQRCodeBundle == nil)
    {
        // 这里不使用mainBundle是为了适配pod 1.x和0.x
        NSBundle *bundle = [NSBundle bundleForClass:[RJScanQRCodeViewController class]];
        scanQRCodeBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"RJScanQRCode" ofType:@"bundle"]];
    }
    return scanQRCodeBundle;
}


@end
