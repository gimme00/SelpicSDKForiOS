//
//  PenMaJiProtocol.m
//  PenMaJi
//
//  Created by Arvin on 2019/8/9.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import "PenMaJiProtocol.h"
#import <UIKit/UIKit.h>
#import "TcpCmd.h"
#import "ProductDefine.h"

//系统参说明
typedef struct
{
    unsigned short int DevId;            //设备的通信ID 取值0x0001—0xffff;默认为0x0001
    unsigned short int HeartbeatTime;     //心跳时间      多长时间设备主动上传一次数单位s
    unsigned short int Mode;            //通信模式 =1，wifi为AP模式，TCP为服务器，=3，wifi为设备端，TCP为客户端
    unsigned char      IP1[4];     //wifi IP地址    //TCP服务器IP，mode=1时为设备IP
    unsigned short int Port1;              //TCP通信的端口
    unsigned short int WiFiApNameLen;           //WIFIAP名字长度，mode=3有效。
    unsigned short int WiFiApPassWordLen;        //WIFIAP密码长度    mode=3有效。
    unsigned char WiFiApName[20];              //WIFIAP名字，mode=3有效。
    unsigned char WiFiApPassWord[20];           //WIFIAP名字，mode=3有效。
    // mode=1时，AP名字固定为Prt_xxxxxxx,密码：12345678
}SystemParam;

//打印参数说明：
typedef struct
{
    unsigned short int  PrtBeginDelay;        //开始打印延时，按下打印键后多久才开始打。
    unsigned short int  PrtColsDelay;      //列和列间的时间间隔.编码器无效时可以此参数
    unsigned short int  PrtColsMotos;    //列和列计多个编码器计数。
    unsigned short int  PrtPlusWidth;       //打印脉冲宽度
    unsigned short int  PrtGrayScale;       //打印灰度
    unsigned short int  PrtGrayDelay;
    unsigned short int  Prtvoltage;         //打印电压
    unsigned short int  PrtRorL;           //左右喷头选择
    unsigned short int  Prtflie;            //打印文件选择,<4打印对应的文件，=4:1->2文件轮流打，=5：1->2->3轮流打印。
    unsigned short int  IdlePrt;             //闲喷,高字节表示空闲时间多久开始闲喷，低字节表示，喷多少列。避免长时间不用喷头堵住。
}PrintParam;

uint16_t ModBusCRC16(uint8_t *cmd, int len)
{
    uint16_t i, j, tmp, CRC16;
    
    CRC16 = 0xFFFF;             //CRC寄存器初始值
    for (i = 0; i < len; i++)
    {
        CRC16 ^= cmd[i];
        for (j = 0; j < 8; j++)
        {
            tmp = (ushort)(CRC16 & 0x0001);
            CRC16 >>= 1;
            if (tmp == 1)
            {
                CRC16 ^= 0xA001;    //异或多项式
            }
        }
    }
    
    return CRC16;
//    
//    cmd[i++] = (uint8_t) (CRC16 & 0x00FF);
//    cmd[i++] = (uint8_t) ((CRC16 & 0xFF00)>>8);
}

enum {
    step_start = 0,
    step_len = 1,
    step_id = 2,
    step_data = 3,
    step_crc = 4
};

@implementation PenMaJiProtocol
{
    NSMutableData *remainData;
}

- (instancetype)init {
    
    if (self = [super init]) {
        remainData = [NSMutableData data];
    }
    return self;
}

- (NSData *)constructDataWithCmd:(RequestCmd *)reqCmd otherInfo:(id)info {
    
    NSData *bodyData = [self generateDataByCmd:reqCmd];
    
    uint16_t len = bodyData.length;
    uint8_t *buf = malloc(1 + 2 + 1 + len + 2);
    
    *(buf + 0) = reqCmd.start;
    uint16_t tmp_len = len + 5;
    memcpy(buf + 1, &tmp_len, 2);
//    *(buf + 1) = len + 5;
    *(buf + 3) = reqCmd.cmdId;
    memcpy(buf + 4, [bodyData bytes], len);
    
    uint16_t crc = ModBusCRC16(buf, len+4);
    memcpy(buf+len+4, &crc, 2);
    
    NSData *data = [NSData dataWithBytes:buf length:len+6];
    free(buf);
    
    return data;
}

- (NSArray <ResponseCmd *> *)receiveCmdWithData:(NSData *)data otherInfo:(id)info {
    
    NSMutableArray *resArray = [NSMutableArray array];
    [remainData setLength:0];
    [remainData appendData:data];
    
    while (1) {
        
        int len = 0;
        ResponseCmd *res = [self parseData:&len];
        
        if (len) {
            [remainData replaceBytesInRange:NSMakeRange(0, len) withBytes:NULL length:0];
        }
        
        if (res) {
            [resArray addObject:res];
        }
        else {
            break;
        }
    }
    
    return resArray;
}

- (ResponseCmd *)parseData:(int *)parse_len {
    
    ResponseCmd *res = nil;
    
    uint8_t *buf = (uint8_t *)[remainData bytes];
  
    int index = 0;
    int start = 0;
    
    int len = 0;
    uint8_t cmdId = 0;
    
    int status = step_start;
    
    BOOL enoughData = YES;
    
    while (enoughData) {@autoreleasepool{
        
        switch (status) {
            case step_start:
            {
                start = index;
                
                if (buf[index++] == 0xFA) {
                    status = step_len;
                    *parse_len = index-1;
                }
                else {
                    *parse_len = index;
                }
            }
                break;
            case step_len:
            {
                if (index + 1 < remainData.length) {
                    len = buf[index] + (buf[index+1] << 8);
                    
                    if (len < 5) {
                        status = step_start;
                        index++;
                    }
                    else {
                        status = step_id;
                        index += 2;
                    }
                }
                else {
                    enoughData = NO;
                }
            }
                break;
            case step_id:
            {
                cmdId = buf[index++];
                
                if (len <= 5) {
                    status = step_crc;
                }
                else {
                    status = step_data;
                }
            }
                break;
            case step_data:
            {
                index += len - 5;
                
                status = step_crc;
            }
                break;
            case step_crc:
            {
                *parse_len = index;
                res = [self generateResCmdByData:[NSData dataWithBytes:buf+start+4 length:len-5] cmdId:cmdId];
                enoughData = NO;
                
//                if (index + 1 < remainData.length) {
//
//                    uint16_t crc = buf[index] + (buf[index+1] << 8);
//                    uint16_t f_crc = ModBusCRC16(buf+start, len-5+4);
//                    if (crc == f_crc) {
//                        index += 2;
//                        *parse_len = index;
//
//                        res = [ResponseCmd new];
//                        res.cmdId = cmdId;
//                        res.result = [self parseInfoByData:[NSData dataWithBytes:buf+start length:len-5+4] cmdId:cmdId];
//
//                        enoughData = NO;
//                    }
//                    else {
//                        status = step_start;
//                        index = start + 1;
//                        *parse_len = index;
//                    }
//                }
//                else {
//                    enoughData = NO;
//                }
            }
                break;
            default:
                break;
        }
        
        if (index >= remainData.length) {
            enoughData = NO;
        }
    }}
    
    return res;
}

- (NSData *)generateDataByCmd:(RequestCmd *)req {
    
    NSDictionary *param = req.param;
    
    NSLog(@"请求参数:%@",req.param);
    
    switch (req.cmdId) {
        case REQ_setTime:
        {
            uint8_t buf[7] = {0};
            buf[0] = [param[SECOND] intValue];
            buf[1] = [param[MINUTE] intValue];
            buf[2] = [param[HOUR] intValue];
            buf[3] = [param[DAY] intValue];
            buf[4] = [param[WEEKDAY] intValue];
            buf[5] = [param[MONTH] intValue];
            buf[6] = [param[YEAR] intValue];
            
            return [NSData dataWithBytes:buf length:7];
        }
            break;
        case REQ_setPrintParam:
        {
            uint16_t buf[11] = {0};
            buf[0] = [param[PrtBeginDelay] unsignedShortValue];
            buf[1] = [param[PrtColsDelay] unsignedShortValue];
            buf[2] = [param[PrtColsMotos] unsignedShortValue];
            buf[3] = [param[PrtPlusWidth] unsignedShortValue];
            buf[4] = [param[PrtGrayScale] unsignedShortValue];
            buf[5] = [param[PrtGrayDelay] unsignedShortValue];
            buf[6] = [param[Prtvoltage] unsignedShortValue];
            buf[7] = [param[PrtRorL] unsignedShortValue];
            buf[8] = [param[IdlePrt] unsignedShortValue];
            buf[9] = [param[PttRasterize] unsignedShortValue];
            buf[10] = [param[PrtperCrc] unsignedShortValue];
            
            return [NSData dataWithBytes:buf length:22];
        }
            break;
        case REQ_startDownload:
        {
            uint16_t line = [param[ItemLine] intValue];
            uint8_t isTest = [param[ItemIsTest] intValue];
            
            NSMutableData *content = [NSMutableData data];
            [content appendBytes:&line length:2];
            [content appendBytes:&isTest length:1];
            return content;
        }
            break;
        case REQ_downloadTime:
        {
            uint16_t timeIndex = [param[ItemLine] intValue];
            NSData *timeFormat = [self dataWithString:param[ItemTimeFormat]];
            uint16_t timeLen = timeFormat.length;
            uint16_t timeFont = [param[ItemFont] intValue];
            int x_start = [param[ItemBeginX] intValue];
            int x_end = [param[ItemEndX] intValue];
            uint16_t y_start = [param[ItemBeginY] intValue];
            uint16_t y_end = [param[ItemEndY] intValue];
            uint16_t space = [param[ItemSpace] intValue];
            uint8_t mirror = [param[ItemMirror] intValue];
            uint8_t inverse = [param[ItemReverse] intValue];
            uint16_t rotate = [param[ItemRotate] intValue];
            
            NSMutableData *content = [NSMutableData data];
            [content appendBytes:&timeIndex length:2];
            [content appendBytes:&timeLen length:2];
            [content appendBytes:&timeFont length:2];
            [content appendBytes:&x_start length:4];
            [content appendBytes:&x_end length:4];
            [content appendBytes:&y_start length:2];
            [content appendBytes:&y_end length:2];
            [content appendBytes:&space length:2];
            [content appendBytes:&mirror length:1];
            [content appendBytes:&inverse length:1];
            [content appendBytes:&rotate length:2];
            
            NSDate *date = param[ItemTime];
            
            NSDateComponents *com = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] componentsInTimeZone:[NSTimeZone systemTimeZone] fromDate:date];
            uint8_t time_v = 0;
            time_v = (com.year - 2000);
            [content appendBytes:&time_v length:1];
            time_v = com.month;
            [content appendBytes:&time_v length:1];
            time_v = com.day;
            [content appendBytes:&time_v length:1];
            time_v = com.hour;
            [content appendBytes:&time_v length:1];
            time_v = com.minute;
            [content appendBytes:&time_v length:1];
            time_v = com.second;
            [content appendBytes:&time_v length:1];
            [content appendData:timeFormat];
            
            return content;
        }
            break;
        case REQ_downloadSort:
        {
            uint16_t timeIndex = [param[ItemLine] intValue];
            uint16_t timeLen = [param[ItemSortLength] intValue];
            uint16_t timeFont = [param[ItemFont] intValue];
            int x_start = [param[ItemBeginX] intValue];
            int x_end = [param[ItemEndX] intValue];
            uint16_t y_start = [param[ItemBeginY] intValue];
            uint16_t y_end = [param[ItemEndY] intValue];
            uint16_t space = [param[ItemSpace] intValue];
            uint8_t mirror = [param[ItemMirror] intValue];
            uint8_t inverse = [param[ItemReverse] intValue];
            uint16_t rotate = [param[ItemRotate] intValue];
            uint16_t offset = [param[ItemSortOffset] intValue];
            int number = [param[ItemSortNumber] intValue];
            
            NSMutableData *content = [NSMutableData data];
            [content appendBytes:&timeIndex length:2];
            [content appendBytes:&timeLen length:2];
            [content appendBytes:&timeFont length:2];
            [content appendBytes:&x_start length:4];
            [content appendBytes:&x_end length:4];
            [content appendBytes:&y_start length:2];
            [content appendBytes:&y_end length:2];
            [content appendBytes:&space length:2];
            [content appendBytes:&mirror length:1];
            [content appendBytes:&inverse length:1];
            [content appendBytes:&rotate length:2];
            [content appendBytes:&offset length:2];
            [content appendBytes:&number length:4];
            
            return content;
        }
            break;
        case REQ_downloadFileBegin:
        {
            uint16_t timeIndex = [param[ItemLine] intValue];
            uint16_t packageCount = [param[TotalPackages] intValue];
            int totalBytes = [param[TotalBytes] intValue];
            
            int x_start = [param[ItemBeginX] intValue];
            int x_end = [param[ItemEndX] intValue];
            uint16_t y_start = [param[ItemBeginY] intValue];
            uint16_t y_end = [param[ItemEndY] intValue];
            uint8_t grayLevel = [param[GrayLevel] intValue];
            uint8_t grayType = [param[GrayType] intValue];
//            uint16_t crc = [param[FileCrc] intValue];
            uint16_t notes = 0;
            
            NSMutableData *content = [NSMutableData data];
            [content appendBytes:&timeIndex length:2];
            [content appendBytes:&packageCount length:2];
            [content appendBytes:&totalBytes length:4];
            [content appendBytes:&x_start length:4];
            [content appendBytes:&x_end length:4];
            [content appendBytes:&y_start length:2];
            [content appendBytes:&y_end length:2];
            [content appendBytes:&grayType length:1];
            [content appendBytes:&grayLevel length:1];
//            [content appendBytes:&crc length:2];
            [content appendBytes:&notes length:2];
            
            return content;
        }
            break;
        case REQ_downloadFile:
        {
            uint16_t timeIndex = [param[PackageIndex] intValue];
            int totalBytes = [param[PackageValidLen] intValue];
            
            int x_start = [param[ItemBeginX] intValue];
            int x_end = [param[ItemEndX] intValue];
            uint16_t y_start = [param[ItemBeginY] intValue];
            uint16_t y_end = [param[ItemEndY] intValue];
            uint16_t crc = [param[PackageCrc] intValue];
            
            NSData *data = param[PackageData];
            
            NSMutableData *content = [NSMutableData data];
            [content appendBytes:&timeIndex length:2];
            [content appendBytes:&totalBytes length:2];
            [content appendBytes:&x_start length:4];
            [content appendBytes:&x_end length:4];
            [content appendBytes:&y_start length:2];
            [content appendBytes:&y_end length:2];
            [content appendBytes:&crc length:2];
            [content appendData:data];
            
            return content;
        }
            break;
        case REQ_startOTAUpgrade:
        {
            int totalBytes = [param[TotalBytes] intValue];
            uint16_t mtu = [param[OTAMTU] intValue];
            uint16_t packageCount = [param[TotalPackages] intValue];
            uint8_t big = [param[VersionBig] intValue];
            uint8_t small = [param[VersionSmall] intValue];
            uint16_t index = [param[VersionIndex] intValue];
            
            uint32_t crc = [param[FileCrc] unsignedIntValue];
            
            NSMutableData *content = [NSMutableData data];
            [content appendBytes:&totalBytes length:4];
            [content appendBytes:&mtu length:2];
            [content appendBytes:&packageCount length:2];
            [content appendBytes:&small length:1];
            [content appendBytes:&big length:1];
            [content appendBytes:&index length:2];
            [content appendBytes:&crc length:4];
            
            return content;
        }
            break;
        case REQ_OTAUpgrade:
        {
            uint16_t timeIndex = [param[PackageIndex] intValue];
            uint16_t crc = [param[PackageCrc] intValue];
            uint16_t totalBytes = [param[PackageValidLen] intValue];
            uint16_t notes = 0;
            NSData *data = param[PackageData];
            
            NSMutableData *content = [NSMutableData data];
            
            [content appendBytes:&timeIndex length:2];
            [content appendBytes:&crc length:2];
            [content appendBytes:&totalBytes length:2];
            [content appendBytes:&notes length:2];
            [content appendData:data];
            
            return content;
        }
            break;
        case REQ_setActive:
        {
            NSMutableData *content = [NSMutableData data];
            
            NSData *data = param[PackageData];
            uint16_t len = data.length;
            
            [content appendBytes:&len length:2];
            
            [content appendData:data];
            
            return content;
        }
        case REQ_getHardNum:
        {
//             05 00 30 aa aa
//                       uint8_t buf[2] = {0};
//                       buf[0] = 170;
//                       buf[1] = 170;
//                    return [NSData dataWithBytes:buf length:5];
        }
        case REQ_PrtDataOtaBegin:{
            
            int totalBytes = [param[@"totalBytes"] intValue];
            uint16_t otaMtu = [param[@"otaMtu"] intValue];
            uint16_t mtuNum = [param[@"mtuNum"] intValue];
            uint32_t crc = [param[@"prtDataCrc"] unsignedIntValue];
            
            NSMutableData *content = [NSMutableData data];
            [content appendBytes:&totalBytes length:4];
            [content appendBytes:&otaMtu length:2];
            [content appendBytes:&mtuNum length:2];
            [content appendBytes:&crc length:4];
            
            return content;
            
        }
        case REQ_PrtDataOtaSend:
        {
                       uint16_t timeIndex = [param[@"PackageIndex"] intValue];
                       uint16_t crc = [param[@"PackageCrc"] intValue];
                       uint16_t totalBytes = [param[@"PackageValidLen"] intValue];
                       NSData *data = param[@"PackageData"];
                       NSMutableData *content = [NSMutableData data];
                       
                       [content appendBytes:&timeIndex length:2];
                       [content appendBytes:&crc length:2];
                       [content appendBytes:&totalBytes length:2];
                       [content appendData:data];
                       return content;
                       
        }
            break;
        default:
            break;
    }
    return nil;
}

- (ResponseCmd *)generateResCmdByData:(NSData *)data cmdId:(int)cmdId {
    
    ResponseCmd *res = [ResponseCmd new];
    res.cmdId = cmdId;
    
    if (data.length == 0) {
        res.code = -1;
        return res;
    }
    
    uint8_t *buf = (uint8_t *)[data bytes];
    res.code = 1;
    
    switch (cmdId) {
        case RES_getDevice:
        {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            
            info[AddBattery] = @(buf[0]);
            info[BatteryStatus] = @(buf[1]);
            info[BatteryValue] = @(buf[2]);
            info[DeviceActive] = @(buf[3]);
            info[VersionBig] = @(buf[4]);
            info[VersionSmall] = @(buf[5]);
            info[VersionX1] = @(buf[6]);
            info[VersionX2] = @(buf[7]);
            uint16_t index = buf[8] + (buf[9] << 8);
            info[VersionIndex] = @(index);
            uint16_t mtu = buf[10] + (buf[11] << 8);
            info[VersionOTAMTU] = @(mtu);
            
            info[GrayLevel] = @(buf[12]);
            info[PixelToPrtPoint] = @(buf[13]);
            uint16_t maxPoint = buf[14] + (buf[15] << 8);
            info[ColMaxPrtPoint] = @(maxPoint);
            
            res.result = info;
        }
            break;
        case RES_getTime:
        {
            res.result = @{YEAR:@(buf[6]),MONTH:@(buf[5]),DAY:@(buf[3]),HOUR:@(buf[2]),MINUTE:@(buf[1]),SECOND:@(buf[0]),WEEKDAY:@(buf[4])};
        }
            break;
        case RES_getSystemParam:
        {
            
        }
            break;
        case RES_getPrintParam:
        {
            
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            uint16_t tmp = 0;
            tmp = *buf;
            info[PrtBeginDelay] = @(tmp);
            tmp = *(buf+2);
            info[PrtColsDelay] = @(tmp);
            tmp = *(buf+4);
            info[PrtColsMotos] = @(tmp);
            tmp = *(buf+6);
            info[PrtPlusWidth] = @(tmp);
            tmp = *(buf+8);
            info[PrtGrayScale] = @(tmp);
            tmp = *(buf+10);
            info[PrtGrayDelay] = @(tmp);
            tmp = *(buf+12);
            info[Prtvoltage] = @(tmp);
            tmp = *(buf+14);
            info[PrtRorL] = @(tmp);
            tmp = *(buf+16);
            info[Prtflie] = @(tmp);
            tmp = *(buf+18);
            info[IdlePrt] = @(tmp);
            
            res.result = info;
        }
            break;
        case RES_setTime:
        case RES_setSystemParam:
        case RES_setPrintParam:
        case RES_cleanPrint:
        case RES_startDownload:
        case RES_downloadTime:
        case RES_downloadSort:
        case RES_downloadFileBegin:
        case RES_downloadFileEnd:
        case RES_stopDownload:
        case RES_startOTAUpgrade:
        case RES_stopOTAUpgrade:
        case RES_PrtDataOtaBegin:
        case RES_PrtDataOtaSend:
        case RES_PrtDataOtaEnd:
        case RES_workStatus:
        case RES_setActive:
        {
            res.code = buf[0];
        }
            break;
        case RES_downloadFile:
        {
                     
                      NSMutableDictionary *info = [NSMutableDictionary dictionary];
                       uint16_t tmp = 0;
                       tmp = *buf;
                       info[@"1"] = @(tmp);
                       tmp = *(buf+2);
                       info[@"2"] = @(tmp);
                       res.result = info;
                    
        }
            break;
        case RES_OTAUpgrade:
        {
            res.code = buf[0];
            uint16_t index = buf[2] + (buf[1] << 8);
            res.result = @{@"PackageIndex":@(index)};
        }
            break;
        case RES_getHardNum:
        {
                       NSMutableData *mutData = [NSMutableData dataWithData:data];
                       NSData *subData =[mutData subdataWithRange:NSMakeRange(2,mutData.length-2)];
                       NSString *str = [[NSString alloc]initWithData:subData encoding:NSUTF8StringEncoding];
                       NSMutableDictionary *info = [NSMutableDictionary dictionary];
                       [info setValue:str forKey:@"WIFIName"];
                       res.result = info;
        }
            break;
        case RES_batteryStatus:{
            res.code = buf[3];
        }
            break;
        
        default:
            break;
    }
    
//    NSLog(@"response.cmdid=%d,result=%@",res.cmdId,res.result);
    
    return res;
}

- (NSDictionary *)parseInfoByData:(NSData *)data cmdId:(int)cmdId {
    
    switch (cmdId) {
        case RES_getDevice:
        {
            NSStringEncoding   gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            
            NSString *name = [[NSString alloc] initWithData:data encoding:gbkEncoding];
            
            if (name) {
                return @{@"deviceName":name};
            }
        }
            break;
        case RES_setTime:
        {
            uint8_t *buf = (uint8_t *)[data bytes];
            return @{@"year":@(buf[6]),@"month":@(buf[5]),@"day":@(buf[3]),@"hour":@(buf[2]),@"minute":@(buf[1]),@"second":@(buf[0]),@"weekday":@(buf[4])};
        }
            break;
            
        default:
            break;
    }
    return nil;
}

- (NSData *)dataWithString:(NSString *)string {
    
    NSStringEncoding   gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    return [string dataUsingEncoding:gbkEncoding];
}

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )

- (NSData *)imageToBitData:(UIImage *)image {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();//颜色通道
    CGImageRef imageRef = image.CGImage;//位图
    int width = (int)CGImageGetWidth(imageRef);//位图宽
    int height = (int)CGImageGetHeight(imageRef);//位图高
    
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, width*4, colorSpace, kCGImageAlphaNone|kCGImageAlphaPremultipliedLast);//生成上下午
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), imageRef);//绘制图片到上下文中
    
    uint32_t *buf = (uint32_t *)CGBitmapContextGetData(context);//(uint32_t *)malloc(width*height);
    
    uint8_t bitMap[height][width];
    
    uint32_t color = 0;
    int testPic = 0;
    NSLog(@"转化前数据:\n");
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            color = buf[i*width + j];
            
            if (testPic == 0) {
                
                color = (R(color)*38 + G(color)*75 + B(color)*15) >> 7;
            }
            else if (testPic == 1) {
                if (i >= height*0.35 && i <= height*0.65) {
                    color = 0;
                }
                else if (i < height*0.35 && j >= width*0.35 && j <= width*0.65) {
                    color = 0;
                }
                else {
                    color = 255;
                }
            }
//            printf("%03d ",color);
            //测试图片
            if (color <= 120) {
                color = 1;
            }
            else {
                color = 0;
            }
            bitMap[i][j] = color;
            printf("%02d ",color);
        }
        printf("\n");
    }
    
    int bitHeight = height/8 + (height%8?1:0);
    int bitWidth = width;

    uint8_t coverMap[bitWidth][bitHeight];
    memset(coverMap, 0, bitWidth*bitHeight);

    uint8_t byte = 0;
    int p = 0;
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {

            byte |= bitMap[j][i] << p;
            p++;

            coverMap[i][j/8] = byte;

            if (p == 8) {
                p = 0;
                byte = 0;
            }
        }
        p = 0;
        byte = 0;
    }
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return [NSData dataWithBytes:coverMap length:bitWidth*bitHeight];
}
@end
