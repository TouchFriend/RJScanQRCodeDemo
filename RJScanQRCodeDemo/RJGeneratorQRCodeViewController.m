//
//  RJGeneratorQRCodeViewController.m
//  RJScanQRCodeDemo
//
//  Created by TouchWorld on 2019/5/22.
//  Copyright © 2019 RJ. All rights reserved.
//

#import "RJGeneratorQRCodeViewController.h"
#import "RJQRCodeManager.h"

@interface RJGeneratorQRCodeViewController ()
@property (weak, nonatomic) IBOutlet UITextField *codeTextF;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageV;
@property (weak, nonatomic) IBOutlet UISwitch *logoSwitch;
- (IBAction)generateQRCodeBtnClick:(id)sender;
- (IBAction)generateBarCodeBtnClick:(id)sender;

- (IBAction)bgViewClick:(id)sender;

@end

@implementation RJGeneratorQRCodeViewController

#pragma mark - Life Cycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupInit];
}

#pragma mark - 设置初始化
- (void)setupInit
{
    self.view.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Override Methods

#pragma mark - Public Methods

#pragma mark - Private Methods

#pragma mark - Properties Methods

- (IBAction)generateQRCodeBtnClick:(id)sender {
    NSString *codeStr = self.codeTextF.text;
    if (!codeStr || codeStr.length == 0)
    {
        self.qrCodeImageV.image = nil;
        return;
    }
    
    CGSize qrCodeImageSize = self.qrCodeImageV.frame.size;
    BOOL isOn = [self.logoSwitch isOn];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *qrCodeImage = nil;
        if (isOn)
        {
            qrCodeImage = [RJQRCodeManager generatorQRCodeImage:codeStr logoImage:[UIImage imageNamed:@"dog"] withSize:qrCodeImageSize];
        }
        else
        {
            qrCodeImage = [RJQRCodeManager generatorQRCodeImage:codeStr withSize:qrCodeImageSize];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.qrCodeImageV.image = qrCodeImage;
        });
        
    });
    
}

- (IBAction)generateBarCodeBtnClick:(id)sender {
    
    NSString *codeStr = self.codeTextF.text;
    if (!codeStr || codeStr.length == 0)
    {
        self.qrCodeImageV.image = nil;
        return;
    }
    CGSize qrCodeImageSize = self.qrCodeImageV.frame.size;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *qrCodeImage = [RJQRCodeManager generateCode128:codeStr size:qrCodeImageSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.qrCodeImageV.image = qrCodeImage;
        });
    });
    
    
}

- (IBAction)bgViewClick:(id)sender {
    [self.view endEditing:YES];
}
@end
