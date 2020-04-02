//
//  UIImage+RJScanQRCode.h
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/23.
//  Copyright © 2019 RJ. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (RJScanQRCode)

+ (instancetype)rj_imageNamedFromMyBundle:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
