//
//  HBS_Tools.h
//  CommanApp
//
//  Created by cxq on 15/12/12.
//  Copyright © 2015年 cxq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define IPHONEX_OFFSET  ([HBS_Tools deviceIsIphoneX] ? 44 : 0)

@interface HBS_Tools : NSObject

+ (NSString *)curDeviceTypeName;

/**
 *  显示弹出框,不一定是UIAlertView，也可以是自定义的弹出框
 *
 *  @param title       弹出框的标题，参数如果为nil，则显示@"提示"，如果为@“”，则不显示标题
 *  @param message     弹出框的内容
 *  return
 */
+ (void)msgBoxWithTitle:(NSString *)title message:(NSString *)message;

/**
 提示框，会自动消失

 @param text 提示框内容
 @param duration 存在时间s
 */
+ (void)showToast:(NSString *)text duration:(NSTimeInterval)duration;

/**
 提示框，0.5s后会自动消失

 @param text 提示框内容
 */
+ (void)showToast:(NSString *)text;

/**
 @param text 提示框内容
 */
+ (void)showWaitBox:(NSString *)text;

+ (void)hideWaitBox;

/**
 *  计算字符串的size，单行显示
 *
 *  @param str      计算的字符串
 *  @param font     字符串显示的字体
 *  return          字符串的现实范围
 */
+ (CGSize)getStrSize:(NSString *)str font:(UIFont *)font;

/**
 *  计算字符串的size，可多行显示
 *
 *  @param str                  计算的字符串
 *  @param font                 字符串显示的字体
 *  @param containSize          字符串显示的区域,用MAXFLOAT来指定宽或高为可变
 *  return                      字符串的现实范围
 */
+ (CGSize)getStrSize:(NSString *)str font:(UIFont *)font containSize:(CGSize)containSize;

/**
 *  获取App的uuid
 *
 *   return               当前的uuid
 */
+ (NSString *)getAppUUID;

/**
 *  生成一个富文本字符串
 *
 *  @param textInfoArray        一个个字符片段，eg: @[@{@"text":str1,@"font":font1,@"color":color1},@{@"text":str2,@"font":font2,@"color":color2}]
 *  return                      返回组合的富文本
 */
+ (NSMutableAttributedString *)generateAttributeStringBy:(NSArray <NSDictionary *> *)textInfoArray;

+ (void)filterTextLenth:(UITextField *)textField limit:(NSInteger)len;

+ (NSMutableAttributedString *)getAttributeStringWith:(NSArray *)textInfoArray;

+ (UIImage *)getThumbnailImage:(NSString *)videoURL;

+ (NSString *)formatStringBySeconds:(long)seconds;

+ (NSString *)dateName;

+ (BOOL)deviceIsIphoneX;

+ (NSString *)ssid;

@end
