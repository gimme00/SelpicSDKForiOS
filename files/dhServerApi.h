//
//  dhServerApi.h
//  PenMaJi
//
//  Created by 徐迪华 on 2019/11/20.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface dhServerApi : NSObject
+ (NSString *)GetSSID;
+(void)saveStrWithKey:(NSString*)key Value:(NSString*)value;
+(void)saveDictWithKey:(NSString*)key Dict:(NSDictionary*)dict;
+(void)saveArrWithKey:(NSString*)key Arr:(NSArray*)arr;
+(NSString*)getStrWithKey:(NSString*)key;
+(NSDictionary*)getDictWithKey:(NSString*)key;
+(NSArray*)getArrtWithKey:(NSString*)key;
+(CAShapeLayer*)getCornerViewWithLineColor:(UIColor*)color  View:(UIView*)view Corndi:(CGFloat)cordi;
+(void)lockScren;
+(void)unLockScren;
+(NSString *)hexStringFromString:(NSString *)string;//字符转16进制
+(NSString *)stringFromHexString:(NSString *)hexString;
+(BOOL)ValidateEmail:(NSString*)email;//邮箱正则判断
+(NSString*)getAppVersion;
+(void)jumpToAppStre;
+(NSString*)getTimerStr;
+(void)removeDataBase:(NSString*)name;
+ (UIImage *)newSizeImage:(CGSize)size image:(UIImage *)sourceImage;
+(NSData *)resetSizeOfImageData:(UIImage *)sourceImage maxSize:(NSInteger)maxSize;
+(CGSize)get_ImageCompressionProportion:(UIImage *)image;
+(void)deletPhotoWithPath:(NSString*)path;
+(BOOL)isCurrentLanguageEn;
+(BOOL)isCurrentLanguageJP;
+(BOOL)checkEmail:(NSString*)emailStr;
+ (UIImage *)image:(UIImage*)image byScalingToSize:(CGSize)targetSize;//修改image尺寸
+ (UIImage *)imageWithInverse:(UIImage*)img;//image 镜像
+ (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation;//旋转
+(UIImage*)rotateWithImg:(UIImage*)dhImg rotaion:(UIImageOrientation)orient;//镜像
+ (BOOL)getIsIpad;
+ (UIImage*)changeImgColorWithImg:(UIImage*)image andColor:(UIColor*)color;//
+ (UIImage *)inverColorImage:(UIImage *)image;
+(UIColor*)getColorWithType:(NSString*)type;
+ (UIImage*)grayscale:(UIImage*)anImage type:(int)type;
+ (NSDictionary*)getPrinterConfig;
+ (NSDictionary *)readInterfaceValue;
+(UIImage*)OriginImage:(UIImage *)image scaleToSize:(CGSize)size;
+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color;
+ (UIImage *)addImage:(UIImage *)image1 toImage:(UIImage *)image2;
@end

NS_ASSUME_NONNULL_END
