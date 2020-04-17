//
//  PrinterItem.h
//  PenMaJi
//
//  Created by Arvin on 2019/8/17.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BaseKVCObj.h"

#define SHOW_SCALE  1

#define MIN_FONT    20
#define MAX_FONT    150
//#define MAX_FONT    308

typedef enum {
    PrintItemText = 1,
    PrintItemTime,
    PrintItemSort,
    PrintItemWeight,
    PrintItemImage,
    PrinterItemQrcode,
    PrinterItemLineCode,
}PrintItemType;

typedef enum {
    FontNormal,
    FontItalic,
    FontVerList,
    FontBold,
    FontUndleline,
    FontDelete
}FontStyle;

@interface PrinterItem : BaseKVCObj

@property (nonatomic,assign) PrintItemType type;
@property (nonatomic,assign) int rotate;
@property (nonatomic,assign) BOOL reverse;
@property (nonatomic,assign) BOOL mirror;
@property (nonatomic,assign) CGRect frame;
@property (nonatomic,assign) int space;
@property (nonatomic,assign) int grayLevel;
@property (nonatomic,assign) float scale;//显示倍数 0~1,最小值和最大值由具体的item自定

- (UIImage *)asImage;

- (BOOL)contentIsEmpty;

- (void)copyToPrint:(PrinterItem *)print;

- (NSComparisonResult)compareByFrame:(PrinterItem *)other;

- (int)minSpace;

- (NSString *)text;
- (void)setText:(NSString *)text;

- (NSAttributedString *)attributedText;

@end

@interface PrinterText : PrinterItem

@property (nonatomic,assign) FontStyle fontStyle;
@property (nonatomic,assign) int fontsize;
@property (nonatomic,strong) NSString *fontName;
@property (nonatomic,strong) NSString *fontSizeString;

- (int)font;

@end

@interface PrinterWord : PrinterText

@property (nonatomic,strong) NSString *word;

@end

@interface PrinterTime : PrinterText

@property (nonatomic,strong) NSDate *time;
@property (nonatomic,strong) NSString *format;

- (NSString *)timeString;
- (NSString *)fullTimeString;

@end

@interface PrinterSort : PrinterText

@property (nonatomic,assign) int sort;
@property (nonatomic,assign) int offset;
@property (nonatomic,assign) int length;

@end

@interface PrinterWeight : PrinterText

@property (nonatomic,assign) int unit;
@property (nonatomic,strong) NSString *weight;
@property (nonatomic,strong) NSString *format;

+ (NSArray *)allUnitString;

- (NSString *)unitString;

- (NSInteger)pointLen;
- (NSInteger)pointValue;
- (NSUInteger)weightIntValue;

@end

@interface PrinterImage : PrinterItem

@property (nonatomic,assign) float imgScale;
@property (nonatomic,strong) NSString *imageName;

@end

@interface PrinterQrcode : PrinterImage

@property (nonatomic,strong) NSString *content;

@end

@interface PrinterLineCode : PrinterImage

@property (nonatomic,strong) NSString *content;
@property (nonatomic,strong) NSString *codeType;

@end
