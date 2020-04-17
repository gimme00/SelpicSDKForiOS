//
//  ProductDefine.h
//  PenMaJi
//
//  Created by Arvin on 2019/8/9.
//  Copyright © 2019 Arvin. All rights reserved.
//

#ifndef ProductDefine_h
#define ProductDefine_h

enum {
    
    REQ_setTime = 0x01,
    RES_setTime = REQ_setTime,
    
    REQ_getTime = 0x02,
    RES_getTime = REQ_getTime,
    
    REQ_setSystemParam = 0x03,
    RES_setSystemParam = REQ_setSystemParam,
    
    REQ_getSystemParam = 0x04,
    RES_getSystemParam = REQ_getSystemParam,
    
    REQ_setPrintParam = 0x05,
    RES_setPrintParam = REQ_setPrintParam,
    
    REQ_getPrintParam = 0x06,
    RES_getPrintParam = REQ_getPrintParam,
    
    REQ_getDevice = 0x07,
    RES_getDevice = REQ_getDevice,
    
    REQ_cleanPrint = 0x08,
    RES_cleanPrint = REQ_cleanPrint,
    
    REQ_workStatus = 0x09,
    RES_workStatus = REQ_workStatus,
    
    REQ_startDownload = 0x10,
    RES_startDownload = REQ_startDownload,
    
    REQ_downloadTime = 0x11,
    RES_downloadTime = REQ_downloadTime,
    
    REQ_downloadSort = 0x12,
    RES_downloadSort = REQ_downloadSort,
    
    REQ_downloadFileBegin = 0x1C,
    RES_downloadFileBegin = REQ_downloadFileBegin,
    
    REQ_downloadFile = 0x1D,
    RES_downloadFile = REQ_downloadFile,
    
    REQ_downloadFileEnd = 0x1E,
    RES_downloadFileEnd = REQ_downloadFileEnd,
    
    REQ_stopDownload = 0x1F,
    RES_stopDownload = REQ_stopDownload,
    
    REQ_startOTAUpgrade = 0x20,
    RES_startOTAUpgrade = REQ_startOTAUpgrade,
    
    REQ_OTAUpgrade = 0x21,
    RES_OTAUpgrade = REQ_OTAUpgrade,
    
    REQ_stopOTAUpgrade = 0x22,
    RES_stopOTAUpgrade = REQ_stopOTAUpgrade,
    
    REQ_restart = 0x23,
    
    REQ_PrtDataOtaBegin = 0x24,
    RES_PrtDataOtaBegin = REQ_PrtDataOtaBegin,
    
    REQ_PrtDataOtaSend  = 0x25,
    RES_PrtDataOtaSend  = REQ_PrtDataOtaSend,
    
    REQ_PrtDataOtaEnd = 0x26,
    RES_PrtDataOtaEnd = REQ_PrtDataOtaEnd,
    
    REQ_getHardNum = 0x30,
    RES_getHardNum = REQ_getHardNum,
    
    REQ_setActive = 0x32,
    RES_setActive = REQ_setActive,
    
    REQ_batteryStatus = 0xfa,
    RES_batteryStatus = REQ_batteryStatus,
};

typedef enum {
    DownloadText,
    DownloadImage,
    DownloadQrCode,
    DownloadTime,
    DownloadSortNum,
    DownloadWeight,
    DownloadBarcode
}DownloadType;

typedef NSString * ParamKey;
typedef NSDictionary *YearParamInfo;
extern ParamKey const YEAR;
extern ParamKey const MONTH;
extern ParamKey const DAY;
extern ParamKey const WEEKDAY;
extern ParamKey const HOUR;
extern ParamKey const MINUTE;
extern ParamKey const SECOND;
extern ParamKey const NAME;

typedef NSDictionary *PrintParamInfo;
extern ParamKey const PrtBeginDelay; //开始打印延时，按下打印键后多久才开始打
extern ParamKey const PrtColsDelay;  //列和列间的时间间隔.编码器无效时可以此参数
extern ParamKey const PrtColsMotos; //列和列计多个编码器计数。
extern ParamKey const PrtPlusWidth;//打印脉冲宽度
extern ParamKey const PrtGrayScale;//打印灰度
extern ParamKey const PrtGrayDelay;
extern ParamKey const Prtvoltage;//打印电压
extern ParamKey const PrtRorL;//左右喷头选择
extern ParamKey const Prtflie;//打印文件选择,<4打印对应的文件，=4:1->2文件轮流打，=5：1->2->3轮流打印。
extern ParamKey const IdlePrt;//闲喷,高字节表示空闲时间多久开始闲喷，低字节表示，喷多少列。避免长时间不用喷头堵住。
extern ParamKey const PttRasterize;//光栅
extern ParamKey const PrtperCrc;

typedef NSDictionary *SystemParamInfo;

typedef NSDictionary *PrintItemInfo;

extern ParamKey const ItemIndex;
extern ParamKey const ItemType;
extern ParamKey const ItemFont;
extern ParamKey const ItemSpace;
extern ParamKey const ItemFormat;
extern ParamKey const ItemReverse;
extern ParamKey const ItemRotate;
extern ParamKey const ItemMirror;
extern ParamKey const ItemBeginX;
extern ParamKey const ItemEndX;
extern ParamKey const ItemBeginY;
extern ParamKey const ItemEndY;
extern ParamKey const ItemLine;
extern ParamKey const ItemIsTest;

extern ParamKey const ItemText;

extern ParamKey const ItemTime;
extern ParamKey const ItemTimeFormat;

extern ParamKey const ItemSortNumber;
extern ParamKey const ItemSortLength;
extern ParamKey const ItemSortOffset;

extern ParamKey const ItemWeightPointLen;
extern ParamKey const ItemWeightUnit;
extern ParamKey const ItemWeightPointValue;
extern ParamKey const ItemWeightIntValue;

extern ParamKey const ItemImage;
extern ParamKey const ItemImageWidth;
extern ParamKey const ItemImageHeight;

typedef NSDictionary *DeviceInfo;
extern ParamKey const AddBattery;
extern ParamKey const BatteryStatus;
extern ParamKey const BatteryValue;
extern ParamKey const DeviceActive;
extern ParamKey const VersionBig;
extern ParamKey const VersionSmall;
extern ParamKey const VersionX1;
extern ParamKey const VersionX2;
extern ParamKey const VersionIndex;
extern ParamKey const VersionOTAMTU;

extern ParamKey const MaxGrayLevel;
extern ParamKey const PixelToPrtPoint;
extern ParamKey const ColMaxPrtPoint;

extern ParamKey const TotalPackages;
extern ParamKey const GrayLevel;
extern ParamKey const GrayType;
extern ParamKey const TotalBytes;
extern ParamKey const FileCrc;
extern ParamKey const PackageIndex;
extern ParamKey const PackageValidLen;
extern ParamKey const PackageCrc;
extern ParamKey const OTAMTU;
extern ParamKey const PackageData;

extern ParamKey const ResultError;

#endif /* ProductDefine_h */
