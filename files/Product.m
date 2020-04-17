//
//  Product.m
//  PenMaJi
//
//  Created by Arvin on 2019/8/9.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import "Product.h"
#import "GCDAsyncSocket.h"
#import "PenMaJiProtocol.h"
#import "TcpCmd.h"
#import "PrinterItem.h"
#import "UIImage+CECategory.h"
#import "HBS_Tools.h"
#import "ServerApi.h"
#import <NetworkExtension/NetworkExtension.h>



NSErrorDomain const ProductErrorDomain = @"ProductErrorDomain";

NSNotificationName const ProductConnectStatusChangedNotice = @"ProductConnectStatusChangedNotice";
NSNotificationName const ProductReceiveDeviceInfoNotice = @"ProductReceiveDeviceInfoNotice";
NSNotificationName const ProductReceivePrintInfoNotice = @"ProductReceivePrintInfoNotice";
NSNotificationName const ProductBatteryStatus = @"ProductBatteryStatus";

ParamKey const YEAR = @"year";
ParamKey const MONTH = @"month";
ParamKey const DAY = @"day";
ParamKey const WEEKDAY = @"weekday";
ParamKey const HOUR = @"hour";
ParamKey const MINUTE = @"minute";
ParamKey const SECOND = @"second";
ParamKey const NAME = @"name";

ParamKey const PrtBeginDelay = @"PrtBeginDelay";
ParamKey const PrtColsDelay = @"PrtColsDelay";
ParamKey const PrtColsMotos = @"PrtColsMotos";
ParamKey const PrtPlusWidth = @"PrtPlusWidth";
ParamKey const PrtGrayScale = @"PrtGrayScale";
ParamKey const PrtGrayDelay = @"PrtGrayDelay";
ParamKey const Prtvoltage = @"Prtvoltage";
ParamKey const PrtRorL = @"PrtRorL";
ParamKey const Prtflie = @"Prtflie";
ParamKey const IdlePrt = @"IdlePrt";
ParamKey const PttRasterize = @"PttRasterize";
ParamKey const PrtperCrc = @"PrtperCrc";

ParamKey const ItemIndex = @"ItemIndex";
ParamKey const ItemType = @"ItemType";
ParamKey const ItemFont = @"ItemFont";
ParamKey const ItemSpace = @"ItemSpace";
ParamKey const ItemFormat = @"ItemFormat";
ParamKey const ItemText = @"ItemText";
ParamKey const ItemReverse = @"ItemReverse";
ParamKey const ItemRotate = @"ItemRotate";
ParamKey const ItemMirror = @"ItemMirror";
ParamKey const ItemBeginX = @"ItemBeginX";
ParamKey const ItemEndX = @"ItemEndX";
ParamKey const ItemBeginY = @"ItemBeginY";
ParamKey const ItemEndY = @"ItemEndY";
ParamKey const ItemLine = @"ItemLine";
ParamKey const ItemIsTest = @"ItemIsTest";

ParamKey const ItemTime = @"ItemTime";
ParamKey const ItemTimeFormat = @"ItemTimeFormat";

ParamKey const ItemSortNumber = @"ItemSortNumber";
ParamKey const ItemSortLength = @"ItemSortLength";
ParamKey const ItemSortOffset = @"ItemSortOffset";

ParamKey const ItemWeightPointLen = @"ItemWeightPointLen";
ParamKey const ItemWeightUnit = @"ItemWeightUnit";
ParamKey const ItemWeightPointValue = @"ItemWeightPointValue";
ParamKey const ItemWeightIntValue = @"ItemWeightIntValue";

ParamKey const ItemImage = @"ItemImage";
ParamKey const ItemImageWidth = @"ItemImageWidth";
ParamKey const ItemImageHeight = @"ItemImageHeight";

ParamKey const AddBattery = @"AddBattery";
ParamKey const BatteryStatus = @"BatteryStatus";
ParamKey const BatteryValue = @"BatteryValue";
ParamKey const DeviceActive = @"DeviceActive";
ParamKey const VersionBig = @"VersionBig";
ParamKey const VersionSmall = @"VersionSmall";
ParamKey const VersionX1 = @"VersionX1";
ParamKey const VersionX2 = @"VersionX2";
ParamKey const VersionIndex = @"VersionIndex";
ParamKey const VersionOTAMTU = @"VersionOTAMTU";
ParamKey const MaxGrayLevel = @"MaxGrayLevel";
ParamKey const PixelToPrtPoint = @"PixelToPrtPoint";
ParamKey const ColMaxPrtPoint = @"ColMaxPrtPoint";



ParamKey const TotalPackages = @"TotalPackages";
ParamKey const GrayLevel = @"GrayLevel";
ParamKey const GrayType = @"GrayType";
ParamKey const TotalBytes = @"TotalBytes";
ParamKey const FileCrc = @"FileCrc";
ParamKey const PackageIndex = @"PackageIndex";
ParamKey const PackageValidLen = @"PackageValidLen";
ParamKey const PackageCrc = @"PackageCrc";
ParamKey const PackageData = @"PackageData";

ParamKey const totalBytes = @"totalBytes";
ParamKey const otaMtu  = @"otaMtu";
ParamKey const mtuNum = @"mtuNum";
ParamKey const fileWriteSecIndex = @"ileWriteSecIndex";
ParamKey const prtDataCrc = @"prtDataCrc";



ParamKey const OTAMTU = @"OTAMTU";

ParamKey const ResultError = @"error";

@interface Product () <GCDAsyncSocketDelegate>
{
    dispatch_source_t overTimer;
        
    NSDictionary *deviceInfo;
    NSDictionary *printInfo;
    
    BOOL isWorking;
    
    int estimeSendTimes;
    int alreadSendTimes;
    int timerRunCount;//by cxq at 20191123: 计算定时器执行次数 打算2秒获取一次设备信息(包含充电状态和电量)
    int disconnectCount;
}

@property (nonatomic,strong) GCDAsyncSocket *socket;
@property (nonatomic,strong) PenMaJiProtocol *protocol;
@property (nonatomic,strong) NSString *ip;
@property (nonatomic,assign) uint16_t port;
@property (nonatomic,strong) NSMutableArray *sendCmdArray;

@end

@implementation Product

+ (instancetype)globalProduct{
    static id ins = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [self new];
    });
    return ins;
}

- (instancetype)init {
    
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(socketChange:) name:@"changeRotate" object:nil];
        _ip = @"192.168.1.1";
        _port = 9090;
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//        setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &val, sizeof(val);
        _protocol = [PenMaJiProtocol new];
        _sendCmdArray = [NSMutableArray array];
        overTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(overTimer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0.001 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(overTimer, ^{
            [self checkCmdIfOvertime];
            /* by cxq begin at 20191123 : 2秒获取一次设备信息 */
//           dh---1分钟查询一次
            self->timerRunCount++;
            if (self->timerRunCount % 60 == 0 && [self isConnected]) {
                [self getDeviceInfo:nil];
            }
            if (self->timerRunCount > 1000000) {
                self->timerRunCount = 0;
            }
            self->disconnectCount++;
            if ([self isConnected]) {
                self->disconnectCount = 0;
            }
            else {
                if (self->disconnectCount % 30 == 0) {
                    [self disconnect];
                    [self connect];
                }
            }
            /* by cxq end */
        });
        dispatch_resume(overTimer);
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        _connectedKey = [def objectForKey:@"DeviceKey"];
    }
    return self;
}
-(void)socketChange:(NSNotification*)noti{
    NSString *str = noti.object;
    if ([str isEqualToString:@"0"]) {
//        断开socket
        [self.socket disconnect];
    }else{
        [self connect];
    }
}
- (NSDictionary *)getDeviceInfo {
    return deviceInfo;
}

- (BOOL)isDisconnected {
    
    if (_socket.isDisconnected) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isConnected {
    
    if (_socket.isConnected) {
        return YES;
    }
    
    return NO;
}

- (BOOL)connect {
    
    if ([_socket isDisconnected]) {
         NSError *error = nil;
         BOOL ret = [_socket connectToHost:self.ip onPort:self.port withTimeout:10 error:&error];
        if (error) {
               NSLog(@"$connect error:$ %@",error);
               _status = 0;
               [[NSNotificationCenter defaultCenter] postNotificationName:ProductConnectStatusChangedNotice object:nil];
               if (self.connectStatusChanged) {
                   self.connectStatusChanged(0);
               }
               
           }
           else {
//               _status = 2;
//               [[NSNotificationCenter defaultCenter] postNotificationName:ProductConnectStatusChangedNotice object:nil];
//               if (self.connectStatusChanged) {
//                   self.connectStatusChanged(2);
//               }
               
           }
           
           return ret;
    }else{
        return NO;
    }
}

- (void)disconnect {
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:ProductConnectStatusChangedNotice object:nil];
//    if (self.connectStatusChanged) {
//        self.connectStatusChanged(0);
//    }
    if ([_socket isConnected]) {
          [_socket disconnect];
    }
  
    
}

- (void)sendCmd:(RequestCmd *)req {
    
    if (![self isConnected] || isWorking) {
        
        if (isWorking) {
            req.error = [NSError errorWithDomain:ProductErrorDomain code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"printerBusy", nil)}];
        }
        else {
            req.error = [NSError errorWithDomain:ProductErrorDomain code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"wifi_connect_failed", nil)}];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (req.response) {
                req.response(nil, req.error);
            }
        });        
        return;
    }
    
    [_sendCmdArray addObject:req];
    
    NSData *data = [_protocol constructDataWithCmd:req otherInfo:nil];

    if (data.length < 25) {
        
        NSMutableData *tmp = [NSMutableData dataWithData:data];
        uint8_t buff[10] = {0};
        [tmp appendBytes:buff length:10];
        
        data = tmp;
    }
    
    [_socket writeData:data withTimeout:-1 tag:0];
    
    if (data.length > 100) {
        NSLog(@"发送命令ID:%x 数据长度:%lu,\n%@",req.cmdId,(unsigned long)data.length,[data subdataWithRange:NSMakeRange(0, 32)]);
    }
    else {
        NSLog(@"发送命令ID:%x 数据:%@",req.cmdId,data);
    }
    
    
    req.sendDate = [NSDate date];
    req.cmdData = data;
    
    if (req.didSend) {
        req.didSend(self, data);
    }
}

- (void)sendCmdAgain:(RequestCmd *)req {
    
    if (![self isConnected] || isWorking) {
        
        if (isWorking) {
            req.error = [NSError errorWithDomain:ProductErrorDomain code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"printerBusy", nil)}];
        }
        else {
            req.error = [NSError errorWithDomain:ProductErrorDomain code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"wifi_connect_failed", nil)}];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (req.response) {
                req.response(nil, req.error);
            }
        });
        return;
    }
    
    [_socket writeData:req.cmdData withTimeout:-1 tag:0];
    
    NSLog(@"重发发送命令ID:%d",req.cmdId);
    
    req.sendDate = [NSDate date];
    
    req.alreadyRepeatTimes += 1;
}

- (void)receiveData:(NSData *)data {
    
//    [[DHReciveData sharManager]recveData:data];
   
    if (data.length) {
        NSArray *responseCmdArray = [_protocol receiveCmdWithData:data otherInfo:nil];
        
        for (ResponseCmd *res in responseCmdArray) {
            
          
            if (res.cmdId == REQ_workStatus) {
                isWorking = res.code;
            }
          
            if (res.cmdId == REQ_getDevice){
                
                NSDictionary *dict = res.result;
                int status = [dict[@"AddBattery"] intValue];
                if (status ==0) {
//                    dh--拔下充电线
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ProductBatteryStatus" object:@"NO"];
                }else{
//                    插上充电线
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ProductBatteryStatus" object:@"YES"];
                }
            }
                
            
            for (RequestCmd *req in _sendCmdArray) {
                
                if (req.cmdId == res.cmdId) {
                    
                    if (req.response) {
                        req.response(res, res.error);
                    }
                    
                    [_sendCmdArray removeObject:req];
                    break;
                }
            }
        }
    }
}

- (void)checkCmdIfOvertime {
    
//    NSLog(@"运行中...");
    
    NSDate *cur = [NSDate date];
    
    NSInteger index = 0;
    while (index < [_sendCmdArray count]) {
        
        RequestCmd *req = _sendCmdArray[index];
        
        if (req.sendDate && [cur timeIntervalSinceDate:req.sendDate] > 4) {
            
            if (req.alreadyRepeatTimes < req.maxRepeatTimes) {
                
                [self sendCmdAgain:req];
            }
            else {//发送超时
                req.error = [NSError errorWithDomain:ProductErrorDomain code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"error_datasendfail", nil)}];
                [_sendCmdArray removeObjectAtIndex:index];
                
                if (req.response) {
                    req.response(nil, req.error);
                }
                
                index--;
            }
        }
        
        index++;
    }
    
}


- (void)testParse {
    
    uint8_t buf[28] = {0xAA,0xFA,0x0C,0x00,0x02,0x0D,0x2F,0x0D,0x13,0x00,0x07,0x13,0xD4,0x3E,0xFA,0x0C,0x00,0x02,0x0D,0x2F,0x0D,0x13,0x00,0x07,0x13,0xD4,0x3E,0xAA};
    
    NSArray *resArray = [_protocol receiveCmdWithData:[NSData dataWithBytes:buf length:28] otherInfo:nil];
    
    NSInteger count = [resArray count];
}

+ (NSString *)upgradeFolder{
    
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *folder = [dir stringByAppendingPathComponent:@"Upgrade"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    
    return folder;
}
+ (NSString *)configJsonFolder{
    
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *folder = [dir stringByAppendingPathComponent:@"jsonConfig"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    
    return folder;
}
- (NSString *)getLocalNewestUpgradeFilePath {
    NSInteger latestVer = 15;
    NSArray *subfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[Product upgradeFolder] error:nil];
    
    NSString *filename = nil;
    int lastIndex = 0;

    for (NSString *name in subfiles) {
        
        if ([name isEqualToString:@"S1_TEST.bin"]) {
            return [[Product upgradeFolder] stringByAppendingPathComponent:name];
        }
        else {
            NSArray *com = [[name stringByReplacingOccurrencesOfString:@".bin" withString:@""] componentsSeparatedByString:@"_"];
            if ([com count] == 3) {
                if (lastIndex < [com[2] intValue]) {
                    lastIndex = [com[2] intValue];
                    filename = name;
                    latestVer = [com[2]integerValue];
                }
            }
        }
    }
    
    if (!filename || latestVer <= 15) {
        int type = [deviceInfo[@"VersionSmall"] intValue];
            if (type == 0) {
              return [[NSBundle mainBundle] pathForResource:@"1.0_2.7_18" ofType:@"bin"];
            }else if (type == 1){
              return [[NSBundle mainBundle] pathForResource:@"1.1_2.7_18" ofType:@"bin"];
            }
        
    }
    
    return [[Product upgradeFolder] stringByAppendingPathComponent:filename];
}
    
- (NSString *)getVersion {
    //dh----版本信息获取
    if (deviceInfo) {
        return [NSString stringWithFormat:@"v%@.%@",deviceInfo[VersionX1],deviceInfo[VersionX2]];
    }
    return @"Unknown";
}
    
- (BOOL)hasNewVersion {
    
    if (_DeviceType == 2) {
        return NO;
    }
    NSString *path = [self getLocalNewestUpgradeFilePath];
    NSString *name = [path lastPathComponent];
    int index = 0;
    NSString *oldVerStr;
    if ([name isEqualToString:@"1.0_2.7_18.bin"]) {
        index = 18;
        oldVerStr = @"2.7";
    }else if ([name isEqualToString:@"1.1_2.7_18.bin"]){
        index = 18;
        oldVerStr = @"2.7";
    }
    else if ([name isEqualToString:@"S1_TEST.bin"]) {
        return YES;
    }
    else {
        NSArray *com = [[name stringByReplacingOccurrencesOfString:@".bin" withString:@""] componentsSeparatedByString:@"_"];
        if ([com count] == 3) {
            index = [com[2] intValue];
            oldVerStr = com[1];
        }
    }
   
    if ([deviceInfo[VersionIndex] intValue] < index) {
        [dhServerApi saveStrWithKey:@"hardVersion" Value:[NSString stringWithFormat:@"%d",index]];
        [dhServerApi saveStrWithKey:@"hardVersion2" Value:[NSString stringWithFormat:@"%@",oldVerStr]];
    }else{
          [dhServerApi saveStrWithKey:@"hardVersion" Value:[NSString stringWithFormat:@"%d",[deviceInfo[VersionIndex] intValue]]];
          [dhServerApi saveStrWithKey:@"hardVersion2" Value:[NSString stringWithFormat:@"%@",oldVerStr]];
    }
    if (deviceInfo && [deviceInfo[VersionIndex] intValue] < index) {
//    dh---把最新版本的硬件存储，版本更新的时候展示
       
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isExsitConfig_line_1 {
    
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *folder = [dir stringByAppendingPathComponent:@"SEL_CONFIG"];
    
    NSString *path = [folder stringByAppendingPathComponent:@"config_line_1.config"];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)clear {
    deviceInfo = nil;
}

- (void)clearReq {
    
    for (RequestCmd *req in _sendCmdArray) {
        
        if (req.response) {
            req.response(nil, [NSError errorWithDomain:ProductErrorDomain code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"wifi_connect_failed", nil)}]);
        }
        req.response = nil;
    }
    
    [_sendCmdArray removeAllObjects];
}

- (int)getLine {
    
    if ([self isExsitConfig_line_1]) {
        return 1;
    }
    
    return 0;
}

- (int)battery {
    
    if (deviceInfo) {
        return [deviceInfo[BatteryValue] intValue];
    }
    
    return 0;
}

- (int)chargeStatus {
    
     if (deviceInfo) {
        return [deviceInfo[AddBattery] intValue];
    }
    
    return 0;
}

- (int)printGray {
//        dh---灰度改为3级
    if (!printInfo) {
        
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSInteger ret = [def integerForKey:@"PrintGrayScale"];
        if (ret > 0) {
            return (int)ret;
        }
        else {
            return 2;
        }
    }
    
    return [printInfo[PrtGrayScale] intValue];
}
- (int)printBox {
    if (!printInfo) {
          
          NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
          NSInteger ret = [def integerForKey:@"PrtColsDelay"];
          if (ret > 0) {
              return (int)ret;
          }
          else {
              return 0;
          }
      }
      
      return [printInfo[PrtColsDelay] intValue];
}
- (int)printMata {
    if (!printInfo) {
          
          NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
          NSInteger ret = [def integerForKey:@"PrtGrayDelay"];
          if (ret > 0) {
              return (int)ret;
          }
          else {
              return 0;
          }
      }
      
      return [printInfo[PrtGrayDelay] intValue];
}
- (void)savePrintGray:(int)grayScale {
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setInteger:grayScale forKey:@"PrintGrayScale"];
    [def synchronize];
}

- (void)saveConnectKey:(NSString *)key {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setObject:key forKey:@"DeviceKey"];
    [def synchronize];
}
#pragma mark - socket delegate
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
     NSLog(@"%ld 发送数据成功-----xdh",tag);
}
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"$ControlConnect$ didConnectToHost:%@ port:%d wifi:%@",host,port,[HBS_Tools ssid]);
    _status = 2;
    isWorking = NO;
    
    [self clearReq];
    
    NSString *ssid = [[dhServerApi GetSSID] uppercaseString];
    NSArray *arr = [ssid componentsSeparatedByString:@"_"];
    _connectedKey = [arr lastObject];
    
//    [ServerApi getServerApi].config.sn = _connectedKey;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ProductConnectStatusChangedNotice object:nil];
    if (self.connectStatusChanged) {
        self.connectStatusChanged(2);
    }
    [_socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
//    NSLog(@"didReadData-----xdh:%@",data);
    
    [_socket readDataWithTimeout:-1 tag:0];
    [self receiveData:data];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
//    NSLog(@"$ControlConnect$ socketDidDisconnect");
    
    _status = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:ProductConnectStatusChangedNotice object:nil];
    if (self.connectStatusChanged) {
        self.connectStatusChanged(0);
    }
    
    deviceInfo = nil;
    isWorking = NO;
    
    [self clearReq];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self connect];
    });
}

#pragma mark - function
- (NSInteger)maxColsByLevel:(int)level {
//    适配s1 和 s1+
      int height = PRT_H;
      int type1 = [deviceInfo[@"VersionBig"] intValue];
      int type2 = [deviceInfo[@"VersionSmall"] intValue];
      if (type1 == 1 && type2 == 1) {
        height = 308;
      }
    
    
    NSInteger maxBytes = MAX_SEND;
        
        if (level == 2) {
    
            return maxBytes/(height/8 + (height%8?1:0)) - 1;
        }
    
        return maxBytes/(height/2 + (height%2?1:0)) - 1;
}

- (int)bytesSizeByLevel:(int)level {
//    适配s1 和 s1+
           int height = PRT_H;
           int type1 = [deviceInfo[@"VersionBig"] intValue];
           int type2 = [deviceInfo[@"VersionSmall"] intValue];
           if (type1 == 1 && type2 == 1) {
             height = 308;
           }
    if (level == 2) {
           
           return (height/8 + (height%8?1:0));
       }
       
       return (height/2 + (height%2?1:0));
}

- (NSData *)fillBitmapAtFrame:(CGRect)frame item:(NSArray <PrinterItem *> *)items {
    
    NSMutableData *data = [NSMutableData dataWithLength:frame.size.width*frame.size.height];
    
    return data;
}
//dh---down
- (void)downloadOnePackage:(NSDictionary *)levelInfo fromX:(int)fromX index:(int)index progress:(void (^)(float p))progress complete:(void (^)(id ret,NSError *error))complete {
    
    NSDictionary *dataInfo = [levelInfo[@"DataArray"] objectAtIndex:index];
    int x = [dataInfo[@"x"] intValue];
    NSData *validData = dataInfo[@"data"];
   
    NSLog(@"分包数据长度:%d,fromX:%d toX:%d",validData.length,fromX,x);
    if (!validData.length) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:ProductErrorDomain code:-2 userInfo:@{NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"error_datasendfail", nil)}]);
        }
        return;
    }

    uint16_t crc = ModBusCRC16((uint8_t *)validData.bytes,(int)validData.length);
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_downloadFile;
    req.param = @{PackageIndex:@(index),PackageValidLen:@(validData.length),ItemBeginX:@(fromX),ItemEndX:@(x),ItemBeginY:@(0),ItemEndY:@(PRT_H-1),PackageData:validData,PackageCrc:@(crc)};
    req.response = ^(ResponseCmd *res, NSError *error) {
        
        if (error) {
            NSDictionary *dict = res.result;
            if (complete) {
                complete(nil,error);
            }
        }
        else {
            NSDictionary *dict = res.result;
            int full = [dict[@"1"] intValue];
            if (full == 255) {
//                当设备存储数据达到上限
                if (complete) {
                            complete(nil,nil);
                    }
                return ;
             
//                文件结束
//                RequestCmd *reqEnd = [RequestCmd new];
//                reqEnd.cmdId = REQ_downloadFileEnd;
//                reqEnd.response = complete;
//                [self sendCmd:reqEnd];
////                下载结束
//
//                RequestCmd *reqStop = [RequestCmd new];
//                reqStop.cmdId = REQ_stopDownload;
//                reqStop.response = ^(id ret, NSError *error) {
//
////                    if (complete) {
////                        complete(nil,error);
////                    }
//                };
                
            }
            if (index >= [levelInfo[@"DataArray"] count] - 1) {
                if (complete) {
                    complete(nil,nil);
                }
            }
            else {
                [self downloadOnePackage:levelInfo fromX:x+1 index:index+1 progress:progress complete:complete];
            }
        }
    };
    
    [self sendCmd:req];
    
    alreadSendTimes += 1;
    if (progress) {
        progress(alreadSendTimes*1.0/estimeSendTimes);
    }
}
//dh---down
- (void)downloadOneLevelArea:(NSDictionary *)levelInfo progress:(void (^)(float p))progress complete:(void (^)(id ret,NSError *error))complete {
    
    RequestCmd *reqBegin = [RequestCmd new];
    reqBegin.cmdId = REQ_downloadFileBegin;
    reqBegin.param = levelInfo;
    reqBegin.response = ^(id ret, NSError *error) {
        
        if (!error) {
            
            [self downloadOnePackage:levelInfo fromX:[levelInfo[ItemBeginX] intValue] index:0 progress:progress complete:^(id ret, NSError *error) {

                RequestCmd *reqEnd = [RequestCmd new];
                reqEnd.cmdId = REQ_downloadFileEnd;
                reqEnd.response = complete;
                [self sendCmd:reqEnd];
                
                alreadSendTimes += 1;
                if (progress) {
                    progress(alreadSendTimes*1.0/estimeSendTimes);
                }
            }];
        }
        else {
            if (complete) {
                complete(nil,error);
            }
        }
    };
    
    [self sendCmd:reqBegin];
    
    alreadSendTimes += 1;
    if (progress) {
        progress(alreadSendTimes*1.0/estimeSendTimes);
    }
}
//dh---down
- (void)downloadImages:(NSArray <NSDictionary *> *)levelAreas progress:(void (^)(float v))progress complete:(void (^)(id ret,NSError *error))complete {
    
    NSDictionary *info = levelAreas.firstObject;
    if (info) {
        
        [self downloadOneLevelArea:info progress:progress complete:^(id ret, NSError *error) {
           
            if (!error) {
                
                [self downloadImages:[levelAreas subarrayWithRange:NSMakeRange(1, levelAreas.count - 1)] progress:progress complete:complete];
            }
            else {
                if (complete) {
                    complete(nil,error);
                }
            }
        }];
    }
    else {
//  dh---down
        RequestCmd *reqStop = [RequestCmd new];
        reqStop.cmdId = REQ_stopDownload;
        reqStop.response = ^(id ret, NSError *error) {
            
            if (complete) {
                complete(nil,error);
            }
        };
        
        [self sendCmd:reqStop];
        
        alreadSendTimes += 1;
        if (progress) {
            progress(alreadSendTimes*1.0/estimeSendTimes);
        }
    }
}
//dh---down
- (void)printItems:(NSArray <PrinterItem *> *)items progress:(void (^)(float v))progress complete:(void (^)(id ret,NSError *error))complete {
        
    NSMutableArray *levelareas = [NSMutableArray arrayWithCapacity:1];

    estimeSendTimes = 0;
    alreadSendTimes = 0;
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_startDownload;
    req.param = @{ItemLine:@(0),ItemIsTest:@([self isExsitConfig_line_1])};
    
    req.response = ^(id ret, NSError *error) {
        
        if (!error) {
//            NSArray *arr = [NSArray arrayWithArray:levelareas];
            [self downloadImages:levelareas progress:progress complete:complete];
        }
        else {
            if (complete) {
                complete(ret,error);
            }
        }
    };
    
    [self sendCmd:req];
    
    CGRect contentFrame = [_delegate getContentFrame];
    
    int x_start = 0;
    int col_level = 0;
    int last_col_level = 0;
    
    int curType = 0;
    int lastType = 0;
    CGFloat rate = 2.4f / 3.3f;//压缩比例

    for (int i = (int)contentFrame.origin.x; i < CGRectGetMaxX(contentFrame); i++) {
        col_level = 0;
//        for (PrinterItem *item in items) {
//            if (i >= CGRectGetMinX(item.frame) && i <= CGRectGetMaxX(item.frame)) {
//                if (col_level < item.grayLevel) {
//                    col_level = item.grayLevel;
//                    if (item.type == PrintItemImage) {
//                        curType = 1;
//                    }
//                    else {
//                        curType = 0;
//                    }
//                }
//            }
//        }
        if (col_level == 0) {
            col_level = last_col_level;
            curType = lastType;
        }
        if (i == (int)CGRectGetMaxX(contentFrame) - 1 && col_level > 0) {
            last_col_level = col_level;
            lastType = curType;
            col_level = 0;
            i = (int)CGRectGetMaxX(contentFrame);
        }
        if (last_col_level != col_level) {
            if (last_col_level != 0) {
                int w = i - x_start;
                UIImage *image4 = nil;
                
                int type = [deviceInfo[@"VersionSmall"] intValue];
                CGFloat printHeight = [deviceInfo[@"ColMaxPrtPoint"] floatValue];//打印区域高度
                
                     if (_DeviceType == 1 || _DeviceType == 2) {
//                        S1+ / pen
                         UIImage *image = nil;
                         UIImage *image5 = nil;
                         if ([dhServerApi getIsIpad]) {
                            image = [_delegate getImageByFrame:CGRectMake(x_start, 0, w, PRT_H_ipad)];
                            image5 = [dhServerApi image:image byScalingToSize:CGSizeMake(w * printHeight /PRT_H_ipad * rate, printHeight)];
                         }else{
                             image  = [_delegate getImageByFrame:CGRectMake(x_start, 0, w, PRT_H)];
                             image5 = [dhServerApi image:image byScalingToSize:CGSizeMake(w* printHeight/PRT_H*rate, printHeight)];
                         }
                     
//                      CGFloat f1 = w*309/150.0f;
                     
                      UIImage *image2 = [dhServerApi image:image5 rotation:UIImageOrientationDown];//旋转
                      UIImage *image3 = [dhServerApi rotateWithImg:image2 rotaion:UIImageOrientationUpMirrored];//镜像
                      image4 = image3;
                     }else if(type == 0){
//                       S1
                         UIImage *image = nil;
                         if ([dhServerApi getIsIpad]) {
                             UIImage *image2 = [_delegate getImageByFrame:CGRectMake(x_start, 0, w, PRT_H_ipad)];
                             image = [dhServerApi image:image2 byScalingToSize:CGSizeMake(w * printHeight/PRT_H_ipad*rate, printHeight)];
                         }else{
                         UIImage *image8 = [_delegate getImageByFrame:CGRectMake(x_start, 0, w, printHeight)];
                         image = [dhServerApi image:image8 byScalingToSize:CGSizeMake(w * rate, printHeight)];
                         
                         }
                      image4 = image;
                     }
//                int c1 = last_col_level;
//                int c2 = x_start;
                  NSArray *dataArray = [self imageToBitData:image4 byLevel:last_col_level from:x_start];
                int totalbytes = 0;
                for (NSDictionary *dataInfo in dataArray) {
                    NSData *d = dataInfo[@"data"];
                    totalbytes += d.length;
                }

                NSDictionary *info = @{@"DataArray":dataArray,ItemLine:@(0),TotalPackages:@(dataArray.count),TotalBytes:@(totalbytes),ItemBeginX:@(x_start),ItemEndX:@(i-1),ItemBeginY:@(0),ItemEndY:@(PRT_H-1),GrayLevel:@(last_col_level),GrayType:@(lastType)};
                [levelareas addObject:info];
                
                estimeSendTimes += [dataArray count] + 2;
            }
            lastType = curType;
            last_col_level = col_level;
          
            x_start = i;
        }
    }
    estimeSendTimes += 2;
    alreadSendTimes += 1;
    if (progress) {
        progress(alreadSendTimes*1.0/estimeSendTimes);
    }
}

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )

- (NSArray <NSDictionary *> *)imageToBitData:(UIImage *)image byLevel:(uint8_t)level from:(int)from {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();//颜色通道
    CGImageRef imageRef = image.CGImage;//位图
    int width = (int)CGImageGetWidth(imageRef);//位图宽
    int height = (int)CGImageGetHeight(imageRef);//位图高
    
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, width*4, colorSpace, kCGBitmapByteOrder32Big|kCGImageAlphaPremultipliedLast);//生成上下午kCGBitmapByteOrder32Big kCGImageAlphaNone
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), imageRef);//绘制图片到上下文中
    
    uint32_t *buf = (uint32_t *)CGBitmapContextGetData(context);//(uint32_t *)malloc(width*height);
  
    NSMutableArray *dataArray = [NSMutableArray array];
    
    NSMutableData *grayData = [NSMutableData data];
    
    uint8_t colStart = 0x7A;
    uint8_t zeroLevel = 0;
    uint8_t grayType = level <= 2 ? 0 : 1;
    
    int col_len = [self bytesSizeByLevel:level];
    uint8_t *colsBuf = (uint8_t *)malloc(col_len);
    
    BOOL isZero = YES;
    uint32_t pixel = 0;
    uint8_t alpha = 0;
    
    for (int i = 0; i < width; i++) {
        memset(colsBuf, 0, col_len);
        isZero = YES;
        for (int j = 0; j < height; j++) {
            pixel = buf[i+(height-j-1)*width];
            alpha = A(pixel);
            pixel = (R(pixel)*38 + G(pixel)*75 + B(pixel)*15) >> 7;
            if (level <= 2) {
                if (alpha >= 128 && pixel < 128) {
                    colsBuf[j/8] |= 1 << (j % 8);
                }
            }
            else {
                pixel = pixel/16;
                if (alpha >= 128 && pixel < 6) {
                    colsBuf[j/2] |= pixel << (4*(j%2));
                }
            }
            if (alpha >= 128 && pixel < 128) {
                isZero = NO;
            }
        }
        if (isZero) {
            if (grayData.length + 3 > MAX_SEND) {
                [dataArray addObject:@{@"data":grayData,@"x":@(from+i)}];
                grayData = [NSMutableData data];
            }
            [grayData appendBytes:&colStart length:1];
            [grayData appendBytes:&grayType length:1];
            [grayData appendBytes:&zeroLevel length:1];
        }
        else {
            if (grayData.length + col_len + 3 > MAX_SEND) {
                [dataArray addObject:@{@"data":grayData,@"x":@(from+i)}];
                grayData = [NSMutableData data];
            }
            [grayData appendBytes:&colStart length:1];
            [grayData appendBytes:&grayType length:1];
            [grayData appendBytes:&level length:1];
            [grayData appendBytes:colsBuf length:col_len];
          
        }
    }
    
    [dataArray addObject:@{@"data":grayData,@"x":@(from+width-1)}];
    
    return dataArray;
}

- (void)startOTAUpgradeWithProgress:(void (^)(float v))progress complete:(void (^)(id ret,NSError *error))complete {
    
    NSString *path = [self getLocalNewestUpgradeFilePath];
    
    NSData *otaData = [NSData dataWithContentsOfFile:path];
    
    NSInteger otaLen = otaData.length;
    uint16_t per = 2048;
    uint16_t packagesNumber = otaData.length/per + (otaLen%per ? 1 : 0);
    uint32_t crc = 0;
    
    uint8_t *buf = (uint8_t *)[otaData bytes];
    int len = 0;

    while (len < otaLen) {
        
        if (otaLen - len < per) {
            
            int cur = (int)otaLen - len;
            crc += (int)ModBusCRC16(buf+len,cur);
            len += cur;
        }
        else {
            crc += (int)ModBusCRC16(buf+len,per);
            len += per;
        }
    }
    estimeSendTimes = packagesNumber + 2;
    
    uint16_t mtu = [deviceInfo[VersionOTAMTU] intValue];
    uint8_t x1 = [deviceInfo[VersionBig] intValue];
    uint8_t x2 = [deviceInfo[VersionSmall] intValue];
    uint16_t index = [deviceInfo[VersionIndex] intValue];
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_startOTAUpgrade;
    req.response = ^(ResponseCmd *res, NSError *err) {
        if (!err) {
            [self sendPackageWithComand:0 Data:otaData
                               maxLen:per
                                index:0
                             progress:progress
                             complete:^(ResponseCmd *res2, NSError *err2) {
                                 
                                 if (err2) {
                                     if (complete) {
                                         complete(res2.result,err2);
                                     }
                                 }
                                 else {
                                     RequestCmd *req1 = [RequestCmd new];
                                     req1.cmdId = REQ_stopOTAUpgrade;
                                     req1.response = ^(ResponseCmd *res1, NSError *err1) {
                                         
                                         if (!err1 && ![[path lastPathComponent] isEqualToString:@"S1_1.0_2.4_15.bin"]) {
//                                             [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                                         }
                                         
                                         if (!err1 && res1.code == 1) {
                                             RequestCmd *req3 = [RequestCmd new];
                                             req3.cmdId = REQ_restart;
                                             [self sendCmd:req3];
                                         }
                                         
                                         if (complete) {
                                             complete(res1.result,err1);
                                         }
                                     };
                                     [self sendCmd:req1];
                                     
                                     self->alreadSendTimes += 1;
                                     if (progress) {
                                         progress(self->alreadSendTimes*1.0/self->estimeSendTimes);
                                     }
                                 }
                             }];
        }
        else {
            if (complete) {
                complete(nil,err);
            }
        }
    };
    req.param = @{TotalBytes:@(otaLen),OTAMTU:@(mtu),TotalPackages:@(packagesNumber),FileCrc:@(crc),VersionBig:@(x1),VersionSmall:@(x2),VersionIndex:@(index)};
    [self sendCmd:req];
    
    alreadSendTimes = 1;
    if (progress) {
        progress(alreadSendTimes*1.0/estimeSendTimes);
    }
}
- (void)startPrtOTAUpgradeWithProgress:(void (^)(float v))progress complete:(void (^)(id ret,NSError *error))complete {
//    dh---prt文件S1_1.0_2.5_16
    
    NSString *path = nil;
    int type = [deviceInfo[@"VersionSmall"] intValue];
         if (type == 0) {
           path = [[NSBundle mainBundle] pathForResource:@"1.0_2.7_18.print" ofType:@"bin"];
         }else if(type == 1){
             path = [[NSBundle mainBundle] pathForResource:@"1.1_2.7_18.print" ofType:@"bin"];
         }
    NSData *otaData = [NSData dataWithContentsOfFile:path];
    NSInteger fileSize = otaData.length;
    uint16_t per = 2048;
    uint16_t secNum = otaData.length/per + (fileSize%per ? 1 : 0);
    uint32_t crc = 0;
    
    uint8_t *buf = (uint8_t *)[otaData bytes];
    int len = 0;

    while (len < fileSize) {
        
        if (fileSize - len < per) {
            
            int cur = (int)fileSize - len;
            crc += (int)ModBusCRC16(buf+len,cur);
            len += cur;
        }
        else {
            crc += (int)ModBusCRC16(buf+len,per);
            len += per;
        }
    }
    estimeSendTimes = secNum + 2;
    
    uint16_t mtu = [deviceInfo[VersionOTAMTU] intValue];
//    uint16_t index = [deviceInfo[VersionIndex] intValue];
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_PrtDataOtaBegin;
    req.response = ^(ResponseCmd *res, NSError *err) {
        if (!err) {
            [self sendPackageWithComand:1 Data:otaData maxLen:per index:0 progress:progress complete:^(id ret, NSError *error) {
                                            if (err) {
                                                     if (complete) {
                                                         complete(res.result,err);
                                                     }
                                                 }
                                                 else {
                                                     RequestCmd *req1 = [RequestCmd new];
                                                     req1.cmdId = REQ_PrtDataOtaEnd;
                                                     req1.response = ^(ResponseCmd *res1, NSError *err1) {
                                                         
                                                         if (!err1 && ![[path lastPathComponent] isEqualToString:@"S1_1.0_2.4_15.bin"]) {
                //                                             [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                                                         }
                                                         
                                                         if (!err1 && res1.code == 1) {
                                                             RequestCmd *req3 = [RequestCmd new];
                                                             req3.cmdId = REQ_restart;
                                                             [self sendCmd:req3];
                                                         }
                                                         
                                                         if (complete) {
                                                             complete(res1.result,err1);
                                                         }
                                                     };
                                                     [self sendCmd:req1];
                                                     
                                                     self->alreadSendTimes += 1;
                                                     if (progress) {
                                                         progress(self->alreadSendTimes*1.0/self->estimeSendTimes);
                                                     }
                                                 }
            }];

        }
        else {
            if (complete) {
                complete(nil,err);
//                [HBS_Tools showToast:err duration:10];
            }
        }
    };
    req.param = @{totalBytes:@(fileSize),otaMtu:@(mtu),mtuNum:@(secNum),prtDataCrc:@(crc)};
//    req.param = @{TotalBytes:@(otaLen),OTAMTU:@(mtu),TotalPackages:@(packagesNumber),FileCrc:@(crc),VersionBig:@(x1),VersionSmall:@(x2),VersionIndex:@(index)};
    [self sendCmd:req];
    
    alreadSendTimes = 1;
    if (progress) {
        progress(alreadSendTimes*1.0/estimeSendTimes);
    }
}

- (void)sendPackageWithComand:(int)type Data:(NSData *)packageData
                     maxLen:(NSInteger)packageMaxLen
                      index:(NSInteger)index
                   progress:(void (^)(float v))progress
                   complete:(void (^)(id ret,NSError *error))complete {
    if (packageData.length == 0) {
        if (complete) {
            complete(nil,nil);
        }
        return;
    }
    
    NSInteger package_len = packageMaxLen;
    if (packageData.length < packageMaxLen) {
        package_len = packageData.length;
    }
    NSData *pData = [packageData subdataWithRange:NSMakeRange(0, package_len)];
    
    uint16_t crc = ModBusCRC16((uint8_t *)[pData bytes], (int)package_len);
    
    RequestCmd *req = [RequestCmd new];
    if (type == 0) {
         req.cmdId = REQ_OTAUpgrade;
    }else if (type == 1){
         req.cmdId = REQ_PrtDataOtaSend;
    }
   
    req.response = ^(ResponseCmd *res, NSError *err) {
        if (!err) {
            
            NSData *subData = [packageData subdataWithRange:NSMakeRange(package_len, packageData.length-package_len)];

            [self sendPackageWithComand:type Data:subData maxLen:packageMaxLen index:index+1 progress:progress complete:complete];
        }
        else {
            if (complete) {
                complete(nil,err);
            }
        }
    };
    req.param = @{PackageIndex:@(index),PackageCrc:@(crc),PackageValidLen:@(package_len),PackageData:pData};
    
    [self sendCmd:req];
    
    alreadSendTimes += 1;
    if (progress) {
        progress(alreadSendTimes*1.0/estimeSendTimes);
    }
}

- (NSDictionary *)printInfoByPrint:(PrinterItem *)item {
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    
    param[ItemBeginX] = @(item.frame.origin.x);
    param[ItemBeginY] = @(item.frame.origin.y);
    param[ItemEndX] = @(CGRectGetMaxX(item.frame));
    param[ItemEndY] = @(CGRectGetMaxY(item.frame));
    param[ItemSpace] = @(item.space);
    param[ItemReverse] = @(item.reverse);
    param[ItemRotate] = @(item.rotate*90);
    param[ItemMirror] = @(item.mirror);
    param[ItemLine] = @(0);
    
    switch (item.type) {
        case PrintItemText:
        {
            param[ItemType] = @(DownloadText);
            PrinterWord *print = (PrinterWord *)item;
            param[ItemText] = [print text];
            param[ItemFont] = @([print font]);
        }
            break;
        case PrintItemTime:
        {
            param[ItemType] = @(DownloadTime);
            PrinterTime *print = (PrinterTime *)item;
            param[ItemFont] = @([print font]);
            param[ItemTime] = print.time;
            
            NSString *tmp_format = print.format;
            
            if ([[print.format lowercaseString] hasPrefix:@"yy"]) {
                tmp_format = [tmp_format stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@"20"];
            }
            
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@":MM:" withString:@":Ii:"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@":mm:" withString:@":Ii:"];
            
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"yy" withString:@"Yy"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"YY" withString:@"Yy"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"MM" withString:@"Mm"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"mm" withString:@"Mm"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"DD" withString:@"Dd"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"dd" withString:@"Dd"];
            
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"HH" withString:@"Hh"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"hh" withString:@"Hh"];
            
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"SS" withString:@"Ss"];
            tmp_format = [tmp_format stringByReplacingOccurrencesOfString:@"ss" withString:@"Ss"];
            
             param[ItemTimeFormat] = tmp_format;
        }
            break;
        case PrintItemSort:
        {
            param[ItemType] = @(DownloadSortNum);
            PrinterSort *print = (PrinterSort *)item;
            param[ItemFont] = @([print font]);
            param[ItemSortNumber] = @(print.sort);
            param[ItemSortLength] = @(print.length);
            param[ItemSortOffset] = @(print.offset);
        }
            break;
        case PrintItemWeight:
        {
            param[ItemType] = @(DownloadWeight);
            PrinterWeight *print = (PrinterWeight *)item;
            param[ItemFont] = @([print font]);
            param[ItemWeightUnit] = @(print.unit);
            param[ItemWeightPointLen] = @([print pointLen]);
            param[ItemWeightPointValue] = @([print pointValue]);
            param[ItemWeightIntValue] = @([print weightIntValue]);
        }
            break;
        case PrintItemImage:
        {
//            PrinterImage *print = (PrinterImage *)item;
            param[ItemReverse] = @(0);
            param[ItemRotate] = @(0);
        }
            break;
        case PrinterItemQrcode:
        {
            param[ItemType] = @(DownloadQrCode);
            PrinterImage *print = (PrinterImage *)item;
            param[ItemImage] = [[print asImage] imageWithMirror:0];
            param[ItemImageWidth] = @(print.frame.size.width);
            param[ItemImageHeight] = @(print.frame.size.height);
            param[ItemReverse] = @(0);
            param[ItemRotate] = @(0);
        }
            break;
        case PrinterItemLineCode:
        {
            param[ItemType] = @(DownloadBarcode);
            PrinterImage *print = (PrinterImage *)item;
            param[ItemImage] = [[print asImage] imageWithMirror:0];
            param[ItemImageWidth] = @(print.frame.size.width);
            param[ItemImageHeight] = @(print.frame.size.height);
            param[ItemReverse] = @(0);
            param[ItemRotate] = @(0);
        }
            break;
        default:
            break;
    }
    
    return param;
}

- (void)getDeviceInfo:(void (^)(NSDictionary *deviceInfo,NSError *error))complete {
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_getDevice;
    req.response = ^(ResponseCmd *res, NSError *error) {
        
        if (!error) {
            self->deviceInfo = res.result;
            //S1+
//            VersionSmall
             int verBig = [self->deviceInfo[@"VersionBig"] intValue];
             int verSmall = [self->deviceInfo[@"VersionSmall"] intValue];
            [dhServerApi saveStrWithKey:@"dhVerBig" Value:[NSString stringWithFormat:@"%d",verBig]];
            [dhServerApi saveStrWithKey:@"dhVerSmall" Value:[NSString stringWithFormat:@"%d",verSmall]];
             if (verBig == 1 && verSmall == 0) {
                 self->_DeviceType = 0;//s1
             }else if (verBig == 1 && verSmall == 1){
                  self->_DeviceType = 1;//s1+
             }else if (verBig == 1 && verSmall == 2){
                 self->_DeviceType = 2;//pen
             }
             else{
             }
            

            [[NSNotificationCenter defaultCenter] postNotificationName:ProductReceiveDeviceInfoNotice object:nil];
            //           dhGetDeviceInfo
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dhGetDeviceInfo" object:res.result];
        }
        
        if (complete) {
            complete(res.result,error);
        }
    };
    
    [self sendCmd:req];
}

- (void)setTime:(NSDate *)date complete:(void (^)(NSError *error))complete {
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_setTime;
    req.response = ^(ResponseCmd *res, NSError *error) {
        if (complete) {
            complete(error);
        }
    };
    
    NSDateComponents *com = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] componentsInTimeZone:[NSTimeZone systemTimeZone] fromDate:date];
    
    req.param = @{YEAR:@(com.year%100),MONTH:@(com.month),DAY:@(com.day),HOUR:@(com.hour),MINUTE:@(com.minute),SECOND:@(com.second),WEEKDAY:@(com.weekday)};
    
    [self sendCmd:req];
}

- (void)getTime:(void (^)(YearParamInfo info,NSError *error))complete {
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_getTime;
    req.response = ^(ResponseCmd *cmd, NSError *error) {
        if (complete) {
            complete(cmd.result,error);
        }
    };
    
    [self sendCmd:req];
}

- (void)setSystemParam:(SystemParamInfo)info complete:(void (^)(NSError *error))complete {
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_setSystemParam;
    req.response = ^(ResponseCmd *res, NSError *error) {
        if (complete) {
            complete(error);
        }
    };
    req.param = info;
    
    [self sendCmd:req];
}

- (void)getSystemParam:(void (^)(SystemParamInfo info,NSError *error))complete {
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_getSystemParam;
    req.response = ^(ResponseCmd *cmd, NSError *error) {
        if (complete) {
            complete(cmd.result,error);
        }
    };
    
    [self sendCmd:req];
}

/* by cxq begin at 20191123:发送结束下载单个命令 **/
- (void)stopDowloadComplete:(void (^)(NSError *error))complete {
    
    RequestCmd *reqStop = [RequestCmd new];
    reqStop.cmdId = REQ_stopDownload;
    reqStop.response = ^(id ret, NSError *error) {
        
        if (complete) {
            complete(error);
        }
    };
    
    [self sendCmd:reqStop];
}
/* by cxq end  **/
- (void)setPrintGrayBoxMata:(int)grayScale Box:(int)PrtColsDelay mata:(int)PrtGrayDelay complete:(void (^)(NSError *error))complete {
    
        int verBig = [deviceInfo[@"VersionBig"] intValue];
        int verSmall = [deviceInfo[@"VersionSmall"] intValue];
        NSString *versionStr = [NSString stringWithFormat:@"%d.%d",verBig,verSmall];
        
        NSDictionary *configDict = [dhServerApi readInterfaceValue];
        NSArray *arr1 = [configDict valueForKey:versionStr];//版本
        NSArray *arr2 = [arr1 objectAtIndex:grayScale];//灰度
        NSArray *arr3 = [arr2 objectAtIndex:PrtColsDelay];//墨水颜色
        NSDictionary *dict2 = [arr3 objectAtIndex:PrtGrayDelay];//界面材质
       
        NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:dict2];
    
        [mutDict setValue:@(PrtGrayDelay) forKey:@"PrtGrayDelay"];
        [mutDict setValue:@(PrtColsDelay) forKey:@"PrtColsDelay"];
        
        
        [self setPrintParam:mutDict complete:^(NSError *error) {
         if (!error) {
            self->printInfo = mutDict;
                     }
        if (complete) {
                complete(error);
            }
        }];
    
//    if (printInfo) {
//
//        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:printInfo];
//        [dic setValue:@(grayScale) forKey:@"PrtGrayScale"];
//        [dic setValue:@(PrtColsDelay) forKey:@"PrtColsDelay"];
//        [dic setValue:@(PrtGrayDelay) forKey:@"PrtGrayDelay"];
//        [self setPrintParam:dic complete:^(NSError *error) {
//            if (!error) {
//                self->printInfo = dic;
//            }
//            if (complete) {
//                complete(error);
//            }
//        }];
//    }
//    else {
//        [self getPrintParam:^(PrintParamInfo info, NSError *error) {
//
//            if (!error) {
//                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self->printInfo];
//                  [dic setValue:@(grayScale) forKey:@"PrtGrayScale"];
//                  [dic setValue:@(PrtColsDelay) forKey:@"PrtColsDelay"];
//                  [dic setValue:@(PrtGrayDelay) forKey:@"PrtGrayDelay"];
//                [self setPrintParam:dic complete:complete];
//            }
//            else {
//                if (complete) {
//                    complete(error);
//                }
//            }
//        }];
//    }
}

- (void)setPrintGray:(int)grayScale complete:(void (^)(NSError *error))complete {
    
    int verBig = [deviceInfo[@"VersionBig"] intValue];
    int verSmall = [deviceInfo[@"VersionSmall"] intValue];
    NSString *versionStr = [NSString stringWithFormat:@"%d.%d",verBig,verSmall];
    
    NSInteger PrtGrayScale = grayScale;
    NSInteger PrtGrayDelay = 0;
    NSInteger PrtColsDelay = 0;
    
//    NSString *PrtGrayScaleStr = [dhServerApi getStrWithKey:@"dhPrtGrayScale"];//灰度
    NSString *PrtGrayDelayStr = [dhServerApi getStrWithKey:@"dhPrtGrayDelay"];//界面材质
    NSString *PrtColsDelayStr = [dhServerApi getStrWithKey:@"dhPrtColsDelay"];//墨水颜色
    
//    if (PrtGrayScaleStr != nil) {
//        PrtGrayScale = [PrtGrayScaleStr integerValue];
//    }
    if (PrtGrayDelayStr != nil) {
        PrtGrayDelay = [PrtGrayDelayStr integerValue];
    }
    if (PrtColsDelayStr != nil) {
        PrtColsDelay = [PrtColsDelayStr integerValue];
    }
    
   
    NSDictionary *configDict = [dhServerApi readInterfaceValue];
    NSArray *arr1 = [configDict valueForKey:versionStr];//版本
    NSArray *arr2 = [arr1 objectAtIndex:PrtGrayScale];//灰度
    NSArray *arr3 = [arr2 objectAtIndex:PrtColsDelay];//墨水颜色
    NSDictionary *dict2 = [arr3 objectAtIndex:PrtGrayDelay];//界面材质
   
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:dict2];
    [mutDict setValue:@(PrtGrayDelay) forKey:@"PrtGrayDelay"];
    [mutDict setValue:@(PrtColsDelay) forKey:@"PrtColsDelay"];
    
    
    [self setPrintParam:mutDict complete:^(NSError *error) {
     if (!error) {
        self->printInfo = mutDict;
                 }
    if (complete) {
            complete(error);
        }
    }];
    
   
    
    
    
    
    
    
//    if (printInfo) {
//
//        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:printInfo];
//
//
//        [dic setValue:@(grayScale) forKey:PrtGrayScale];
//        [dic setValue:@(PrtGrayDelay) forKey:@"PrtGrayDelay"];
//        [dic setValue:@(PrtColsDelay) forKey:@"PrtColsDelay"];
////         printParam[Prtvoltage] = @(0);//S1/P1 0  S1+ 1
//        if(_DeviceType == 1){
//            [dic setValue:@(1) forKey:Prtvoltage];//S1+
//        }else if (_DeviceType == 0){
//             [dic setValue:@(0) forKey:Prtvoltage];//S1 P1
//        }
//
//        [self setPrintParam:dic complete:^(NSError *error) {
//            if (!error) {
//                self->printInfo = dic;
//            }
//            if (complete) {
//                complete(error);
//            }
//        }];
//    }
//    else {
//        [self getPrintParam:^(PrintParamInfo info, NSError *error) {
//
//            if (!error) {
//                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self->printInfo];
//
//                [dic setValue:@(grayScale) forKey:PrtGrayScale];
//                [dic setValue:@(PrtGrayDelay) forKey:@"PrtGrayDelay"];
//                [dic setValue:@(PrtColsDelay) forKey:@"PrtColsDelay"];
//                if(self->_DeviceType == 1){
//                    [dic setValue:@(1) forKey:Prtvoltage];
//                }else if (self->_DeviceType == 0){
//                     [dic setValue:@(0) forKey:Prtvoltage];
//                }
//
//                [self setPrintParam:dic complete:complete];
//            }
//            else {
//                if (complete) {
//                    complete(error);
//                }
//            }
//        }];
//    }
    
}
- (void)setPrintBoxType:(int)Box complete:(void (^)(NSError *error))complete{
//    if (printInfo) {
//
//        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:printInfo];
//        dic[PrtColsDelay] = @(Box);
//
//        [self setPrintParam:dic complete:^(NSError *error) {
//            if (!error) {
//                self->printInfo = dic;
//            }
//            if (complete) {
//                complete(error);
//            }
//        }];
//    }
//    else {
//        [self getPrintParam:^(PrintParamInfo info, NSError *error) {
//
//            if (!error) {
//                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self->printInfo];
//                dic[PrtColsDelay] = @(Box);
//
//                [self setPrintParam:dic complete:complete];
//            }
//            else {
//                if (complete) {
//                    complete(error);
//                }
//            }
//        }];
//    }
}
- (void)setPrintmateralType:(int)materal complete:(void (^)(NSError *error))complete{
//    if (printInfo) {
//        
//        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:printInfo];
//        dic[PrtGrayDelay] = @(materal);
//        
//        [self setPrintParam:dic complete:^(NSError *error) {
//            if (!error) {
//                self->printInfo = dic;
//            }
//            if (complete) {
//                complete(error);
//            }
//        }];
//    }
//    else {
//        [self getPrintParam:^(PrintParamInfo info, NSError *error) {
//            
//            if (!error) {
//                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self->printInfo];
//                dic[PrtGrayDelay] = @(materal);
//                
//                [self setPrintParam:dic complete:complete];
//            }
//            else {
//                if (complete) {
//                    complete(error);
//                }
//            }
//        }];
//    }
}
- (void)setPrintParam:(PrintParamInfo)paramInfo complete:(void (^)(NSError *error))complete {
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_setPrintParam;
    req.response = ^(ResponseCmd *res, NSError *error) {
        if (complete) {
            complete(error);
        }
    };
    req.param = paramInfo;
    
    [self sendCmd:req];
}

- (void)getPrintParam:(void (^)(PrintParamInfo info,NSError *error))complete {
    
        int verBig = [deviceInfo[@"VersionBig"] intValue];
        int verSmall = [deviceInfo[@"VersionSmall"] intValue];
        NSString *versionStr = [NSString stringWithFormat:@"%d.%d",verBig,verSmall];
        
        NSInteger PrtGrayScale = 1;
        NSInteger PrtGrayDelay = 0;
        NSInteger PrtColsDelay = 0;
        
        NSString *PrtGrayScaleStr = [dhServerApi getStrWithKey:@"dhPrtGrayScale"];//灰度
        NSString *PrtGrayDelayStr = [dhServerApi getStrWithKey:@"dhPrtGrayDelay"];//界面材质
        NSString *PrtColsDelayStr = [dhServerApi getStrWithKey:@"dhPrtColsDelay"];//墨水颜色
        
        if (PrtGrayScaleStr != nil) {
            PrtGrayScale = [PrtGrayScaleStr integerValue];
        }
        if (PrtGrayDelayStr != nil) {
            PrtGrayDelay = [PrtGrayDelayStr integerValue];
        }
        if (PrtColsDelayStr != nil) {
            PrtColsDelay = [PrtColsDelayStr integerValue];
        }
        
       
        NSDictionary *configDict = [dhServerApi readInterfaceValue];
        NSArray *arr1 = [configDict valueForKey:versionStr];//版本
        NSArray *arr2 = [arr1 objectAtIndex:PrtGrayScale];//灰度
        NSArray *arr3 = [arr2 objectAtIndex:PrtColsDelay];//墨水颜色
        NSDictionary *dict2 = [arr3 objectAtIndex:PrtGrayDelay];//界面材质
       
        NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:dict2];
        [mutDict setValue:@(PrtGrayDelay) forKey:@"PrtGrayDelay"];
        [mutDict setValue:@(PrtColsDelay) forKey:@"PrtColsDelay"];
        [mutDict setValue:@(PrtGrayScale) forKey:@"PrtGrayScale"];
        
        if (complete) {
            complete(mutDict,nil);
        }
    
    
//    RequestCmd *req = [RequestCmd new];
//    req.cmdId = REQ_getPrintParam;
//    req.response = ^(ResponseCmd *cmd, NSError *error) {
//
//        if (!error) {
//            self->printInfo = cmd.result;
//            [[NSNotificationCenter defaultCenter] postNotificationName:ProductReceivePrintInfoNotice object:nil];
//        }
//
//        if (complete) {
//            complete(cmd.result,error);
//        }
//    };
//
//    [self sendCmd:req];
}

- (void)cleanPrint:(void (^)(NSError *error))complete {
    
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_cleanPrint;
    req.response = ^(ResponseCmd *res, NSError *error) {
        if (complete) {
            complete(error);
        }
    };
    [self sendCmd:req];
}
- (void)setActiveWithKey1:(NSString *)key1 key2:(NSString *)key2 complete:(void (^)(NSError *error))complete {
    
    NSString *str = [NSString stringWithFormat:@"%@%@",key1,key2];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    RequestCmd *req = [RequestCmd new];
    req.cmdId = REQ_setActive;
    req.response = ^(ResponseCmd *res, NSError *error) {

        if (complete) {
            complete(error);
        }
    };
    req.param = @{PackageData:data};

    [self sendCmd:req];
}
-(void)getHardNum:(void (^)(NSError *error))complete{
//    fa 05 00 30 aa aa
     RequestCmd *req = [RequestCmd new];
     req.cmdId = REQ_getHardNum;
     req.response = ^(ResponseCmd *res, NSError *error) {
         if (!error) {
//            dh---将序列号缓存
             NSDictionary *dict = res.result;
             NSString *str = dict[@"WIFIName"];
             [dhServerApi saveStrWithKey:@"dhwifiName" Value:str];
             NSLog(@"resut--------");
         }
         if (complete) {
             complete(error);
         }
     };
     [self sendCmd:req];
}

#pragma mark - 搜索wifi列表
+ (void)searchWifiList:(void (^)(NSString *wifi))handle  {
    
    if (@available(iOS 9.0,*)) {
        
        NSMutableDictionary* options = [[NSMutableDictionary alloc] init];
        [options setObject:@"" forKey:kNEHotspotHelperOptionDisplayName];
        dispatch_queue_t queue = dispatch_queue_create("com.myapp.ex", NULL);
        //注册成功会返回一个Yes值，否则No
        BOOL returnType = [NEHotspotHelper registerWithOptions:options queue:queue handler: ^(NEHotspotHelperCommand * cmd) {
            NEHotspotNetwork* network;
            if (cmd.commandType == kNEHotspotHelperCommandTypeEvaluate || cmd.commandType ==kNEHotspotHelperCommandTypeFilterScanList) {
                for (network  in cmd.networkList) {
                    NSLog(@"COMMAND TYPE After:   %ld", (long)cmd.commandType);
                    NSLog(@"SSID-> %@ Mac地址-> %@ 信号强度-> %f",network.SSID,network.BSSID,network.signalStrength);
                    if ([network.SSID isEqualToString:@"免费WiFi"]) {
                        double signalStrength = network.signalStrength;
                        NSLog(@"Signal Strength: %f", signalStrength);
                        [network setConfidence:kNEHotspotHelperConfidenceHigh];
                        [network setPassword:@"xxxxxxx"];
                        NEHotspotHelperResponse *response = [cmd createResponse:kNEHotspotHelperResultSuccess];
                        NSLog(@"Response CMD %@", response);
                        [response setNetworkList:@[network]];
                        [response setNetwork:network];
                        [response deliver];
                    }
                }
            }
        }];
        
        NSLog(@"returnType=%d",returnType);
    }
}

@end
