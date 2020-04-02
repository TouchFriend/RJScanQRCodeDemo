//
//  RJScanQRCodeAuthorizationManager.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2020/4/2.
//  Copyright © 2020 RJ. All rights reserved.
//

#import "RJScanQRCodeAuthorizationManager.h"
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>

@implementation RJScanQRCodeAuthorizationManager

+ (void)cameraAuthorizeWithCompletion:(void(^)(BOOL granted,BOOL firstTime))completion
{
    AVAuthorizationStatus permission = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (permission) {
        case AVAuthorizationStatusAuthorized:
        {
            completion(YES, NO);
        }
            break;
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:
        {
            completion(NO, NO);
        }
            break;
        case AVAuthorizationStatusNotDetermined:
        {
            //请求权限
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (completion)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(granted, YES);
                    });
                }
            }];
        }
            break;
            
        default:
            break;
    }
}

+ (void)photoAuthorizeWithCompletion:(void(^)(BOOL granted,BOOL firstTime))completion
{
    PHAuthorizationStatus permission = [PHPhotoLibrary authorizationStatus];
    switch (permission) {
        case PHAuthorizationStatusAuthorized:
        {
            completion(YES, NO);
        }
            break;
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
        {
            completion(NO, NO);
        }
            break;
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
               if (completion)
               {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       completion(status == PHAuthorizationStatusAuthorized, YES);
                   });
                   
               }
            }];
        }
            break;
            
        default:
            break;
    }
}

+ (void)guideUserOpenCameraAuthToScanQRCode
{
    [self guideUserOpenAuthWithTitle:@"相机服务未开启" message:@"我们需要您的相机权限，以扫描二维码"];
}

+ (void)guideUserOpenAuthWithTitle:(NSString *)title message:(NSString *)message
{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"暂不" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *settingAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf openAppSetting];
    }];
    
    [alertController addAction:confirmAction];
    [alertController addAction:settingAction];
    alertController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    dispatch_async(dispatch_get_main_queue(), ^{
        [rootViewController presentViewController:alertController animated:YES completion:nil];
    });
    
}


//进入系统设置页面，APP本身的权限管理页面
+ (void)openAppSetting
{
    NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if([[UIApplication sharedApplication] canOpenURL:url])
    {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            // Fallback on earlier versions
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
