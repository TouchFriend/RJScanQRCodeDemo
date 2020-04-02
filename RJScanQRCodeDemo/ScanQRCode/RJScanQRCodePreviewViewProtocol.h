//
//  RJScanQRCodePreviewViewProtocol.h
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/21.
//  Copyright © 2019 RJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@protocol RJScanQRCodePreviewViewProtocol <NSObject>

@optional


/**
 RJQRCodeManager会根据此方法来设置扫描区域

 @return 扫描区域的frame
 */
- (CGRect)getInterestRect;

- (void)startScanning;

- (void)stopScanning;

- (void)showTorchSwitch:(BOOL)animate;

- (void)hidenTorchSwitch:(BOOL)animate;

- (void)showIndicatorView;

- (void)hidenIndicatorView;

@end

NS_ASSUME_NONNULL_END
