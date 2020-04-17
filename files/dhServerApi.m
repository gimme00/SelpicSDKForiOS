//
//  dhServerApi.m
//  PenMaJi
//
//  Created by 徐迪华 on 2019/11/20.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import "dhServerApi.h"
#import<SystemConfiguration/CaptiveNetwork.h>
#import <UIKit/UIKit.h>
#import "Product.h"

#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#define ScreenWidth [UIScreen mainScreen].bounds.size.width

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )

static CGRect swapWidthAndHeight(CGRect rect)
{
    CGFloat  swap = rect.size.width;
    
    rect.size.width  = rect.size.height;
    rect.size.height = swap;
    
    return rect;
}

@implementation dhServerApi
+ (NSString *)GetSSID{
 NSString *ssid = @"Not Found";
 CFArrayRef myArray = CNCopySupportedInterfaces();
 if (myArray != nil) {
   CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
    if (myDict != nil) {
    NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
    ssid = [dict valueForKey:@"SSID"];
}
     }
 return ssid;
}

+(void)saveStrWithKey:(NSString*)key Value:(NSString*)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}
+(void)saveDictWithKey:(NSString*)key Dict:(NSDictionary*)dict{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dict forKey:key];
    [defaults synchronize];
}
+(void)saveArrWithKey:(NSString*)key Arr:(NSArray*)arr{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:arr forKey:key];
    [defaults synchronize];
}
+(NSString*)getStrWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *value = [defaults objectForKey:key];
    return value;
}
+(NSDictionary*)getDictWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *value = (NSDictionary*)[defaults objectForKey:key];
    return value;
}
+(NSArray*)getArrtWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *value = (NSArray*)[defaults objectForKey:key];
    return value;
}
+(CAShapeLayer*)getCornerViewWithLineColor:(UIColor*)color  View:(UIView*)view Corndi:(CGFloat)cordi{
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(view.frame.size.width/cordi, view.frame.size.height/cordi)];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.strokeColor = color.CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.path = bezierPath.CGPath;
    return shapeLayer;
}
+(void)lockScren{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}
+(void)unLockScren{
     [UIApplication sharedApplication].idleTimerDisabled = YES;
}
+(NSString *)hexStringFromString:(NSString *)string{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}


// 十六进制转换为普通字符串的。
+(NSString *)stringFromHexString:(NSString *)hexString {
    
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    NSLog(@"------字符串=======%@",unicodeString);
    return unicodeString;

}
+(BOOL)ValidateEmail:(NSString*)email {

    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";

    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    return [emailTest evaluateWithObject:email];

}
+(NSString*)getAppVersion{
    NSDictionary *infoDict = [[NSBundle mainBundle]infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    return appVersion;
}
+(void)jumpToAppStre{
    NSString *url = @"https://itunes.apple.com/app/apple-store/id1480400818?mt=8";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
+(NSString*)getTimerStr{
     NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        NSDate *datenow = [NSDate date];
        NSString *currentTimeString = [formatter stringFromDate:datenow];
        NSString *timerStr = [NSString stringWithFormat:@"%@-xdhPhoto",currentTimeString];
        return timerStr;
}
+ (void)removeDataBase:(NSString*)name{

NSString* cachePath = [NSString stringWithFormat:@"/%@",[NSString stringWithFormat:@"/%@/%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject],name]];

NSFileManager*fileManager = [NSFileManager defaultManager];

if (![fileManager fileExistsAtPath:cachePath]) {

return;

}

NSEnumerator* chileFilesEnumerator = [[fileManager subpathsAtPath:cachePath]objectEnumerator];

NSString* fileName;

while ((fileName = [chileFilesEnumerator nextObject]) !=nil) {

NSString* fileAbsolutePath = [cachePath stringByAppendingPathComponent:fileName];

[fileManager removeItemAtPath:fileAbsolutePath error:NULL];

}

}
#pragma mark 调整图片分辨率/尺寸（等比例缩放）
+ (UIImage *)newSizeImage:(CGSize)size image:(UIImage *)sourceImage {
    CGSize newSize = CGSizeMake(sourceImage.size.width, sourceImage.size.height);
    
    CGFloat tempHeight = newSize.height / size.height;
    CGFloat tempWidth = newSize.width / size.width;
    
    if (tempWidth > 1.0 && tempWidth > tempHeight) {
        newSize = CGSizeMake(sourceImage.size.width / tempWidth, sourceImage.size.height / tempWidth);
    } else if (tempHeight > 1.0 && tempWidth < tempHeight) {
        newSize = CGSizeMake(sourceImage.size.width / tempHeight, sourceImage.size.height / tempHeight);
    }
    
    UIGraphicsBeginImageContext(newSize);
    [sourceImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
#pragma mark - 图片压缩
+(NSData *)resetSizeOfImageData:(UIImage *)sourceImage maxSize:(NSInteger)maxSize {
    //先判断当前质量是否满足要求，不满足再进行压缩
    __block NSData *finallImageData = UIImageJPEGRepresentation(sourceImage,1.0);
    NSUInteger sizeOrigin   = finallImageData.length;
    NSUInteger sizeOriginKB = sizeOrigin / 1000;
    
    if (sizeOriginKB <= maxSize) {
        return finallImageData;
    }
    
    //获取原图片宽高比
    CGFloat sourceImageAspectRatio = sourceImage.size.width/sourceImage.size.height;
    //先调整分辨率
    CGSize defaultSize = CGSizeMake(1024, 1024/sourceImageAspectRatio);
    UIImage *newImage = [self newSizeImage:defaultSize image:sourceImage];
    
    finallImageData = UIImageJPEGRepresentation(newImage,1.0);
    
    //保存压缩系数
    NSMutableArray *compressionQualityArr = [NSMutableArray array];
    CGFloat avg   = 1.0/250;
    CGFloat value = avg;
    for (int i = 250; i >= 1; i--) {
        value = i*avg;
        [compressionQualityArr addObject:@(value)];
    }
    
    /*
     调整大小
     说明：压缩系数数组compressionQualityArr是从大到小存储。
     */
    //思路：使用二分法搜索
    finallImageData = [self halfFuntion:compressionQualityArr image:newImage sourceData:finallImageData maxSize:maxSize];
    //如果还是未能压缩到指定大小，则进行降分辨率
    while (finallImageData.length == 0) {
        //每次降100分辨率
        CGFloat reduceWidth = 100.0;
        CGFloat reduceHeight = 100.0/sourceImageAspectRatio;
        if (defaultSize.width-reduceWidth <= 0 || defaultSize.height-reduceHeight <= 0) {
            break;
        }
        defaultSize = CGSizeMake(defaultSize.width-reduceWidth, defaultSize.height-reduceHeight);
        UIImage *image = [self newSizeImage:defaultSize
                                      image:[UIImage imageWithData:UIImageJPEGRepresentation(newImage,[[compressionQualityArr lastObject] floatValue])]];
        finallImageData = [self halfFuntion:compressionQualityArr image:image sourceData:UIImageJPEGRepresentation(image,1.0) maxSize:maxSize];
    }
    return finallImageData;
}
#pragma mark 二分法
+(NSData *)halfFuntion:(NSArray *)arr image:(UIImage *)image sourceData:(NSData *)finallImageData maxSize:(NSInteger)maxSize {
    NSData *tempData = [NSData data];
    NSUInteger start = 0;
    NSUInteger end = arr.count - 1;
    NSUInteger index = 0;
    
    NSUInteger difference = NSIntegerMax;
    while(start <= end) {
        index = start + (end - start)/2;
        
        finallImageData = UIImageJPEGRepresentation(image,[arr[index] floatValue]);
        
        NSUInteger sizeOrigin = finallImageData.length;
        NSUInteger sizeOriginKB = sizeOrigin / 1024;
        NSLog(@"当前降到的质量：%ld", (unsigned long)sizeOriginKB);
        NSLog(@"\nstart：%zd\nend：%zd\nindex：%zd\n压缩系数：%lf", start, end, (unsigned long)index, [arr[index] floatValue]);
        
        if (sizeOriginKB > maxSize) {
            start = index + 1;
        } else if (sizeOriginKB < maxSize) {
            if (maxSize-sizeOriginKB < difference) {
                difference = maxSize-sizeOriginKB;
                tempData = finallImageData;
            }
            if (index<=0) {
                break;
            }
            end = index - 1;
        } else {
            break;
        }
    }
    return tempData;
}
+(CGSize)get_ImageCompressionProportion:(UIImage *)image{
CGSize size = image.size;

CGFloat HBL = ScreenHeight / size.height;
CGFloat WBL = ScreenWidth / size.width;
if (size.width <= ScreenWidth && size.height <= ScreenHeight) {
return size;
}
else if (size.width > ScreenWidth && size.height <= ScreenHeight) {
size.width = ScreenWidth;
size.height = size.height * WBL;
NSString * str = [NSString stringWithFormat:@"%.0f",size.height];
size.height = [str floatValue];
}else if (size.height > ScreenHeight && size.width <= ScreenWidth) {
size.height = ScreenHeight;
size.width = size.width * HBL;
NSString * str = [NSString stringWithFormat:@"%.0f",size.width];
size.width = [str floatValue];
}else if (size.height > ScreenHeight && size.width > ScreenWidth) {
if (HBL < WBL) {
size.height = ScreenHeight;
size.width = size.width * HBL;
NSString * str = [NSString stringWithFormat:@"%.0f",size.width];
size.width = [str floatValue];
}else{
size.width = ScreenWidth;
size.height = size.height * WBL;
NSString * str = [NSString stringWithFormat:@"%.0f",size.height];
size.height = [str floatValue];
}
}
    return size;
}
+(void)deletPhotoWithPath:(NSString*)path{
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
    }
}

+(BOOL)isCurrentLanguageEn
{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    if ([currentLanguage isEqualToString:@"en"])
    {
        return YES;
    }
    
    return NO;
}
+(BOOL)isCurrentLanguageJP
{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    NSArray *arr = [currentLanguage componentsSeparatedByString:@"-"];
    NSString *lstr;
    if (arr.count > 0) {
        lstr = [arr firstObject];
    }
    if ([lstr isEqualToString:@"ja"])
    {
        return YES;
    }
    
    return NO;
}
+(BOOL)checkEmail:(NSString*)emailStr{
    
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
          
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
          
    return [emailTest evaluateWithObject:emailStr];
    
}
+ (UIImage *)image:(UIImage*)image byScalingToSize:(CGSize)targetSize {

UIImage *sourceImage = image;

UIImage *newImage = nil;

UIGraphicsBeginImageContext(targetSize);
   
CGRect thumbnailRect = CGRectZero;

thumbnailRect.origin = CGPointZero;

thumbnailRect.size.width=targetSize.width;

thumbnailRect.size.height = targetSize.height;

[sourceImage drawInRect:thumbnailRect];

newImage = UIGraphicsGetImageFromCurrentImageContext();

UIGraphicsEndImageContext();

return newImage ;
}
+ (UIImage *)imageWithInverse:(UIImage*)img {

    CGImageRef imageRef = img.CGImage;
    int width = (int)CGImageGetWidth(imageRef);
    int height = (int)CGImageGetHeight(imageRef);

    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponet = 8;

    uint32_t *pixels = (uint32_t *)calloc(height * width,4);
    if (pixels == NULL) {
        return nil;
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponet, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);

    uint32_t color = 0;
    for (int i = 0; i < height; i++) {

        for (int j = 0; j < width; j++) {

            color = *(pixels + i * width + j);
            if (A(color) < 200 || (R(color)+G(color)+B(color))/3.0 >= 200) {
                *(pixels + i * width + j) = 0xFF000000;
            }
            else {
                *(pixels + i * width + j) = 0x00FFFFFF;//(255-R(color)) + ((255-G(color))<<8) + ((255-B(color))<<16) + ((255-A(color))<<24);
            }
        }
    }

    NSUInteger dataLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixels, dataLength, NULL);
    CGImageRef mirrorRef = CGImageCreate(width, height,
                                         8,
                                         32,
                                         width*4 ,
                                         colorSpace,
                                         kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big,
                                         provider,
                                         NULL, NO,
                                         kCGRenderingIntentDefault);

    UIImage *image = [UIImage imageWithCGImage:mirrorRef scale:1.0f orientation:UIImageOrientationDown];
    CFRelease(mirrorRef);
    CFRelease(colorSpace);
    CFRelease(provider);
    CFRelease(context);
    return image;
            
}
+ (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 33 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    return newPic;
}
+(UIImage*)rotateWithImg:(UIImage*)dhImg rotaion:(UIImageOrientation)orient
{
    CGRect             bnds = CGRectZero;
    UIImage*           copy = nil;
    CGContextRef       ctxt = nil;
    CGImageRef         imag = dhImg.CGImage;
    CGRect             rect = CGRectZero;
    CGAffineTransform  tran = CGAffineTransformIdentity;

    rect.size.width  = CGImageGetWidth(imag);
    rect.size.height = CGImageGetHeight(imag);
    
    bnds = rect;
     switch (orient)
    {
          case UIImageOrientationUp:
                  // would get you an exact copy of the original
//                  [assert](false);
                   return  nil;
        case UIImageOrientationUpMirrored:
                tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
                tran = CGAffineTransformScale(tran, -1.0, 1.0);
                break;

        case UIImageOrientationDown:
                tran = CGAffineTransformMakeTranslation(rect.size.width,rect.size.height);
                tran = CGAffineTransformRotate(tran, M_PI);
                break;

        case UIImageOrientationDownMirrored:
                tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
                tran = CGAffineTransformScale(tran, 1.0, -1.0);
                break;
        case UIImageOrientationLeft:
                bnds = swapWidthAndHeight(bnds);
                tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
                tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
                break;

        case UIImageOrientationLeftMirrored:
                bnds = swapWidthAndHeight(bnds);
                tran = CGAffineTransformMakeTranslation(rect.size.height,rect.size.width);
                tran = CGAffineTransformScale(tran, -1.0, 1.0);
                tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
                break;

        case UIImageOrientationRight:
                bnds = swapWidthAndHeight(bnds);
                tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
                tran = CGAffineTransformRotate(tran, M_PI / 2.0);
                break;

        case UIImageOrientationRightMirrored:
                 bnds = swapWidthAndHeight(bnds);
                 tran = CGAffineTransformMakeScale(-1.0, 1.0);
                 tran = CGAffineTransformRotate(tran, M_PI / 2.0);
                break;

      default:
      // orientation value supplied is invalid
//      [assert](false);
      return  nil;

    }

    UIGraphicsBeginImageContext(bnds.size);
    ctxt = UIGraphicsGetCurrentContext();
    switch (orient)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
        CGContextScaleCTM(ctxt, -1.0, 1.0);
        CGContextTranslateCTM(ctxt, -rect.size.height, 0.0);
        break;
        
        default:
        CGContextScaleCTM(ctxt, 1.0, -1.0);
        CGContextTranslateCTM(ctxt, 0.0, -rect.size.height);
        break;
    }
  
    CGContextConcatCTM(ctxt, tran);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, imag);
    
    copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return copy;

}
#pragma mark - 判断用户设备是iPhone, iPad 还是iPod touch
+ (BOOL)getIsIpad
{
    NSString *deviceType = [UIDevice currentDevice].model;
    
    if([deviceType isEqualToString:@"iPhone"]) {
        //iPhone
        return NO;
    }
    else if([deviceType isEqualToString:@"iPod touch"]) {
        //iPod Touch
        return NO;
    }
    else if([deviceType isEqualToString:@"iPad"]) {
        //iPad
        return YES;
    }
    return NO;
    
    //这两个防范判断不准，不要用
    //#define is_iPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    //
    //#define is_iPad (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
}
+ (UIImage*)changeImgColorWithImg:(UIImage*)image andColor:(UIColor*)color{
CGRect rect = CGRectMake(0,0, image.size.width, image.size.height);
UIGraphicsBeginImageContext(rect.size);
CGContextRef context = UIGraphicsGetCurrentContext();
CGContextClipToMask(context, rect, image.CGImage);
CGContextSetFillColorWithColor(context, [color CGColor]);
//    CGContextSetStrokeColorWithColor(context, [color CGColor]);
CGContextFillRect(context, rect);
UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();
UIImage *flippedImage = [UIImage imageWithCGImage:img.CGImage scale:1.0 orientation: UIImageOrientationDownMirrored];
return  flippedImage;
    
}
+ (UIImage *)inverColorImage:(UIImage *)image {
    CGImageRef cgimage = image.CGImage;
    size_t width = CGImageGetWidth(cgimage);
    size_t height = CGImageGetHeight(cgimage);
    
    // 取图片首地址
    unsigned char *data = calloc(width * height * 4, sizeof(unsigned char));
    size_t bitsPerComponent = 8; // r g b a 每个component bits数目
    size_t bytesPerRow = width * 4; // 一张图片每行字节数目 (每个像素点包含r g b a 四个字节)
    // 创建rgb颜色空间
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgimage);

    for (size_t i = 0; i < height; i++) {
        for (size_t j = 0; j < width; j++) {
            size_t pixelIndex = i * width * 4 + j * 4;
            unsigned char red = data[pixelIndex];
            unsigned char green = data[pixelIndex + 1];
            unsigned char blue = data[pixelIndex + 2];
            // 修改颜色
            data[pixelIndex] = 255 - red;
            data[pixelIndex + 1] = 255 - green;
            data[pixelIndex + 2] = 255 - blue;

        }
    }
    cgimage = CGBitmapContextCreateImage(context);
    return [UIImage imageWithCGImage:cgimage];
}
+(UIColor*)getColorWithType:(NSString*)type{
    
    if ([type isEqualToString:@"1"]) {
        return [UIColor redColor];
    }else if ([type isEqualToString:@"2"]){
         return [UIColor blueColor];
    }else if ([type isEqualToString:@"3"]){
         return [UIColor yellowColor];
    }else if ([type isEqualToString:@"4"]){
         return [UIColor greenColor];
    }else if ([type isEqualToString:@"5"]){
        return [UIColor whiteColor];
    }
    
    return [UIColor blackColor];
}
+ (UIImage*)grayscale:(UIImage*)anImage type:(int)type {
    
    CGImageRef imageRef = anImage.CGImage;
    
    size_t width  = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    
    bool shouldInterpolate = CGImageGetShouldInterpolate(imageRef);
    
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(imageRef);
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    
    UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);
    
    NSUInteger  x, y;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            UInt8 *tmp;
            tmp = buffer + y * bytesPerRow + x * 4;
            
            UInt8 red,green,blue;
            red = *(tmp + 0);
            green = *(tmp + 1);
            blue = *(tmp + 2);
            
            UInt8 brightness;
            switch (type) {
                   
                case 1:
                    brightness = (77 * red + 28 * green + 151 * blue) / 256;
                    *(tmp + 0) = brightness;
                    *(tmp + 1) = brightness;
                    *(tmp + 2) = brightness;
                    break;
                   
                case 2:
                    *(tmp + 0) = red;
                    *(tmp + 1) = green * 0.7;
                    *(tmp + 2) = blue * 0.4;
                    break;
                case 3:
                    *(tmp + 0) = 255 - red;
                    *(tmp + 1) = 255 - green;
                    *(tmp + 2) = 255 - blue;
                    break;
                default:
                    *(tmp + 0) = red;
                    *(tmp + 1) = green;
                    *(tmp + 2) = blue;
                    break;
            }
        }
    }
    
    
    CFDataRef effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
    
    CGDataProviderRef effectedDataProvider =CGDataProviderCreateWithCFData(effectedData);
    
    CGImageRef effectedCgImage = CGImageCreate(
                                               width, height,
                                               bitsPerComponent, bitsPerPixel, bytesPerRow,
                                               colorSpace, bitmapInfo, effectedDataProvider,
                                               NULL, shouldInterpolate, intent);
    
    UIImage *effectedImage = [[UIImage alloc] initWithCGImage:effectedCgImage];
    
    CGImageRelease(effectedCgImage);
    
    CFRelease(effectedDataProvider);
    
    CFRelease(effectedData);
    
    CFRelease(data);
    
    return effectedImage;
    
}
+ (NSDictionary*)getPrinterConfig{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"print_param_config.jsonc" ofType:nil];
    
      NSData *data = [NSData dataWithContentsOfFile:path];
      NSError *error;
      NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
      if (error) {
          NSLog(@"%@",error);
      }
    return dict;
}
+ (NSDictionary *)readInterfaceValue {
    //文件路径
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"print_param_config.jsonc" ofType:nil];
    NSArray *subfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[Product configJsonFolder] error:nil];
    if (subfiles.count > 0 ) {
        NSString *fileName = [subfiles firstObject];
        NSArray *arr = [fileName componentsSeparatedByString:@"-"];
        if (arr.count > 2) {
            NSInteger code = [arr[1] integerValue];
            if (code > 1) {
//         使用 下载的最新的config文件
                NSString *path2 = [subfiles firstObject];
                path = [[Product configJsonFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",path2]];
                
            }
        }
        
    }
    
    //带有注释的json文本
    NSString  *allStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSScanner *myScanner = [NSScanner scannerWithString:allStr];//扫描
    NSString *annotStr = nil;
    NSString *jsonStr = allStr;
    while ([myScanner isAtEnd] == NO) {
        //开始扫描
        [myScanner scanUpToString:@"//" intoString:NULL];
        [myScanner scanUpToString:@"\n" intoString:&annotStr];
        //将结果替换
        //注意 这样写jsonStr =  [jsonStr stringByReplacingOccurrencesOfString:annotStr withString:@""]; 无法区分json中的”// 事项“和”// 事项备注“ 两个注释
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@\n", annotStr] withString:@"\n"];
    }
    if (jsonStr == nil) {return nil;}
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if(error) {
        NSLog(@"json解析失败：%@",error);
        return nil;
    }
    return resultDic;
}
/**
 *  压缩图片
 *  image:将要压缩的图片   size：压缩后的尺寸
 */
+(UIImage*)OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
 
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];

    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return scaledImage;   //返回的就是已经改变的图片
}
// 画背景
+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [image drawInRect:rect];
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextFillRect(context, rect);
    
    UIImage*newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage *newImage2 = [dhServerApi addImage:image toImage:newImage];
    
    return newImage2;
}
// 合成图片
+ (UIImage *)addImage:(UIImage *)image1 toImage:(UIImage *)image2 {
    UIGraphicsBeginImageContext(image1.size);
    
    // Draw image2  哪个图片在最下面先画谁，在这里有先后顺序
    [image2 drawInRect:CGRectMake(0, 0, image2.size.width, image2.size.height)];
    
    // Draw image1
    [image1 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
    
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
}
@end
