//
//  UIImage+CECategory.h
//  CommanApp
//
//  Created by cxq on 15/12/12.
//  Copyright © 2015年 cxq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImage (CECategory)

+ (UIImage *)safeScaleImage:(CIImage *)image size:(CGSize)size;
- (UIImage *)imageWithMirror:(int)type;
- (UIImage *)imageWithRotate:(int)rotate;
- (UIImage *)imageBlackAndWhiteColor;
- (UIImage *)imageWithInverse;
- (UIImage *)safeScaleImageBySize:(CGSize)size;

- (UIImage*)rotate:(UIImageOrientation)orient;

- (UIImage*)scaleToSize:(CGSize)size;
- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees;
- (UIImage*)scaleToSizeForCircleCut:(CGSize)size;
- (UIImage*)scaleToSizeAutoWH:(CGSize)size;
- (UIImage *)shotImageWithSize:(CGSize)size;

+ (BOOL)compositionVideoWithImgs:(NSArray *)imageArray videoPath:(NSString *)moviePath complete:(void (^)(NSError *error))complete;

@end
