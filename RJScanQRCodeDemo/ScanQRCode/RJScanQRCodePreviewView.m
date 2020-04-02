//
//  RJScanQRCodePreviewView.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/21.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "RJScanQRCodePreviewView.h"
#import "RJScanQRCodePreviewViewConfiguration.h"
#import "RJScanQRCodePreviewViewProtocol.h"
#import "UIImage+RJScanQRCode.h"

static NSString *const RJScanningLineAnimationKey = @"ScanningLineAnimationKey";

@interface RJScanQRCodePreviewView ()

/********* 配置 *********/
@property (nonatomic, strong) RJScanQRCodePreviewViewConfiguration *configuration;

/********* 扫描框frame *********/
@property (readwrite, nonatomic, assign) CGRect rectFrame;
/********* 扫描框边框颜色 *********/
@property (nonatomic, strong) UIColor *rectBorderColor;
/********* 扫描框四个角颜色 *********/
@property (nonatomic, strong) UIColor *rectCornerColor;
/********* 扫描线颜色 *********/
@property (nonatomic, strong) UIColor *scanningLineColor;
/********* 扫描线 *********/
@property (nonatomic, weak) CAShapeLayer *scanningLineLayer;
/********* 扫描线动画 *********/
@property (nonatomic, strong) CABasicAnimation *scanningLineAnimation;
/********* 手电筒开关 *********/
@property (nonatomic, weak) UIButton *torchSwitchBtn;
/********* 活动指示器 *********/
@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;
/********* 提示语 *********/
@property (readwrite, nonatomic, weak) UILabel *tipLbl;

@end

@implementation RJScanQRCodePreviewView

#pragma mark - Init Methods

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<RJScanQRCodePreviewViewDelegate>)delegate configuration:(RJScanQRCodePreviewViewConfiguration *)configuration
{
    if (self = [super initWithFrame:frame])
    {
        if (delegate == nil)
        {
            @throw [NSException exceptionWithName:@"RJScanQRCodePreviewView" reason:@"RJScanQRCodePreviewView 初始化方法中的代理必须设置" userInfo:nil];
        }
        self.delegate = delegate;
        
        if (configuration == nil)
        {
            @throw [NSException exceptionWithName:@"RJScanQRCodePreviewView" reason:@"RJScanQRCodePreviewView 初始化方法中的配置信息必须设置" userInfo:nil];
        }
        self.configuration = configuration;
        
        if (CGRectEqualToRect(configuration.rectFrame, CGRectZero))
        {
            CGFloat rectSide = fminf(frame.size.width, frame.size.height) * 2 / 3;
            configuration.rectFrame = CGRectMake((frame.size.width - rectSide) * 0.5, (frame.size.height - rectSide) * 0.5, rectSide, rectSide);
        }
        if (CGColorEqualToColor(configuration.rectCornerColor.CGColor, [UIColor clearColor].CGColor))
        {
            configuration.rectCornerColor = [UIColor whiteColor];
        }
        if (CGColorEqualToColor(configuration.scanningLineColor.CGColor, [UIColor clearColor].CGColor))
        {
            configuration.scanningLineColor = [UIColor whiteColor];
        }
        
        self.rectFrame = configuration.rectFrame;
        self.rectBorderColor = configuration.rectBorderColor;
        self.rectCornerColor = configuration.rectCornerColor;;
        self.scanningLineColor = configuration.scanningLineColor;
        [self setupInit];
    }
    return self;
}

+ (instancetype)previewViewWithFrame:(CGRect)frame delegate:(id<RJScanQRCodePreviewViewDelegate>)delegate configuration:(RJScanQRCodePreviewViewConfiguration *)configuration
{
    return [[self alloc] initWithFrame:frame delegate:delegate configuration:configuration];
}

#pragma mark - Life Cycle Methods

#pragma mark - 设置初始化
- (void)setupInit
{
    self.backgroundColor = [UIColor blackColor];
    
    self.layer.masksToBounds = YES;
    self.clipsToBounds = YES;
    
    //添加扫描框边框
    CGFloat rectBorderWidth = 0.5;
    //由于lineWidth是向两边延伸，为了固定扫描框的尺寸，需要偏移
    CGFloat rectBorderOffset = rectBorderWidth * 0.5;
    UIBezierPath *rectBorderPath = [UIBezierPath bezierPathWithRect:CGRectMake(rectBorderOffset, rectBorderOffset, self.rectFrame.size.width - rectBorderWidth, self.rectFrame.size.height - rectBorderWidth)];
    CAShapeLayer *rectBorderLayer = [CAShapeLayer layer];
    rectBorderLayer.strokeColor = self.rectBorderColor.CGColor;
    rectBorderLayer.fillColor = [UIColor clearColor].CGColor;
    rectBorderLayer.lineWidth = rectBorderWidth;
    rectBorderLayer.frame = self.rectFrame;
    rectBorderLayer.path = rectBorderPath.CGPath;
    [self.layer addSublayer:rectBorderLayer];
    
    //添加扫描框四个角
    CGFloat rectCornerWidth = 2.0;
    CGFloat rectCornerOffset = rectCornerWidth * 0.5;
    CGFloat rectCornerLength = fminf(self.rectFrame.size.width, self.rectFrame.size.height) / 12.0;
    UIBezierPath *rectCornerPath = [UIBezierPath bezierPath];
    //左上角
    [rectCornerPath moveToPoint:CGPointMake(rectCornerOffset, 0)];
    [rectCornerPath addLineToPoint:CGPointMake(rectCornerOffset, rectCornerLength)];
    [rectCornerPath moveToPoint:CGPointMake(0, rectCornerOffset)];
    [rectCornerPath addLineToPoint:CGPointMake(rectCornerLength, rectCornerOffset)];
    
    //右上角
    [rectCornerPath moveToPoint:CGPointMake(self.rectFrame.size.width - rectCornerOffset, 0)];
    [rectCornerPath addLineToPoint:CGPointMake(self.rectFrame.size.width - rectCornerOffset, rectCornerLength)];
    [rectCornerPath moveToPoint:CGPointMake(self.rectFrame.size.width, rectCornerOffset)];
    [rectCornerPath addLineToPoint:CGPointMake(self.rectFrame.size.width - rectCornerLength, rectCornerOffset)];
    
    //右下角
    [rectCornerPath moveToPoint:CGPointMake(self.rectFrame.size.width - rectCornerOffset, self.rectFrame.size.height)];
    [rectCornerPath addLineToPoint:CGPointMake(self.rectFrame.size.width - rectCornerOffset, self.rectFrame.size.height - rectCornerLength)];
    [rectCornerPath moveToPoint:CGPointMake(self.rectFrame.size.width, self.rectFrame.size.height - rectCornerOffset)];
    [rectCornerPath addLineToPoint:CGPointMake(self.rectFrame.size.width - rectCornerLength, self.rectFrame.size.height - rectCornerOffset)];
    
    //左下角
    [rectCornerPath moveToPoint:CGPointMake(rectCornerOffset, self.rectFrame.size.height)];
    [rectCornerPath addLineToPoint:CGPointMake(rectCornerOffset, self.rectFrame.size.height - rectCornerLength)];
    [rectCornerPath moveToPoint:CGPointMake(0, self.rectFrame.size.height - rectCornerOffset)];
    [rectCornerPath addLineToPoint:CGPointMake(rectCornerLength, self.rectFrame.size.height - rectCornerOffset)];
    
    CAShapeLayer *rectCornerLayer = [CAShapeLayer layer];
    rectCornerLayer.frame = self.rectFrame;
    rectCornerLayer.path = rectCornerPath.CGPath;
    rectCornerLayer.strokeColor = self.rectCornerColor.CGColor;
    rectCornerLayer.lineWidth = rectCornerWidth;
    [self.layer addSublayer:rectCornerLayer];
    
    //遮罩 + 镂空
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.bounds];
    UIBezierPath *spacePath = [[UIBezierPath bezierPathWithRect:self.rectFrame] bezierPathByReversingPath];
    [maskPath appendPath:spacePath];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.fillColor = [UIColor colorWithWhite:0.0 alpha:0.6].CGColor;
    maskLayer.path = maskPath.CGPath;
    [self.layer addSublayer:maskLayer];
    
    //扫描线
    CGRect scanningLineFrame = CGRectMake(self.rectFrame.origin.x + 5.0, self.rectFrame.origin.y, self.rectFrame.size.width - 10.0, 1.5);
    UIBezierPath *scanningLinePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 0.0, scanningLineFrame.size.width, scanningLineFrame.size.height)];
    CAShapeLayer *scanningLineLayer = [CAShapeLayer layer];
    scanningLineLayer.frame = scanningLineFrame;
    scanningLineLayer.path = scanningLinePath.CGPath;
    scanningLineLayer.fillColor = self.scanningLineColor.CGColor;
    scanningLineLayer.hidden = YES;
    //设置阴影
    scanningLineLayer.shadowColor = self.scanningLineColor.CGColor;
    scanningLineLayer.shadowRadius = 5.0;
    scanningLineLayer.shadowOpacity = 0.5;
    scanningLineLayer.shadowOffset = CGSizeMake(0.0, 0.0);
    [self.layer addSublayer:scanningLineLayer];
    self.scanningLineLayer = scanningLineLayer;
    
    //扫描线动画
    CABasicAnimation *scanningLineAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    scanningLineAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(scanningLineLayer.frame.origin.x + scanningLineLayer.frame.size.width * 0.5, scanningLineLayer.frame.origin.y)];
    scanningLineAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(scanningLineLayer.frame.origin.x + scanningLineLayer.frame.size.width * 0.5, self.rectFrame.origin.y + self.rectFrame.size.height - scanningLineLayer.frame.size.height)];
    scanningLineAnimation.repeatCount = CGFLOAT_MAX;
    scanningLineAnimation.duration = 2.0;
    //时间曲线
    scanningLineAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    //自动反转
    scanningLineAnimation.autoreverses = YES;
    self.scanningLineAnimation = scanningLineAnimation;
    
    //手电筒开关
    UIButton *torchSwitchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    torchSwitchBtn.bounds = CGRectMake(0.0, 0.0, 73.0, 70.0);
    torchSwitchBtn.center = CGPointMake(CGRectGetMidX(self.rectFrame), CGRectGetMaxY(self.rectFrame) - CGRectGetMidY(torchSwitchBtn.bounds));
    [torchSwitchBtn setTitle:@"轻触照亮" forState:UIControlStateNormal];
    [torchSwitchBtn setTitle:@"轻触关闭" forState:UIControlStateSelected];
    [torchSwitchBtn setImage:[UIImage rj_imageNamedFromMyBundle:@"rj_torch_switch_off"] forState:UIControlStateNormal];
    [torchSwitchBtn setImage:[[UIImage rj_imageNamedFromMyBundle:@"rj_torch_switch_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    torchSwitchBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    torchSwitchBtn.tintColor = self.rectCornerColor;
    torchSwitchBtn.hidden = YES;
    [torchSwitchBtn addTarget:self action:@selector(torchSwitchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:torchSwitchBtn];
    self.torchSwitchBtn = torchSwitchBtn;
    
    //提示语
    UILabel *tipLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    tipLbl.font = [UIFont systemFontOfSize:13.0];
    tipLbl.textAlignment = NSTextAlignmentCenter;
    tipLbl.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    tipLbl.text = self.configuration.tipTitle;
    [tipLbl sizeToFit];
    tipLbl.center = CGPointMake(CGRectGetMidX(self.rectFrame), CGRectGetMaxY(self.rectFrame) + CGRectGetHeight(tipLbl.bounds) * 0.5 + 15.0);
    [self addSubview:tipLbl];
    self.tipLbl = tipLbl;
    
    //活动指示器
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.rectFrame];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    indicatorView.hidesWhenStopped = YES;
    [self addSubview:indicatorView];
    self.indicatorView = indicatorView;
}

#pragma mark - Override Methods

- (void)layoutSubviews {
    [super layoutSubviews];
    //调整位置
    self.torchSwitchBtn.titleEdgeInsets = UIEdgeInsetsMake(self.torchSwitchBtn.imageView.frame.size.height + 5.0, -self.torchSwitchBtn.imageView.frame.size.width, 0.0, 0.0);
    self.torchSwitchBtn.imageEdgeInsets = UIEdgeInsetsMake(0, self.torchSwitchBtn.titleLabel.frame.size.width * 0.5, self.torchSwitchBtn.titleLabel.frame.size.height + 5.0, -self.torchSwitchBtn.titleLabel.frame.size.width * 0.5);
}

#pragma mark - Public Methods

- (CGRect)getInterestRect
{
    return self.rectFrame;
}

- (void)startScanning
{
    self.scanningLineLayer.hidden = NO;
    [self.scanningLineLayer addAnimation:self.scanningLineAnimation forKey:RJScanningLineAnimationKey];
}

- (void)stopScanning
{
    self.scanningLineLayer.hidden = YES;
    [self.scanningLineLayer removeAnimationForKey:RJScanningLineAnimationKey];
}

- (void)showTorchSwitch
{
    self.torchSwitchBtn.hidden = NO;
    self.torchSwitchBtn.alpha = 0.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.torchSwitchBtn.alpha = 1.0;
    }];
}

- (void)hidenTorchSwitch
{
    self.torchSwitchBtn.alpha = 1.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.torchSwitchBtn.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.torchSwitchBtn.hidden = YES;
    }];
}

- (void)showIndicatorView
{
    [self.indicatorView startAnimating];
}

- (void)hidenIndicatorView
{
    [self.indicatorView stopAnimating];
}

#pragma mark - Target Methods

- (void)torchSwitchBtnClick:(UIButton *)torchSwitchBtn
{
//    torchSwitchBtn.selected = !torchSwitchBtn.selected;
    if ([self.delegate respondsToSelector:@selector(scanQRCodePreviewView:didClickedTorchSwitch:)])
    {
        [self.delegate scanQRCodePreviewView:self didClickedTorchSwitch:torchSwitchBtn];
    }
}

#pragma mark - Private Methods



#pragma mark - Properties Methods

@end
