//
//  RJScanQRCodeViewController.h
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/20.
//  Copyright © 2019 RJ. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@class RJScanQRCodeViewController, RJScanQRCodePreviewViewConfiguration;

@protocol RJScanQRCodeViewControllerDelegate <NSObject>

- (void)scanningResult:(RJScanQRCodeViewController *)scanQRCodeViewController codeString:(NSString *)codeString;

@end

@interface RJScanQRCodeViewController : UIViewController

/********* 配置信息 *********/
@property (nonatomic, strong) RJScanQRCodePreviewViewConfiguration *configuration;
/********* 代理 *********/
@property (nonatomic, weak) id<RJScanQRCodeViewControllerDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
