//
//  HBS_Tools.m
//  CommanApp
//
//  Created by cxq on 15/12/12.
//  Copyright © 2015年 cxq. All rights reserved.
//

#import "HBS_Tools.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import <sys/utsname.h>
#import <SystemConfiguration/CaptiveNetwork.h>

static MBProgressHUD *waitHub = nil;

@implementation HBS_Tools

+ (HBS_Tools *)shareInstance {
    
    static dispatch_once_t once;
    static HBS_Tools *ins = nil;
    
    dispatch_once(&once, ^{
        
        if (!ins) {
            ins = [[HBS_Tools alloc] init];
        }
    });
    
    return ins;
}

+ (NSString *)curDeviceTypeName {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *str1 = [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
//    NSString *str2 = [NSString stringWithCString:systemInfo.version
//                                        encoding:NSUTF8StringEncoding];
//    NSString *str3 = [NSString stringWithCString:systemInfo.release
//                                        encoding:NSUTF8StringEncoding];
//    NSString *str4 = [NSString stringWithCString:systemInfo.nodename
//                                        encoding:NSUTF8StringEncoding];
//    NSString *str5 = [NSString stringWithCString:systemInfo.sysname
//                                        encoding:NSUTF8StringEncoding];
    
    return str1;
}

/**
 *  显示弹出框,不一定是UIAlertView，也可以是自定义的弹出框
 *
 *  @param title       弹出框的标题，参数如果为nil，则显示@"提示"，如果为@“”，则不显示标题
 *  @param message     弹出框的内容
 */
+ (void)msgBoxWithTitle:(NSString *)title message:(NSString *)message {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title ? title : NSLocalizedString(@"dialog_sign", nil)
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"dialog_sure", nil),nil];
    [alertView show];
}

+ (void)showToast:(NSString *)text duration:(NSTimeInterval)duration {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = text;
    hud.mode = MBProgressHUDModeText;
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [hud show:YES];
        
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hide:YES];
    });
}

+ (void)showToast:(NSString *)text {
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = text;
    hud.mode = MBProgressHUDModeText;
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [hud show:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hide:YES];
    });
}

+ (void)showWaitBox:(NSString *)text {
    
    if (!waitHub) {
        waitHub = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
        waitHub.mode = MBProgressHUDModeIndeterminate;
        waitHub.removeFromSuperViewOnHide = YES;
    }
    
    waitHub.labelText = text;
    [[UIApplication sharedApplication].keyWindow addSubview:waitHub];
    [waitHub show:YES];
}

+ (void)hideWaitBox {
    
    [waitHub hide:YES];
    waitHub = nil;
}

/**
 *  计算字符串的size，单行显示
 *
 *  @param str      计算的字符串
 *  @param font     字符串显示的字体
 *  @param return   字符串的现实范围
 */
+ (CGSize)getStrSize:(NSString *)str font:(UIFont *)font {
    
    CGSize size = [str sizeWithAttributes:@{NSFontAttributeName: font}];
    return size;
}

/**
 *  计算字符串的size，可多行显示
 *
 *  @param str                  计算的字符串
 *  @param font                 字符串显示的字体
 *  @param containSize          字符串显示的区域,用MAXFLOAT来指定宽或高为可变
 *  @param return               字符串的现实范围
 */
+ (CGSize)getStrSize:(NSString *)str font:(UIFont *)font containSize:(CGSize)containSize {
    
    CGRect rect = [str boundingRectWithSize:containSize  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil];
    return rect.size;
}

/**
 *  获取App的uuid
 *
 *  @param return               当前的uuid
 */
+ (NSString *)getAppUUID {
    
    NSString *retStr = nil;
    
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    
    if (uuidRef) {
        
        retStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
    }
    
    return retStr;
}

/**
 *  生成一个富文本字符串
 *
 *  @param textInfoArray        一个个字符片段，eg: @[@{@"text":str1,@"font":font1,@"color":color1},@{@"text":str2,@"font":font2,@"color":color2}]
 
 *  @param return               返回组合的富文本
 */
+ (NSMutableAttributedString *)generateAttributeStringBy:(NSArray <NSDictionary *> *)textInfoArray {
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] init];
    for (NSDictionary *textInfo in textInfoArray) {
        
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:[textInfo objectForKey:@"text"] attributes:@{NSForegroundColorAttributeName:[textInfo objectForKey:@"color"],NSFontAttributeName:[textInfo objectForKey:@"font"]}];
        
        [attributeStr appendAttributedString:attr];
    }
    
    return attributeStr;
}

+ (void)filterTextLenth:(UITextField *)textField limit:(NSInteger)len {
    
    NSString *toBeString = textField.text;
    
    NSString *lang = [[textField textInputMode] primaryLanguage]; // 键盘输入模式
    
    if ([lang isEqualToString:@"zh-Hans"] || [lang isEqualToString:@"zh-Hant"] || [lang isEqualToString: @"ja-JP"]) { // 简体中文输入，包括简体拼音，健体五笔，简体手写
        UITextRange *selectedRange = [textField markedTextRange];
        //获取高亮部分
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
        if (!position) {
            if (toBeString.length > len) {
                textField.text = [toBeString substringToIndex:len];
            }
        }
        // 有高亮选择的字符串，则暂不对文字进行统计和限制
        else{
            
        }
    }
    // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
    else{
        if (toBeString.length > len) {
            textField.text = [toBeString substringToIndex:len];
        }
    }
}


//AttributedString 切割
+ (NSMutableAttributedString *)getAttributeStringWith:(NSArray *)textInfoArray {
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] init];
    for (NSDictionary *textInfo in textInfoArray) {
        
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:[textInfo objectForKey:@"text"] attributes:@{NSForegroundColorAttributeName:[textInfo objectForKey:@"color"],NSFontAttributeName:[textInfo objectForKey:@"font"]}];
        
        [attributeStr appendAttributedString:attr];
    }
    
    return attributeStr;
}

+ (UIImage *)getThumbnailImage:(NSString *)videoURL
{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    
    NSError *error = nil;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:NULL error:&error];
    
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    
    CGImageRelease(image);
    
    return thumb;
}

+ (NSString *)formatStringBySeconds:(long)seconds {
    
    int h = (int)(seconds / 3600);
    int m = (seconds % 3600)/60;
    int s = seconds%60;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",h,m,s];
}

+ (NSString *)dateName {
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.timeZone = [NSTimeZone localTimeZone];
    [format setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    
    return [format stringFromDate:[NSDate date]];
}

+ (BOOL)deviceIsIphoneX {
    
    if ([UIScreen mainScreen].bounds.size.width == 812 || [UIScreen mainScreen].bounds.size.height == 812) {
        return YES;
    }
    
    return NO;
}


+ (NSString *)ssid
{
    
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
@end
