//
//  SelpicManager.h
//  Selpic
//
//  Created by 徐迪华 on 2020/1/3.
//  Copyright © 2020 xdh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelpicManager : NSObject
//初始化
+(instancetype)sharedManager;
//获取设备信息
-(void)getDeviceInfo:(void(^)(NSDictionary *result,NSError *error))complite;
/*
 实时接受设备状态
 */
//设置打印参数
-(void)setPrintParam:(NSDictionary*)dict Complite:(void(^)(NSError *error))complite;
//发送OTA数据
-(void)sendOtaWithProgress:(void(^)(float v))progress Complite:(void (^)(NSError * _Nonnull))complite;
//发送OTA初始打印数据
-(void)sendPrintDataOtaWithProgress:(void(^)(float v))progress Complite:(void (^)(NSError * _Nonnull))complite;
//发送打印数据
-(void)sendPrintData:(NSDictionary*)dict Complite:(void(^)(NSError *error))complite;
@end

NS_ASSUME_NONNULL_END
