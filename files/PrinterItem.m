//
//  PrinterItem.m
//  PenMaJi
//
//  Created by Arvin on 2019/8/17.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import "PrinterItem.h"
#import "UIImage+CECategory.h"
#import "PMJImageHandle.h"

#define InkColor  [UIColor redColor]

@implementation PrinterItem

- (instancetype)init {
    if (self = [super init]) {
        _type = PrintItemText;
        _grayLevel = 2;
    }
    return self;
}

- (float)rotateAngle {
    return _rotate * 90;
}

- (UIImage *)asImage {
    
    return nil;
}

- (BOOL)contentIsEmpty {
    return NO;
}

- (int)minSpace {
    return -50;
}

- (NSString *)text {
    return @"";
}

- (void)setText:(NSString *)text {
    
}

- (void)copyToPrint:(PrinterItem *)print {
    
    print.rotate = self.rotate;
    print.reverse = self.reverse;
    print.mirror = self.mirror;
    print.frame = self.frame;
    print.space = self.space;
    print.grayLevel = self.grayLevel;
    print.scale = self.scale;
}

- (NSComparisonResult)compareByFrame:(PrinterItem *)other {
    
    if (self.frame.origin.x > other.frame.origin.x) {
        return NSOrderedDescending;
    }
    else if (self.frame.origin.x < other.frame.origin.x) {
        return NSOrderedAscending;
    }
    return NSOrderedSame;
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:@"frame"]) {
        return [NSString stringWithFormat:@"%d,%d,%d,%d",(int)_frame.origin.x,(int)_frame.origin.y,(int)_frame.size.width,(int)_frame.size.height];
    }
    return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if ([key isEqualToString:@"frame"]) {
        NSArray *com = [value componentsSeparatedByString:@","];
        if ([com count] == 4) {
            _frame = CGRectMake([com[0] intValue], [com[1] intValue], [com[2] intValue], [com[3] intValue]);
        }
    }
    else {
        [super setValue:value forKey:key];
    }
}
@end

@implementation PrinterText

- (instancetype)init {
    if (self = [super init]) {
        _fontsize = 50;
        _fontName = @"HYm1gj";
        _fontStyle = FontNormal;
        _fontSizeString = @"16x16";
        self.space = 0;
    }
    return self;
}

- (int)font {
    
    if (_fontSizeString.length) {
        
        NSArray *array = @[@"5x7",@"12x12",@"16x16",@"24x24",@"32x32",@"48x48"];
        NSInteger index = [array indexOfObject:_fontSizeString];
        if (index >= [array count] || index < 0) {
            index = 1;
        }
        
        return (int)index;
    }

    return _fontsize;
}

- (void)setScale:(float)scale {
    super.scale = scale;
    
    //对应字体50～150
    _fontsize = 50 + scale*(150-50);
    
}

- (NSString *)text {
    
    return @"";
}

- (BOOL)contentIsEmpty {
    return [self text].length == 0;
}

- (int)minSpace {
    return -self.fontsize/3;
}

- (void)copyToPrint:(PrinterText *)print {
    
    [super copyToPrint:print];
    
    print.fontStyle = self.fontStyle;
    print.fontsize = self.fontsize;
    print.fontName = self.fontName;
    print.fontSizeString = self.fontSizeString;
}

/*字体是以像素（px）为单位的，iOS App开发中字体以磅(pt)为单位，它们的转换关系为：pt = (px / 96) * 72*/
- (UILabel *)textLabel {
    
    NSString *content = [self text];
    
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
#if USE_OLD
    
    NSArray *com = [self.fontSizeString componentsSeparatedByString:@"x"];
    UIFont *font = [self fontBySize:CGSizeMake([com[0] intValue], [com[1] intValue]) text:content];
    
    label.attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor blackColor],NSKernAttributeName:@(self.space)}];
    
    
#else
    switch (self.fontStyle) {
        case FontNormal:
        {
            
            label.attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont fontWithName:self.fontName size:self.fontsize],NSForegroundColorAttributeName:[UIColor blackColor],NSKernAttributeName:@(self.space)}];
        }
            break;
        case FontVerList:
        {
            CGFloat label_w = 0;
            CGFloat label_h = 0;
            for (int i = 0; i < content.length; i++) {
                UILabel *sub = [UILabel new];
                sub.backgroundColor = [UIColor clearColor];
                sub.font = [UIFont fontWithName:self.fontName size:self.fontsize];
                sub.textColor = [UIColor blackColor];
                sub.text = [content substringWithRange:NSMakeRange(i, 1)];
                [sub sizeToFit];

                [label addSubview:sub];

                sub.transform = CGAffineTransformMakeRotation(-M_PI_2);
                
                sub.center = CGPointMake(label_w + sub.frame.size.width/2, sub.frame.size.height/2);
                
                label_w += sub.frame.size.width + self.space;
                
                if (label_h < sub.frame.size.height) {
                    label_h = sub.frame.size.height;
                }
            }

            label_w -= self.space;

            label.frame = CGRectMake(0, 0, label_w, label_h);
            
            for (UILabel *sub in label.subviews) {
                sub.center = CGPointMake(sub.center.x, label_h/2);
            }
        }
            break;
        case FontBold:
        {
            label.attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.fontsize],NSForegroundColorAttributeName:[UIColor blackColor],NSKernAttributeName:@(self.space)}];
        }
            break;
        case FontItalic:
        {
            label.attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont fontWithName:self.fontName size:self.fontsize],NSForegroundColorAttributeName:[UIColor blackColor],NSObliquenessAttributeName:@(0.2),NSKernAttributeName:@(self.space)}];
        }
            break;
        case FontDelete:
        {
            label.attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont fontWithName:self.fontName size:self.fontsize],NSForegroundColorAttributeName:[UIColor blackColor],NSStrikethroughStyleAttributeName:@(1),NSKernAttributeName:@(self.space)}];
        }
            break;
        case FontUndleline:
        {
            label.attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont fontWithName:self.fontName size:self.fontsize],NSForegroundColorAttributeName:[UIColor blackColor],NSUnderlineStyleAttributeName:@(1),NSKernAttributeName:@(self.space)}];
        }
            break;
        default:
            break;
    }
#endif
    if (self.fontStyle != FontVerList)
    {
        [label sizeToFit];
    }
    
    return label;
}

- (UIFont *)fontBySize:(CGSize)size text:(NSString *)text {
    
    NSAttributedString *str = nil;
    
    UIFont *font = [UIFont systemFontOfSize:MIN_FONT];
    CGRect rect = CGRectZero;
    
    for (int i = MIN_FONT; i < 200; i++) {
        
        font = [UIFont systemFontOfSize:i];
        
        str = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font,NSKernAttributeName:@(self.space)}];
        
        rect = [text boundingRectWithSize:CGSizeMake(10000, 200) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];
        
        if (rect.size.width > size.width*0.5 * text.length || rect.size.height > 48) {
            break;
        }
        
    }
    
    return font;
}

- (UIImage *)asImage {
    
    UILabel *label = [self textLabel];
    
    UIGraphicsBeginImageContextWithOptions(label.bounds.size, NO, UIScreen.mainScreen.scale);
    [label.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    image = [image imageBlackAndWhiteColor];

    if (self.mirror) {
        image = [image imageWithMirror:0];
    }
    
    if (self.reverse) {
        image = [image imageWithInverse];

    }
    
    if (self.rotate) {
        image = [image imageWithRotate:self.rotate];
    }
    
    CGRect rect = self.frame;
    
    rect.size.width = image.size.width;
    rect.size.height = image.size.height;
    
    self.frame = rect;
    
    return image;
}

@end

@implementation PrinterWord

- (instancetype)init {
    
    if (self = [super init]) {
    }
    return self;
}

- (NSString *)text {
    
    return _word;
}

- (void)setText:(NSString *)text {
    _word = text;
}

- (void)copyToPrint:(PrinterWord *)print {
    
    [super copyToPrint:print];
    print.word = self.word;
}

@end

@implementation PrinterTime
- (instancetype)init {
    if (self = [super init]) {
        self.type = PrintItemTime;
        
        _format = @"yyyy-MM-dd";
        
        _time = [NSDate date];
    }
    return self;
}

- (NSString *)text {
    
    return [self timeString];
}

- (NSString *)timeString {
    
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:_format];
    
    return [dateFormat stringFromDate:_time];
}

- (NSString *)fullTimeString {
    
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    
    return [dateFormat stringFromDate:_time];
}

- (void)copyToPrint:(PrinterTime *)print {
    
    [super copyToPrint:print];
    
    print.time = self.time;
    print.format = self.format;
}
@end

@implementation PrinterSort
- (instancetype)init {
    if (self = [super init]) {
        self.type = PrintItemSort;
        
        _length = 6;
        _offset = 1;
    }
    return self;
}

- (NSString *)text {
    
    return [NSString stringWithFormat:[NSString stringWithFormat:@"%%0%dd",_length],_sort];
}

- (void)copyToPrint:(PrinterSort *)print {
    
    [super copyToPrint:print];
    
    print.sort = self.sort;
    print.length = self.length;
    print.offset = self.offset;
}
@end

@implementation PrinterWeight
- (instancetype)init {
    if (self = [super init]) {
        self.type = PrintItemWeight;
        _format = @"x.xx";
    }
    return self;
}

+ (NSArray *)allUnitString {
    
//    NSArray *appLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
//    NSString *languageName = [appLanguages objectAtIndex:0];
//
//    if ([languageName hasPrefix:@"zh-"]) {
//        return @[@"g",@"kg",@"克",@"千克",@"公斤",@"斤",@"磅",@"吨",@"盎司"];
//    }
    return @[@"g",@"kg",@"oz",@"lbs",@"t"];
}

- (NSString *)unitString {
    return [[[self class] allUnitString] objectAtIndex:_unit];
}

- (NSInteger)pointLen {
    
    NSArray *com = [_format componentsSeparatedByString:@"."];
    if ([com count] > 1) {
        return [com[1] length];
    }
    return 0;
}

- (NSInteger)pointValue {
    
    NSString *str = [self text];
    NSArray *com = [str componentsSeparatedByString:@"."];
    if ([com count] > 1) {
        return [com[1] integerValue];
    }
    return 0;
}

- (NSUInteger)weightIntValue {
    
    NSString *str = [self text];
    NSArray *com = [str componentsSeparatedByString:@"."];
    if ([com count] > 0) {
        return [com[0] unsignedLongLongValue];
    }
    return 0;
}

- (NSString *)text {
    
    if (_weight.length == 0) {
        _weight = @"0";
    }
    
    NSArray <NSString *> *com = [_format componentsSeparatedByString:@"."];
    if ([com count] <= 1) {
        return [NSString stringWithFormat:@"%@%@",_weight,[self unitString]];
    }
    
    int len = (int)com[1].length;
    if (_weight.length <= len) {
        return [NSString stringWithFormat:[NSString stringWithFormat:@"0.%%0%dd%%@",len],_weight.intValue,[self unitString]];
    }
    
    return [NSString stringWithFormat:@"%@.%@%@",[_weight substringToIndex:_weight.length-len],[_weight substringFromIndex:_weight.length-len],[self unitString]];
}

- (void)copyToPrint:(PrinterWeight *)print {
    
    [super copyToPrint:print];
    print.weight = self.weight;
    print.unit = self.unit;
    print.format = self.format;
}
@end

@implementation PrinterImage
- (instancetype)init {
    if (self = [super init]) {
        self.type = PrintItemImage;
        _imgScale = 1.0;
        self.scale = 1.0;
//        self.scale = 4.0;
    }
    return self;
}

- (BOOL)contentIsEmpty {
    
    UIImage *image = [UIImage imageNamed:_imageName];
    
    if (!image) {
        NSString *path = [[PMJImageHandle emojiFolder] stringByAppendingPathComponent:_imageName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            image = [UIImage imageWithContentsOfFile:path];
        }
    }
    
    return image == nil;
}
//图片高度范围100～150px
- (UIImage *)asImage {
    
    UIImage *image = [UIImage imageNamed:_imageName];
    
    if (!image) {
        NSString *path = [[PMJImageHandle emojiFolder] stringByAppendingPathComponent:_imageName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            image = [UIImage imageWithContentsOfFile:path];
        }
    }
    
    CGFloat img_h = 100 + 50 * self.scale;
    if ([dhServerApi getIsIpad]) {
        img_h = 200 + 100 * self.scale;
    }
    float scale = image.size.height/img_h;
    image = [image scaleToSize:CGSizeMake(image.size.width/scale, img_h)];
    
    if (self.mirror) {
        image = [image imageWithMirror:0];
    }
    
    if (self.reverse) {
        image = [image imageWithInverse];
    }
    
    if (self.rotate) {
        image = [image imageWithRotate:self.rotate];
    }
    
    CGRect rect = self.frame;
    
    rect.size.width = image.size.width;
    rect.size.height = image.size.height;
    
    self.frame = rect;
    
    UIImage *image2 = [dhServerApi image:image withColor:[UIColor whiteColor]];

    
    return image2;
}

- (void)copyToPrint:(PrinterImage *)print {
    
    [super copyToPrint:print];
    
    print.imageName = self.imageName;
    print.imgScale = self.imgScale;
}
@end

@implementation PrinterQrcode
- (instancetype)init {
    if (self = [super init]) {
        self.type = PrinterItemQrcode;
        self.scale = 0.5;
    }
    return self;
}

- (BOOL)contentIsEmpty {

    return self.content.length == 0;
}

- (void)setContent:(NSString *)content {
    
    if ([_content isEqualToString:content]) {
        
        return;
    }
    
    _content = content;
}

- (NSString *)text {
    return _content;
}

- (void)setText:(NSString *)text {
    _content = text;
}

- (void)copyToPrint:(PrinterQrcode *)print {
    
    [super copyToPrint:print];
    print.content = self.content;
}

- (UIImage *)asImage {
    
    if (self.content.length == 0) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 0, 0);
        return nil;
    }
    
    
    //创建名为"CIQRCodeGenerator"的CIFilter
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    //将filter所有属性设置为默认值
    [filter setDefaults];
    
    //将所需尽心转为UTF8的数据，并设置给filter
    NSData *data = [self.content dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    
    //设置二维码的纠错水平，越高纠错水平越高，可以污损的范围越大
    /*
     * L: 7%
     * M: 15%
     * Q: 25%
     * H: 30%
     */
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    //拿到二维码图片，此时的图片不是很清晰，需要二次加工
    CIImage *outputImage = [filter outputImage];
    
    CGRect extent = CGRectIntegral(outputImage.extent);
    CGFloat img_h = 100 + 50 * self.scale;
    if ([dhServerApi getIsIpad]) {
       img_h = 200 + 100 * self.scale;
    }
    extent.size.width = img_h;
    extent.size.height = img_h;
    
    UIImage *image = [UIImage safeScaleImage:outputImage size:extent.size];
    
    if (self.mirror) {
        image = [image imageWithMirror:0];
    }
    
    if (self.reverse) {
        image = [image imageWithInverse];
    }
    
    if (self.rotate) {
        image = [image imageWithRotate:self.rotate];
    }
    
//    if (self.imgScale == 1) {
//    }
//    else if (self.imgScale < 1) {
//
//        float w = image.size.width * self.imgScale;
////        if (w < 20) {
////            w = 20;
////        }
//        image = [image scaleToSize:CGSizeMake(w, w)];
//    }
//    else {
//        float w = image.size.width * self.imgScale;
//        if (w > 50) {
//            w = 50;
//        }
//        image = [image safeScaleImageBySize:CGSizeMake(w, w)];
//    }
    
    CGRect rect = self.frame;
    
    rect.size.width = image.size.width;
    rect.size.height = image.size.height;
    
    self.frame = rect;
    
    return image;
}

@end

@implementation PrinterLineCode
- (instancetype)init {
    if (self = [super init]) {
        self.type = PrinterItemLineCode;
        _codeType = @"Code128";
        self.scale = 0.5;
    }
    return self;
}

- (BOOL)contentIsEmpty {
    
    return self.content.length == 0;
}

- (NSString *)text {
    return _content;
}

- (void)setText:(NSString *)text {
    _content = text;
}

- (void)copyToPrint:(PrinterLineCode *)print {
    
    [super copyToPrint:print];
    print.content = self.content;
    print.codeType = self.codeType;
}

- (void)setContent:(NSString *)content {
    
    if ([_content isEqualToString:content]) {
        
        return;
    }
    
    _content = content;
}

- (UIImage *)asImage {
    
    if (self.content.length == 0) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 0, 0);
        return nil;
    }
    
    //创建名为"CIQRCodeGenerator"的CIFilter
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    
    //将filter所有属性设置为默认值
    [filter setDefaults];
    
    //将所需尽心转为UTF8的数据，并设置给filter
    NSData *data = [self.content dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@(1.0) forKey:@"inputQuietSpace"];
    CGFloat img_h = 100 + 50 * self.scale;
    if ([dhServerApi getIsIpad]) {
        img_h = 200 + 100 * self.scale;
    }
    [filter setValue:@(img_h) forKey:@"inputBarcodeHeight"];
    
    //拿到二维码图片，此时的图片不是很清晰，需要二次加工
    CIImage *outputImage = [filter outputImage];
    CGRect extent = CGRectIntegral(outputImage.extent);
    
    UIImage *image = [UIImage safeScaleImage:outputImage size:CGSizeMake(extent.size.width*4, extent.size.height)];
    
    if (self.mirror) {
        image = [image imageWithMirror:0];
    }
    
    if (self.reverse) {
        image = [image imageWithInverse];
    }
    
    if (self.rotate) {
        image = [image imageWithRotate:self.rotate];
    }
    
    if (self.imgScale == 1) {
        
    }
    else if (self.imgScale < 1) {
        image = [image scaleToSize:CGSizeMake(image.size.width*self.imgScale, image.size.height*self.imgScale)];
    }
    else {
        image = [image safeScaleImageBySize:CGSizeMake(image.size.width*self.imgScale, image.size.height*self.imgScale)];
    }
    
    CGRect rect = self.frame;
    
    rect.size.width = image.size.width;
    rect.size.height = image.size.height;
    
    self.frame = rect;
    
    return image;
}
@end
