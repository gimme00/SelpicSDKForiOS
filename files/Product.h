//
//  Product.h
//  PenMaJi
//
//  Created by Arvin on 2019/8/9.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ProductDefine.h"
#import "dhServerApi.h"

extern NSNotificationName const ProductConnectStatusChangedNotice;
extern NSNotificationName const ProductReceiveDeviceInfoNotice;
extern NSNotificationName const ProductReceivePrintInfoNotice;

@class PrinterItem;

#define PRT_W   300

#define PRT_H  150

#define PRT_H_ipad   300

#define PRT_HPlus   308

#define MAX_SEND    2048
//#define MAX_SEND      4090

//获取有效打印区域 从（0，0）开始计算
@protocol ProductDelegate <NSObject>

- (UIImage *)getImageByFrame:(CGRect)frame;

- (CGRect)getContentFrame;

@end

extern NSErrorDomain const ProductErrorDomain;

@interface Product : NSObject

@property (nonatomic,copy) void (^connectStatusChanged)(int status);//status: 0未连接 1正在连接 2已连接
@property (nonatomic,weak) id <ProductDelegate> delegate;
@property (nonatomic,assign,readonly) int status;
@property (nonatomic,assign,readonly) int DeviceType;//设备类型 0:s1   1:s1+
@property (nonatomic,assign)int hardSorftVer;//固件版本信息，如果固件版本过低，需要从后台拉取下载
@property (nonatomic,assign,readonly) NSString *connectedKey;//设备序列号
@property (nonatomic,strong)NSString *dhInterfaceOrientationMask;
+ (instancetype)globalProduct;

+ (NSString *)upgradeFolder;
+ (NSString *)configJsonFolder;

+ (void)searchWifiList:(void (^)(NSString *wifi))handle;

- (BOOL)connect;

- (BOOL)isDisconnected;

- (BOOL)isConnected;

- (void)disconnect;

- (void)testParse;

- (NSString *)getVersion;
    
- (BOOL)hasNewVersion;

- (void)clear;

- (int)battery;
- (int)chargeStatus;//by cxq at 20191123: 0未充电 1正充电 2充满
- (int)printGray;
- (int)printBox;
- (int)printMata;

- (void)savePrintGray:(int)gray;

#pragma mark - function
- (void)setPrintGrayBoxMata:(int)grayScale Box:(int)PrtColsDelay mata:(int)PrtGrayDelay complete:(void (^)(NSError *error))complete;
- (void)setPrintBoxType:(int)Box complete:(void (^)(NSError *error))complete;

- (void)setPrintmateralType:(int)materal complete:(void (^)(NSError *error))complete;

/* by cxq begin at 20191123:发送结束下载单个命令 **/
- (void)stopDowloadComplete:(void (^)(NSError *error))complete;
/* by cxq end  **/
- (void)setPrintGray:(int)grayScale complete:(void (^)(NSError *error))complete;

- (void)printItems:(NSArray <PrinterItem *> *)items progress:(void (^)(float v))progress complete:(void (^)(id ret,NSError *error))complete;

- (void)startOTAUpgradeWithProgress:(void (^)(float v))progress complete:(void (^)(id ret,NSError *error))complete;

- (void)startPrtOTAUpgradeWithProgress:(void (^)(float v))progress complete:(void (^)(id ret,NSError *error))complete;

- (void)getDeviceInfo:(void (^)(NSDictionary *deviceInfo,NSError *error))complete;

- (void)setTime:(NSDate *)date complete:(void (^)(NSError *error))complete;

- (void)getTime:(void (^)(YearParamInfo info,NSError *error))complete;

- (void)setSystemParam:(SystemParamInfo)info complete:(void (^)(NSError *error))complete;

- (void)getSystemParam:(void (^)(SystemParamInfo info,NSError *error))complete;

- (void)setPrintParam:(PrintParamInfo)paramInfo complete:(void (^)(NSError *error))complete;

- (void)getPrintParam:(void (^)(PrintParamInfo info,NSError *error))complete;

- (void)cleanPrint:(void (^)(NSError *error))complete;

- (void)setActiveWithKey1:(NSString *)key1 key2:(NSString *)key2 complete:(void (^)(NSError *error))complete;

-(void)getHardNum:(void (^)(NSError *error))complete;//获取设备序列好号并存储

//-(void)setActiveWithKey1:(NSString *)key1 key2:(NSString *)key2 complete:(void (^)(NSDictionary *response,NSError *error))complete;

@end
