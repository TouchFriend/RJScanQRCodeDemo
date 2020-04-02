//
//  NJCIQRCodeTool.h
//  Sepetember_fifteen_二维码的综合使用
//
//  Created by TouchWorld on 2017/9/23.
//  Copyright © 2017年 qichen. All rights reserved.
//

// .h
#define single_interface(class)  + (class *)shared##class;

// .m
// \ 代表下一行也属于宏
// ## 是分隔符
#define single_implementation(class) \
static class *_instance; \
\
+ (class *)shared##class \
{ \
if (_instance == nil) { \
_instance = [[self alloc] init]; \
} \
return _instance; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [super allocWithZone:zone]; \
}); \
return _instance; \
}

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface NJCIQRCodeTool : NSObject
single_interface(NJCIQRCodeTool)
// 设置是否需要描绘二维码边框
@property (nonatomic, assign) BOOL isDrawQRCodeRect;


/**
 
 根据文字，生成对应的二维码图片
 
 @param str 内容
 @param centerImage 中间图片 可为nil
 @param size 尺寸
 @return 二维码
 */
+ (UIImage *)QRCodeGenerator:(NSString *)str centerImage:(UIImage *)centerImage withSize:(CGFloat) size;
//识别图片中的二维码

/**
 识别图片中的二维码

 @param sourceImage 二维码图片
 @param isDrawFrame 是否对二维码绘画一个矩形边框
 @param completed 回调block
 */
+ (void)detectorQICodeImage:(UIImage *)sourceImage isDrawFrame:(BOOL)isDrawFrame withCompleted:(void(^)(NSString * str,UIImage * resultImage)) completed;

// 开始扫描二维码

/**
 开始扫描二维码

 @param view 需要添加预览层的视图
 @param resultBlock 回调block
 */
- (void)beginScanInView:(UIView *)view result:(void(^)(NSArray<NSString *> *resultStrs))resultBlock;

// 停止扫描二维码
- (void)stopScan;

// 设置兴趣点(扫描的有限区域)
- (void)setInsteretRect:(CGRect)originRect;
@end
