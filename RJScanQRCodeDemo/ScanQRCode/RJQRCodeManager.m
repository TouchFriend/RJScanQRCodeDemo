//
//  RJQRCodeManager.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/20.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "RJQRCodeManager.h"
#import <AVFoundation/AVFoundation.h>
#import "RJScanQRCodePreviewViewProtocol.h"

//亮度监测回调
typedef void(^LightObserverBlock)(BOOL dimmed, BOOL torchOn);

static CGFloat const RJMinZoomFactor = 1.0;
static CGFloat const RJMaxZoomFactor = 4.0;

static NSString *RJInputCorrectionLevelL = @"L";//!< L: 7%
static NSString *RJInputCorrectionLevelM = @"M";//!< M: 15%
static NSString *RJInputCorrectionLevelQ = @"Q";//!< Q: 25%
static NSString *RJInputCorrectionLevelH = @"H";//!< H: 30%

@interface RJQRCodeManager () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
/********* containerView *********/
@property (nonatomic, weak) UIView<RJScanQRCodePreviewViewProtocol> *previewView;
/********* 会话 *********/
@property (nonatomic, strong) AVCaptureSession *session;
/********* 视频预览图层 *********/
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previewLayer;
/********* 元数据输出 *********/
@property (nonatomic, weak) AVCaptureMetadataOutput *output;
/********* 初始化完成block *********/
@property (nonatomic, copy) ScanningCompletedBlock completed;
/********* 扫描结果block *********/
@property (nonatomic, copy) ScanningResultBlock resultBlock;
/********* 扫描到二维码，自动停止扫描 *********/
@property (nonatomic, assign) BOOL autoStop;
/********* 亮度监测block *********/
@property (nonatomic, copy) LightObserverBlock lightObserverBlock;


@end

@implementation RJQRCodeManager


#pragma mark - Init Methods

- (instancetype)initWithPreviewView:(UIView<RJScanQRCodePreviewViewProtocol> *)previewView completed:(ScanningCompletedBlock)completed
{
    if (self = [super init])
    {
        self.previewView = previewView;
        self.completed = completed;
        [self setupInit];
        [self addNotificationObservers];
    }
    return self;
}

#pragma mark - Life Cycle Methods

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [self removeNotificationObservers];
}

#pragma mark - 设置初始化
- (void)setupInit
{
    //显示等待指示器
    if ([self.previewView respondsToSelector:@selector(showIndicatorView)])
    {
        [self.previewView showIndicatorView];
    }
    
    //初始化session比较费时，所以放在子线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //获取摄像头设备
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        //输入设备
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        
        //设置元数据输出
        AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        self.output = output;
        
        //会话
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        self.session = session;
        session.sessionPreset = AVCaptureSessionPresetHigh;
        if ([session canAddInput:input])
        {
            [session addInput:input];
        }
        
        if ([session canAddOutput:output])
        {
            [session addOutput:output];
            // 设置元数据处理类型(注意, 一定要将设置元数据处理类型的代码添加到会话添加输出之后)
            if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode] && [output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code] && [output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code])
            {
                output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeEAN13Code];
            }
        }
        
        //修改device属性之前须lock
        [device lockForConfiguration:nil];
        if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        [device unlockForConfiguration];
        
        //回到主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            //添加预览图层
            AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
            self.previewLayer = previewLayer;
            [self.previewView.layer insertSublayer:previewLayer atIndex:0];
            previewLayer.frame = self.previewView.bounds;
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            
            //设置扫描区域
            if ([self.previewView respondsToSelector:@selector(getInterestRect)])
            {
                CGRect interestRect = [self.previewView getInterestRect];
                [self setInterestRect:interestRect];
            }
            
            //缩放手势
            UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchAction:)];
            [self.previewView addGestureRecognizer:pinchGesture];
            
            //双击手势
            UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAction:)];
            doubleTapGesture.numberOfTapsRequired = 2;
            [self.previewView addGestureRecognizer:doubleTapGesture];
            
            //隐藏等待指示器
            if ([self.previewView respondsToSelector:@selector(hidenIndicatorView)])
            {
                [self.previewView hidenIndicatorView];
            }
            
            if (self.completed)
            {
                self.completed(self);
            }
        });
        
    });
    
    
    
    
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate Methods
//扫描到的信息
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    AVMetadataMachineReadableCodeObject *code = metadataObjects.firstObject;
    if (code.stringValue != nil && code.stringValue.length > 0)
    {
        [self handleCodeString:code.stringValue];
        
    }
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate Methods

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // 通过sampleBuffer获取到光线亮度值brightness
    CFDictionaryRef metadataDicRef = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadataDic = (__bridge NSDictionary *)metadataDicRef;
    NSDictionary *exifDic = metadataDic[(__bridge NSString *)kCGImagePropertyExifDictionary];
    CFRelease(metadataDicRef);
    
    // 初始化一些变量，作为是否透传brightness的因数
    CGFloat brightness = [exifDic[(__bridge NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL torchOn = device.torchMode == AVCaptureTorchModeOn;
    BOOL dimmed = brightness < 0.7;
    
    if (self.lightObserverBlock)
    {
        self.lightObserverBlock(dimmed, torchOn);
    }
    
    
}

#pragma mark - UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    UIImage *pickerImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    
    //识别图片中的二维码
    __weak typeof(self) weakSelf = self;
    [[self class] singleDetectorQRCodeImage:pickerImage completed:^(NSString *codeString) {
        [picker dismissViewControllerAnimated:YES completion:^{
            [weakSelf handleCodeString:codeString];
        }];
    }];
    
    
}

//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
//{
//    [picker dismissViewControllerAnimated:YES completion:nil];
//}

#pragma mark - Override Methods

#pragma mark - Public Methods

- (void)startScanningWithResultBlock:(ScanningResultBlock)resultBlock
{
    [self startScanningWithResultBlock:resultBlock autoStop:NO];
}

- (void)startScanningWithResultBlock:(ScanningResultBlock)resultBlock autoStop:(BOOL)autoStop
{
    self.resultBlock = resultBlock;
    self.autoStop = autoStop;
    
    [self startScanning];
    
}

- (void)stopScanning
{
    if (self.session && self.session.isRunning)
    {
        [self.session stopRunning];
        if ([self.previewView respondsToSelector:@selector(stopScanning)])
        {
            [self.previewView stopScanning];
        }
    }
    
    //关闭手电筒
    [self torchStatusSwitch:NO];
    //重置缩放比例（解决 放大->进入后台->再进入前台，有一定的几率奔溃。）
#warning 解决 放大->进入后台->再进入前台，有一定的几率奔溃。
    [self resetZoomFactor];
    
}

- (void)setInterestRect:(CGRect)originRect
{
    if (CGRectEqualToRect(originRect, CGRectZero))
    {
        return;
    }
    // 设置兴趣点
    // 注意: 兴趣点的坐标是横屏状态(0, 0 代表竖屏右上角, 1,1 代表竖屏左下角)
    
    NSLog(@"扫描区域范围：%@", NSStringFromCGRect(originRect));
    CGFloat x = originRect.origin.x / self.previewView.frame.size.width;
    CGFloat y = originRect.origin.y / self.previewView.frame.size.height;
    CGFloat width = originRect.size.width / self.previewView.frame.size.width;
    CGFloat height = originRect.size.height / self.previewView.frame.size.height;
    
    self.output.rectOfInterest = CGRectMake(y, x, height, width);
}


- (void)turnOnTorch:(BOOL)on
{
    [self torchStatusSwitch:on];
}

- (void)presentPhotoLibraryWithRootController:(UIViewController *)rootController resultBlock:(ScanningResultBlock)resultBlock
{
    self.resultBlock = resultBlock;
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
//    imagePickerController.allowsEditing = YES;
    [rootController presentViewController:imagePickerController animated:YES completion:nil];
    
}

#pragma mark - 识别图片中的二维码

//识别图片中的二维码,返回第一个结果
+ (void)singleDetectorQRCodeImage:(UIImage *)qrCodeImage completed:(void(^)(NSString *codeString))completed
{
    [self allDetectorQRCodeImage:qrCodeImage completed:^(NSArray *codeStringArr) {
        if (completed)
        {
            NSString *codeString = (codeStringArr && codeStringArr.count > 0) ? codeStringArr.firstObject : @"";
            completed(codeString);
        }
    }];
}

//识别图片中的二维码,返回全部结果
+ (void)allDetectorQRCodeImage:(UIImage *)qrCodeImage completed:(void(^)(NSArray *codeStringArr))completed
{
    [self detectorQRCodeImage:qrCodeImage isDrawFrame:NO withCompleted:^(NSArray *codeStringArr, UIImage *resultImage) {
        if (completed)
        {
            completed(codeStringArr);
        }
    }];
}

//识别图片中的二维码,返回全部结果，并绘画二维码边框
+ (void)detectorQRCodeImage:(UIImage *)sourceImage isDrawFrame:(BOOL)isDrawFrame withCompleted:(void(^)(NSArray *codeStringArr, UIImage *resultImage))completed
{
    if (sourceImage == nil)
    {
        completed(nil, nil);
    }
    CIImage *imageCI = [CIImage imageWithCGImage:sourceImage.CGImage];
    
    //生成一个探测器
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{
                                                                          CIDetectorAccuracy : CIDetectorAccuracyHigh
                                                                          }];
    //探测二维码特征
    NSArray<CIFeature *> *featureArr = [detector featuresInImage:imageCI];
    UIImage *resultImage = sourceImage;
    NSMutableArray *codeStringArrM = [NSMutableArray array];
    for (CIQRCodeFeature *feature in featureArr)
    {
        NSString *codeMessage = feature.messageString;
        if (codeMessage == nil || codeMessage.length == 0)
        {
            continue;
        }
        [codeStringArrM addObject:codeMessage];
        if (isDrawFrame)
        {
            //绘画二维码边框
            resultImage = [self drawFrameWithImage:resultImage feature:feature];
        }
    }
    
    if (completed)
    {
        completed([NSArray arrayWithArray:codeStringArrM], resultImage);
    }
}

//绘画二维码边框
+ (UIImage *)drawFrameWithImage:(UIImage *)bgImage feature:(CIQRCodeFeature *)feature
{
    CGSize imageSize = bgImage.size;
    //1.开启图像上下文
    UIGraphicsBeginImageContext(imageSize);
    
    //2.绘制背景图片
    [bgImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    //3.转换坐标系
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(contextRef, 1, -1);
    CGContextTranslateCTM(contextRef, 0, -imageSize.height);
    //4.绘制路径
    CGRect bounds = feature.bounds;
    UIBezierPath * path = [UIBezierPath bezierPathWithRect:bounds];
    [UIColor.redColor setStroke];
    path.lineWidth = 6;
    [path stroke];
    //5.获取图片
    UIImage * resultImage = UIGraphicsGetImageFromCurrentImageContext();
    //6.关闭图像上下文
    UIGraphicsEndImageContext();
    return resultImage;
}

#pragma mark - 生成二维码/条形码

//生成二维码
+ (UIImage *)generatorQRCodeImage:(NSString *)codeStr withSize:(CGSize)size
{
    return [self generatorQRCodeImage:codeStr logoImage:nil withSize:size];
}

//生成二维码,带中间logo
+ (UIImage *)generatorQRCodeImage:(NSString *)codeStr logoImage:(UIImage *)logoImage withSize:(CGSize)size
{
    if(codeStr == nil || codeStr.length == 0)
    {
        
        return nil;
    }
    
    //1.生成滤镜
    CIFilter * filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //2.设置相关属性
    [filter setDefaults];
    //3.设置输入数据
    NSData * strData = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
    //3.1KVC
    [filter setValue:strData forKey:@"inputMessage"];
    //3.2设置容错率
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    //4.获取输出结果
    CIImage * outputImage = [filter outputImage];
    //获取指定大小的图片
    UIImage * resultImage = [self scaleImage:outputImage toSize:size];
    //5.设置前景图片
    if(logoImage != nil)
    {
        resultImage = [self combinateImage:resultImage logoImage:logoImage];
    }
    
    return resultImage;
}

//生成条形码
+ (UIImage *)generateCode128:(NSString *)code size:(CGSize)size
{
    NSData *codeData = [code dataUsingEncoding:NSUTF8StringEncoding];
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator" withInputParameters:@{@"inputMessage": codeData, @"inputQuietSpace": @.0}];
    /* @{@"inputMessage": codeData, @"inputQuietSpace": @(.0), @"inputBarcodeHeight": @(size.width / 3)} */
    UIImage *codeImage = [self scaleImage:filter.outputImage toSize:size];
    
    return codeImage;
}


/**
 缩放图片(生成高质量图片）

 @param image 要缩放的图片
 @param size 缩放目标尺寸
 @return 缩放完成后的图片
 */
+ (UIImage *)scaleImage:(CIImage *)image toSize:(CGSize)size
{
    //! 将CIImage转成CGImageRef
    CGRect integralRect = image.extent;// CGRectIntegral(image.extent);// 将rect取整后返回，origin取舍，size取入
    CGImageRef imageRef = [[CIContext context] createCGImage:image fromRect:integralRect];
    
    //! 创建上下文
    CGFloat sideScale = fminf(size.width / integralRect.size.width, size.width / integralRect.size.height) * [UIScreen mainScreen].scale;// 计算需要缩放的比例
    size_t contextRefWidth = ceilf(integralRect.size.width * sideScale);
    size_t contextRefHeight = ceilf(integralRect.size.height * sideScale);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    CGContextRef contextRef = CGBitmapContextCreate(nil, contextRefWidth, contextRefHeight, 8, 0, colorSpaceRef, (CGBitmapInfo)kCGImageAlphaNone);// 灰度、不透明
    CGColorSpaceRelease(colorSpaceRef);
    
    CGContextSetInterpolationQuality(contextRef, kCGInterpolationNone);// 设置上下文无插值
    CGContextScaleCTM(contextRef, sideScale, sideScale);// 设置上下文缩放
    CGContextDrawImage(contextRef, integralRect, imageRef);// 在上下文中的integralRect中绘制imageRef
    CGImageRelease(imageRef);
    
    //! 从上下文中获取CGImageRef
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(contextRef);
    CGContextRelease(contextRef);
    
    //! 将CGImageRefc转成UIImage
    UIImage *scaledImage = [UIImage imageWithCGImage:scaledImageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    CGImageRelease(scaledImageRef);
    
    return scaledImage;
}


/**
 合并图片 二维码 + logo图片

 @param codeImage 二维码图片
 @param logoImage logo图片
 @return 合并的图片
 */
+ (UIImage *)combinateImage:(UIImage *)codeImage logoImage:(UIImage *)logoImage
{
    CGSize codeImageSize = [codeImage size];
    //1.开启图像上下文
    UIGraphicsBeginImageContext(codeImageSize);
    
    //2.绘画背景图片
    [codeImage drawInRect:CGRectMake(0, 0, codeImageSize.width,  codeImageSize.height)];
    
    //3.绘画logo图片
    CGFloat logoImageSide = fmin(codeImage.size.width, codeImage.size.width) / 4.0;
    CGFloat logoImageX = (codeImageSize.width - logoImageSide) * 0.5;
    CGFloat logoImageY = (codeImageSize.height - logoImageSide) * 0.5;
    CGRect logoRect = CGRectMake(logoImageX, logoImageY, logoImageSide, logoImageSide);
    
    //logo圆角
    UIBezierPath *logoCornerPath = [UIBezierPath bezierPathWithRoundedRect:logoRect cornerRadius:logoImageSide / 5.0];
    logoCornerPath.lineWidth = 2.0;
    [[UIColor whiteColor] set];
    [logoCornerPath stroke];
    [logoCornerPath addClip];
    
    //将logo画到上下文中
    [logoImage drawInRect:logoRect];
    
    //4.取出图片
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    //5.关闭图像上下文
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Private Methods

- (void)startScanning
{
    if (self.session && !self.session.isRunning)
    {
        [self.session startRunning];
        if ([self.previewView respondsToSelector:@selector(startScanning)])
        {
            [self.previewView startScanning];
        }
        
    }
    
    //开始亮度监测
    __weak typeof(self) weakSelf = self;
    [self observerLightStatus:^(BOOL dimmed, BOOL torchOn) {
       if (dimmed || torchOn)// 变为弱光或者手电筒处于开启状态
       {
           // 停止扫描动画
           if ([weakSelf.previewView respondsToSelector:@selector(stopScanning)])
           {
               [weakSelf.previewView stopScanning];
           }
           // 显示手电筒开关
           if ([weakSelf.previewView respondsToSelector:@selector(showTorchSwitch:)])
           {
               [weakSelf.previewView showTorchSwitch:NO];
           }
        }
        else// 变为亮光并且手电筒处于关闭状态
        {
            // 开始扫描动画
            if ([weakSelf.previewView respondsToSelector:@selector(startScanning)])
            {
                [weakSelf.previewView startScanning];
            }
            // 隐藏手电筒开关
            if ([weakSelf.previewView respondsToSelector:@selector(hidenTorchSwitch:)])
            {
                [weakSelf.previewView hidenTorchSwitch:NO];
            }
        }
    }];
}

//亮度监测
- (void)observerLightStatus:(LightObserverBlock)block
{
    self.lightObserverBlock = block;
    AVCaptureVideoDataOutput *lightOutput = [[AVCaptureVideoDataOutput alloc] init];
    [lightOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    if ([self.session canAddOutput:lightOutput])
    {
        [self.session addOutput:lightOutput];
    }
}

//打开/关闭手电筒
- (void)torchStatusSwitch:(BOOL)on
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureTorchMode torchMode = on ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
    
    if (device.hasFlash && device.hasTorch && device.torchMode != torchMode)
    {
        [device lockForConfiguration:nil];// 修改device属性之前须lock
        [device setTorchMode:torchMode];// 修改device的手电筒状态
        [device unlockForConfiguration];// 修改device属性之后unlock
    }
}

//注册通知
- (void)addNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
}

//移除通知
- (void)removeNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//重置缩放比例
- (void)resetZoomFactor
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];// 修改device属性之前须lock
    device.videoZoomFactor = 1.0;// 修改device的视频缩放比例
    [device unlockForConfiguration];// 修改device属性之后unlock
}

//处理扫到的二维码
- (void)handleCodeString:(NSString *)codeString
{
    if (self.autoStop)
    {
        [self stopScanning];
    }
    
    if (self.resultBlock)
    {
        self.resultBlock(codeString);
    }
}


#pragma mark - Gesture Methods

- (void)handlePinchAction:(UIPinchGestureRecognizer *)gesture
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //设定有效缩放范围，防止超出范围而崩溃
    CGFloat minZoomFactor = RJMinZoomFactor;
    CGFloat maxZoomFactor = RJMaxZoomFactor;
    maxZoomFactor = fmin(maxZoomFactor, device.activeFormat.videoMaxZoomFactor);
    
    if (@available(iOS 11.0, *)) {
        minZoomFactor = device.minAvailableVideoZoomFactor;
        maxZoomFactor = fmin(maxZoomFactor, device.maxAvailableVideoZoomFactor);
    } else {
        // Fallback on earlier versions
    }
    
    static CGFloat lastZoomFactor = 1.0;
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        // 记录上次缩放的比例，本次缩放在上次的基础上叠加
        lastZoomFactor = device.videoZoomFactor;// lastZoomFactor为外部变量
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        CGFloat zoomFactor = lastZoomFactor * gesture.scale;
        zoomFactor = fmaxf(fminf(zoomFactor, maxZoomFactor), minZoomFactor);
        [device lockForConfiguration:nil];// 修改device属性之前须lock
        device.videoZoomFactor = zoomFactor;// 修改device的视频缩放比例
        [device unlockForConfiguration];// 修改device属性之后unlock
    }
    
}

- (void)handleDoubleTapAction:(UITapGestureRecognizer *)tapGesture
{
    if (tapGesture.state != UIGestureRecognizerStateEnded)
    {
        return;
    }
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //设定有效缩放范围，防止超出范围而崩溃
    CGFloat minZoomFactor = RJMinZoomFactor;
    CGFloat maxZoomFactor = RJMaxZoomFactor;
    maxZoomFactor = fmin(maxZoomFactor, device.activeFormat.videoMaxZoomFactor);
    
    if (@available(iOS 11.0, *)) {
        minZoomFactor = device.minAvailableVideoZoomFactor;
        maxZoomFactor = fmin(maxZoomFactor, device.maxAvailableVideoZoomFactor);
    } else {
        // Fallback on earlier versions
    }
    
    CGFloat currentZoomFactor = device.videoZoomFactor;
    
    CGFloat zoomFactor = currentZoomFactor < maxZoomFactor * 0.6 ? maxZoomFactor : minZoomFactor;
    [device lockForConfiguration:nil];// 修改device属性之前须lock
    [device rampToVideoZoomFactor:zoomFactor withRate:10];// 平滑改变device的视频缩放比例
    [device unlockForConfiguration];// 修改device属性之后unlock
}


#pragma mark - Properties Methods

#pragma mark - Notification Methods

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self startScanning];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self stopScanning];
}

- (void)captureSessionRuntimeError:(NSNotification *)notification
{
    NSLog(@"captureSessionRuntimeError：%@", notification);
}

@end
