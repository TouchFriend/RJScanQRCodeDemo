//
//  UIImage+RJScanQRCode.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/23.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "UIImage+RJScanQRCode.h"
#import "NSBundle+RJScanQRCode.h"

@implementation UIImage (RJScanQRCode)

+ (instancetype)rj_imageNamedFromMyBundle:(NSString *)name
{
    NSBundle *imageBundle = [NSBundle rj_scanQRCodeBundle];
    name = [name stringByAppendingString:@"@2x"];
    NSString *imagePath = [imageBundle pathForResource:name ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (!image)
    {
        //兼容业务方自己设置图片的方式
        name = [name stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
        image = [UIImage imageNamed:name];
    }
    return image;
}

@end
