//
//  UIImage+CECategory.m
//  CommanApp
//
//  Created by cxq on 15/12/12.
//  Copyright © 2015年 cxq. All rights reserved.
//

#import "UIImage+CECategory.h"
#import <AVFoundation/AVFoundation.h>

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

@implementation UIImage (CECategory)

+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    //1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    //2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return [UIImage imageWithCGImage:scaledImage];
}

+ (UIImage *)safeScaleImage:(CIImage *)outputImage size:(CGSize)size {
    
    CGRect extent = CGRectIntegral(outputImage.extent);
//    CGFloat t_scale = MIN(size.width/extent.size.width, size.height/extent.size.height);
    CGFloat t_scale_x = size.width/extent.size.width;
    CGFloat t_scale_y = size.height/extent.size.height;
    //1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * t_scale_x;
    size_t height = CGRectGetHeight(extent) * t_scale_y;
    //创建一个DeviceGray颜色空间
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    //CGBitmapContextCreate(void * _Nullable data, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow, CGColorSpaceRef  _Nullable space, uint32_t bitmapInfo)
    //width：图片宽度像素
    //height：图片高度像素
    //bitsPerComponent：每个颜色的比特值，例如在rgba-32模式下为8
    //bitmapInfo：指定的位图应该包含一个alpha通道。
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CIContext *context = [CIContext contextWithOptions:nil];
    //创建CoreGraphics image
    CGImageRef bitmapImage = [context createCGImage:outputImage fromRect:extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, t_scale_x, t_scale_y);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    //2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    //清晰的二维码图片
    UIImage *image = [UIImage imageWithCGImage:scaledImage];
    
    CGImageRelease(bitmapImage);
    CGContextRelease(bitmapRef);
    
    return image;
}

- (UIImage *)imageBlackAndWhiteColor {
    
    CGImageRef imageRef = self.CGImage;
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
            if ((R(color)+G(color)+B(color))/3.0 > 180) {
                *(pixels + i * width + j) = 0xFFFFFFFF;
            }
//            else {
//                *(pixels + i * width + j) = 0xFFFFFFFF;
//            }
        }
    }
    
    NSUInteger dataLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixels, dataLength, NULL);
    CGImageRef mirrorRef = CGImageCreate(width, height,
                                         8,
                                         32,
                                         width*4 ,
                                         colorSpace,
                                         kCGImageAlphaNone|kCGImageAlphaPremultipliedLast,
                                         provider,
                                         NULL, NO,
                                         kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:mirrorRef scale:self.scale orientation:self.imageOrientation];
    CFRelease(mirrorRef);
    CFRelease(colorSpace);
    CFRelease(provider);
    CFRelease(context);
    return image;
}

- (UIImage *)imageWithInverse {
    
    CGImageRef imageRef = self.CGImage;
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
//                dh---color 颜色改
                
//                NSString *typeStr = [dhServerApi getStrWithKey:@"dhInkColor"];
//                if ([typeStr isEqualToString:@"1"]) {
//                     *(pixels + i * width + j) = 0xFF0000FF;
//                }else if ([typeStr isEqualToString:@"2"]){
//                     *(pixels + i * width + j) = 0xFFFF0000;
//                }else if ([typeStr isEqualToString:@"3"]){
//                     *(pixels + i * width + j) = 0xFFFFFF00;
//                }else if ([typeStr isEqualToString:@"4"]){
//                     *(pixels + i * width + j) = 0xFF008000;
//                }else if ([typeStr isEqualToString:@"5"]){
//                     *(pixels + i * width + j) = 0xFFFFFFFF;
//                }else{
//                     *(pixels + i * width + j) = 0xFF000000;
//                }
                
            }
            else {
                *(pixels + i * width + j) = 0x00FFFFFF;//(255-R(color)) + ((255-G(color))<<8) + ((255-B(color))<<16) + ((255-A(color))<<24);
//                *(pixels + i * width + j) = 0x00FF00FF;
            }

//            color = *(pixels + i * width + j);
//            if ((R(color)+G(color)+B(color))/3.0 < 120) {
//                *(pixels + i * width + j) = 0xFFFFFFFF;
//            }
//            else {
//                *(pixels + i * width + j) = 0xFF000000;
//            }
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
    
    UIImage *image = [UIImage imageWithCGImage:mirrorRef scale:self.scale orientation:self.imageOrientation];
    CFRelease(mirrorRef);
    CFRelease(colorSpace);
    CFRelease(provider);
    CFRelease(context);
    return image;
}

- (UIImage *)imageWithRotate:(int)rotate {
    
    if (rotate == 0) {
        return self;
    }
    
    CGImageRef imageRef = self.CGImage;
    int width = (int)CGImageGetWidth(imageRef);
    int height = (int)CGImageGetHeight(imageRef);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponet = 8;
    
    uint32_t *pixels = (uint32_t *)calloc(height * width,4);
    if (pixels == NULL) {
        return nil;
    }
//    memset(pixels, 0xFFFFFFFF, height*width*4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponet, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    if (rotate == 1) {
        
        uint32_t *tmp = (uint32_t *)calloc(height * width,4);
        
        memcpy(tmp, pixels, height * width * 4);
        
        for (int i = 0; i < width; i++) {
            
            for (int j = 0; j < height; j++) {
                
                *(pixels + i*height +j) = *(tmp + (height - j - 1) * width + i);
            }
        }
        
        free(tmp);
        
        int w = width;
        width = height;
        height = w;
    }
    else if (rotate == 2) {
        
        uint32_t *tmp = (uint32_t *)calloc(height * width,4);
        memcpy(tmp, pixels, height * width * 4);
        
        for (int i = 0; i < height; i++) {
            
            for (int j = 0; j < width; j++) {
                
                *(pixels + i*width +j) = *(tmp + (height - i - 1) * width + width - 1 - j);
            }
        }
        
        free(tmp);
    }
    else if (rotate == 3) {
        
        uint32_t *tmp = (uint32_t *)calloc(height * width,4);
        memcpy(tmp, pixels, height * width * 4);
        
        for (int i = 0; i < width; i++) {
            
            for (int j = 0; j < height; j++) {
                
                *(pixels + i*height +j) = *(tmp + j * width + width - i - 1);
            }
        }
        
        free(tmp);
        
        int w = width;
        width = height;
        height = w;
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
    
    UIImage *image = [UIImage imageWithCGImage:mirrorRef scale:self.scale orientation:self.imageOrientation];
    CFRelease(mirrorRef);
    CFRelease(colorSpace);
    CFRelease(provider);
    CFRelease(context);
    return image;
}

- (UIImage *)imageWithMirror:(int)type {
    
    CGImageRef imageRef = self.CGImage;
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
    int end = width - 1;
    
    for (int i = 0; i < height; i++) {
        
        end = width - 1;
        
        for (int start = 0; start < end; start++,end--) {
            color = *(pixels + i * width + start);
            *(pixels + i * width + start) = *(pixels + i * width + end);
            *(pixels + i * width + end) = color;
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

    UIImage *image = [UIImage imageWithCGImage:mirrorRef scale:self.scale orientation:self.imageOrientation];
    CFRelease(mirrorRef);
    CFRelease(colorSpace);
    CFRelease(provider);
    CFRelease(context);
    return image;
}

- (UIImage *)safeScaleImageBySize:(CGSize)size {
    
    CIImage *outputImage = self.CIImage;
    if (!outputImage) {
        outputImage = [[CIImage alloc] initWithImage:self];
    }
    
    CGRect extent = CGRectIntegral(outputImage.extent);
    CGFloat t_scale = MIN(size.width/extent.size.width, size.height/extent.size.height);
    
    //1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * t_scale;
    size_t height = CGRectGetHeight(extent) * t_scale;
    //创建一个DeviceGray颜色空间
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    //CGBitmapContextCreate(void * _Nullable data, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow, CGColorSpaceRef  _Nullable space, uint32_t bitmapInfo)
    //width：图片宽度像素
    //height：图片高度像素
    //bitsPerComponent：每个颜色的比特值，例如在rgba-32模式下为8
    //bitmapInfo：指定的位图应该包含一个alpha通道。
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CIContext *context = [CIContext contextWithOptions:nil];
    //创建CoreGraphics image
    CGImageRef bitmapImage = [context createCGImage:outputImage fromRect:extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, t_scale, t_scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    //2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    //清晰的二维码图片
    UIImage *image = [UIImage imageWithCGImage:scaledImage];
    
    CGImageRelease(bitmapImage);
    CGContextRelease(bitmapRef);
    
    return image;
}

- (UIImage*)scaleToSize:(CGSize)size
{
    //        UIGraphicsBeginImageContext(size);
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    
    // 绘制改变大小的图片
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

- (UIImage *)shotImageWithSize:(CGSize)size {
    
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    
    float verticalRadio = size.height*1.0/height;
    float horizontalRadio = size.width*1.0/width;
    
    float radio = 1;
    if(verticalRadio>1 && horizontalRadio>1)
    {
        radio = verticalRadio > horizontalRadio ? verticalRadio : horizontalRadio;
    }
    else
    {
        radio = verticalRadio < horizontalRadio ? horizontalRadio : verticalRadio;
    }
    
    width = width*radio;
    height = height*radio;
    
    int xPos = (size.width - width)/2;
    int yPos = (size.height-height)/2;
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    //    UIGraphicsBeginImageContext(size);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    // 绘制改变大小的图片
    [self drawInRect:CGRectMake(xPos, yPos, width, height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}


-(UIImage*)scaleToSizeAutoWH:(CGSize)size
{
    
    CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    
    float verticalRadio = size.height*1.0/height;
    float horizontalRadio = size.width*1.0/width;
    
    float radio = 1;
    if(verticalRadio>1 && horizontalRadio>1)
    {
        radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
    }
    else
    {
        radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
    }
    
    width = width*radio;
    height = height*radio;
    
    int xPos = (size.width - width)/2;
    int yPos = (size.height-height)/2;
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    //    UIGraphicsBeginImageContext(size);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    // 绘制改变大小的图片
    [self drawInRect:CGRectMake(xPos, yPos, width, height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

-(UIImage*)scaleToSizeForCircleCut:(CGSize)size
{
    return [[self cutToCubic] scaleToSize:size];
}


-(UIImage*)cutToCubic
{
    
    CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    
    
    int x,y,w,h;
    
    w = MIN(width, height);
    h = w;
    
    x = (width - w)/2.0f;
    y = (height - h)/2.0f;
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    //    UIGraphicsBeginImageContext(size);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 0.0);
    
    // 绘制改变大小的图片
    [self drawInRect:CGRectMake(x, y, width, height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}



- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees
{
    
    CGFloat width = self.size.width;//CGImageGetWidth(self.CGImage);
    CGFloat height = self.size.height;//CGImageGetHeight(self.CGImage);
    
    CGSize rotatedSize;
    
    rotatedSize.width = width;
    rotatedSize.height = height;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    CGContextRotateCTM(bitmap, degrees * M_PI / 180);
    CGContextRotateCTM(bitmap, M_PI);
    CGContextScaleCTM(bitmap, -1.0, 1.0);
    CGContextDrawImage(bitmap, CGRectMake(-rotatedSize.width/2, -rotatedSize.height/2, rotatedSize.width, rotatedSize.height), self.CGImage);
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (BOOL)compositionVideoWithImgs:(NSArray *)imageArray videoPath:(NSString *)moviePath complete:(void (^)(NSError *error))complete {
    
    CGSize size =CGSizeMake(320,480);
    NSError *error = nil;
    
    unlink([moviePath UTF8String]);
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:moviePath] fileType:AVFileTypeQuickTimeMovie error:&error];
    
    NSParameterAssert(videoWriter);
    
    if(error)
        NSLog(@"error =%@", [error localizedDescription]);
    
    //mov的格式设置 编码格式 宽度 高度
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,
                                  [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                  [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];
    
    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary*sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    //    AVAssetWriterInputPixelBufferAdaptor提供CVPixelBufferPool实例,
    //    可以使用分配像素缓冲区写入输出文件。使用提供的像素为缓冲池分配通常
    //    是更有效的比添加像素缓冲区分配使用一个单独的池
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if ([videoWriter canAddInput:writerInput])
    {
        NSLog(@"11111");
    }
    else
    {
        NSLog(@"22222");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete) {
                complete([NSError new]);
            }
        });
    }
    
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue =dispatch_queue_create("mediaInputQueue",NULL);
    
    int __block frame = 0;
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        
        while([writerInput isReadyForMoreMediaData])
        {@autoreleasepool{
            if(++frame >= [imageArray count]*1)
            {
                [writerInput markAsFinished];
                
                [videoWriter finishWritingWithCompletionHandler:^{
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (complete) {
                            complete(nil);
                        }
                    });
                }];
                
                break;
            }
            
            CVPixelBufferRef buffer = NULL;
            
            int idx = frame/10;
            
            NSLog(@"idx==%d",idx);
            
            buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[imageArray objectAtIndex:idx] size:size];
            
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,30)])//设置每秒钟播放图片的个数
                {
                    NSLog(@"FAIL");
                }
                else
                {
                    NSLog(@"OK");
                }
                
                CFRelease(buffer);
            }
        }}
    }];
    
    return YES;
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(NSString *)imagePath size:(CGSize)size
{
    UIImage *origin = [[UIImage imageWithContentsOfFile:imagePath] scaleToSize:size];
    
    CGImageRef image = origin.CGImage;
    
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    //    当你调用这个函数的时候，Quartz创建一个位图绘制环境，也就是位图上下文。当你向上下文中绘制信息时，Quartz把你要绘制的信息作为位图数据绘制到指定的内存块。一个新的位图上下文的像素格式由三个参数决定：每个组件的位数，颜色空间，alpha选项
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    
    //使用CGContextDrawImage绘制图片  这里设置不正确的话 会导致视频颠倒
    //    当通过CGContextDrawImage绘制图片到一个context中时，如果传入的是UIImage的CGImageRef，因为UIKit和CG坐标系y轴相反，所以图片绘制将会上下颠倒
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    // 释放色彩空间
    CGColorSpaceRelease(rgbColorSpace);
    // 释放context
    CGContextRelease(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
}

-(UIImage*)rotate:(UIImageOrientation)orient
{
    CGRect             bnds = CGRectZero;
    UIImage*           copy = nil;
    CGContextRef       ctxt = nil;
    CGImageRef         imag = self.CGImage;
    
    CGRect             rect = CGRectZero;
    CGAffineTransform  tran = CGAffineTransformIdentity;
    
    rect.size.width  = CGImageGetWidth(imag);
    rect.size.height = CGImageGetHeight(imag);
    
    bnds = rect;
    switch (orient)
    {
        case UIImageOrientationUp:
            // would get you an exact copy of the original
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
@end
