//
//  RJScanQRCodeAuthorizationManager.h
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2020/4/2.
//  Copyright © 2020 RJ. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RJScanQRCodeAuthorizationManager : NSObject

/// 获取摄像头权限状态
/// @param completion 权限 granted：是否允许 firstTime:是否第一次请求
+ (void)cameraAuthorizeWithCompletion:(void(^)(BOOL granted,BOOL firstTime))completion;

/// 获取相册权限状态
/// @param completion 权限 granted：是否允许 firstTime:是否第一次请求
+ (void)photoAuthorizeWithCompletion:(void(^)(BOOL granted,BOOL firstTime))completion;

/// 引导用户打开摄像头权限用于扫描二维码
+ (void)guideUserOpenCameraAuthToScanQRCode;

/// 引导用户授权
/// @param title 标题
/// @param message 内容
+ (void)guideUserOpenAuthWithTitle:(NSString *)title message:(NSString *)message;

/// 进入系统设置页面，APP本身的权限管理页面
+ (void)openAppSetting;

@end

NS_ASSUME_NONNULL_END
