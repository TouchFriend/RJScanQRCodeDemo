//
//  RJQRCodeManager.h
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/20.
//  Copyright © 2019 RJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RJQRCodeManager;
@protocol RJScanQRCodePreviewViewProtocol;

typedef void(^ScanningCompletedBlock)(RJQRCodeManager * _Nonnull manager);
typedef void(^ScanningResultBlock)(NSString * _Nullable resultStr);

NS_ASSUME_NONNULL_BEGIN

@interface RJQRCodeManager : NSObject

- (instancetype)initWithPreviewView:(UIView<RJScanQRCodePreviewViewProtocol> *)previewView completed:(ScanningCompletedBlock)completed;

- (void)startScanningWithResultBlock:(ScanningResultBlock)resultBlock;

- (void)startScanningWithResultBlock:(ScanningResultBlock)resultBlock autoStop:(BOOL)autoStop;

- (void)stopScanning;

//打开/关闭手电筒
#warning 手电筒的切换逻辑有点问题，参考微信。在黑暗环境下关闭手电筒，就没有打开手电筒的按钮
- (void)turnOnTorch:(BOOL)on;

/**
 设置扫描区域

 @param originRect 扫描区域的frame
 */
- (void)setInterestRect:(CGRect)originRect;

/**
 从相册选择二维码图片，识别二维码·

 @param rootController modal控制器
 @param resultBlock 识别结果回调
 */
- (void)presentPhotoLibraryWithRootController:(UIViewController *)rootController resultBlock:(ScanningResultBlock)resultBlock;

#pragma mark - 识别图片中的二维码

/**
 识别图片中的二维码,返回第一个结果

 @param qrCodeImage 二维码图片
 @param completed 识别结果回调
 */
+ (void)singleDetectorQRCodeImage:(UIImage *)qrCodeImage completed:(void(^)(NSString *codeString))completed;


/**
 识别图片中的二维码,返回全部结果

 @param qrCodeImage 二维码图片
 @param completed 识别结果回调
 */
+ (void)allDetectorQRCodeImage:(UIImage *)qrCodeImage completed:(void(^)(NSArray *codeStringArr))completed;


/**
 识别图片中的二维码,返回全部结果，并绘画二维码边框

 @param sourceImage 二维码图片
 @param isDrawFrame 是否绘画二维码边框
 @param completed 识别结果回调
 */
+ (void)detectorQRCodeImage:(UIImage *)sourceImage isDrawFrame:(BOOL)isDrawFrame withCompleted:(void(^)(NSArray *codeStringArr, UIImage *resultImage))completed;

#pragma mark - 生成二维码/条形码

/**
 生成二维码

 @param codeStr 二维码内容
 @param size 尺寸
 @return 二维码图片
 */
+ (UIImage *)generatorQRCodeImage:(NSString *)codeStr withSize:(CGSize)size;

/**
 生成二维码,带中间logo

 @param codeStr 二维码内容
 @param logoImage 中间logo
 @param size 尺寸
 @return 二维码图片
 */
+ (UIImage *)generatorQRCodeImage:(NSString *)codeStr logoImage:(UIImage * _Nullable)logoImage withSize:(CGSize)size;

/**
 生成条形码

 @param code 条形码内容
 @param size 尺寸
 @return 条形码
 */
+ (UIImage *)generateCode128:(NSString *)code size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
