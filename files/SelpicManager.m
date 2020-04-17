//
//  SelpicManager.m
//  Selpic
//
//  Created by 徐迪华 on 2020/1/3.
//  Copyright © 2020 xdh. All rights reserved.
//

#import "SelpicManager.h"
#import "Product.h"

@interface SelpicManager()<ProductDelegate>
{
    Product *product;
}
@end
@implementation SelpicManager

+(instancetype)sharedManager{
    static SelpicManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [self new];
        [manager initSokect];
    });
}
- (void)initSokect{
    product = [Product globalProduct];
    product.delegate = self;
    [product connect];
}
//获取设备信息
- (void)getDeviceInfo:(void (^)(NSDictionary * _Nonnull, NSError * _Nonnull))complite{
    [[Product globalProduct] getDeviceInfo:^(NSDictionary *deviceInfo, NSError *error) {
        if (complite) {
            complite(deviceInfo,error);
        }
    }];
}
//设置打印参数
- (void)setPrintParam:(NSDictionary *)dict Complite:(void (^)(NSError * _Nonnull))complite{
    [[Product globalProduct] setPrintParam:dict complete:^(NSError *error) {
        if (complite) {
            complite(error);
          }
        }];
}
//发送OTA数据
-(void)sendOtaWithProgress:(void(^)(float v))progress Complite:(void (^)(NSError * _Nonnull))complite{
         __weak typeof(self) weakself = self;
         [dhServerApi unLockScren];//防止锁屏
         [[Product globalProduct] startOTAUpgradeWithProgress:^(float v) {
                    __strong typeof(weakself) strongself = weakself;
                    if (!strongself) {
                        return;
                    }
                    if (v > 1) {
                        v = 1;
                    }
    
                  if (progress) {
                     progress(v);
                 }
      
                } complete:^(id ret, NSError *error) {
                    [dhServerApi lockScren];//允许锁屏
                    __strong typeof(weakself) strongself = weakself;
                    if (!strongself) {
                        return;
                    }
                    if (error) {

                    }else {
                        [[Product globalProduct] clear];
                        [[Product globalProduct] disconnect];
                        
                    }
                     if (complite) {
                           complite(error);
                       }
                   
                }];
    
}
//发送初始化打印信息
-(void)sendPrintDataOtaWithProgress:(void(^)(float v))progress Complite:(void (^)(NSError * _Nonnull))complite{
        [dhServerApi unLockScren];
        [[Product globalProduct] startPrtOTAUpgradeWithProgress:^(float v) {
        } complete:^(id ret, NSError *error) {
            [dhServerApi lockScren];
            if (!error) {
            [dhServerApi saveStrWithKey:@"hasOTA" Value:@"NO"];
            }else{
                   }
               }];
}
-(void)sendPrintData:(NSDictionary *)dict Complite:(void (^)(NSError * _Nonnull))complite{
    __weak typeof(self)weakSelf = self;
    int gray = 2;
    [product setPrintGray:gray complete:^(NSError *error) {
    if (error) {
       
    }else {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    __strong __typeof(weakSelf)strongSelf = weakSelf;
    [dhServerApi unLockScren];//防止锁屏
    [strongSelf->product printItems:nil progress:nil complete:^(id ret, NSError *error) {
    [dhServerApi lockScren];//允许锁屏
        if (complite) {
            complite(error);
             }
          }];
        });
      }
    }];
    
}
- (CGRect)getContentFrame {
//    获取打印区域，从外部传入参数
}

- (UIImage *)getImageByFrame:(CGRect)frame {
//截取image
    
}

@end
