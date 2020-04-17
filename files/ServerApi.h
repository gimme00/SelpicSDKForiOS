//
//  ServerApi.h
//  HY012_iOS
//
//  Created by Arvin on 2018/6/5.
//  Copyright © 2018年 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerConfig.h"

enum {//AppErrorCode
    
    CodeSuccess = 0,//成功
    CodeTokenFailed = 100,//token校验失败或token过期，需重新登录
    CodeFailed = 300,//接口访问失败，失败问题描述通过msg返回
    
    CodeParamIsNil = -1,//请求参数为空
    CodeResponseIsNil = -2,//响应为空
    CodeResDataFormatError = -3,//相应格式错误
};

extern NSErrorDomain const HBSServerNetErrorDomain;

@interface ServerApi : NSObject

@property (nonatomic,strong,readonly) ServerConfig *config;

+ (ServerApi *)getServerApi;

- (void)initWithConfig:(ServerConfig *)config;

- (BOOL)isExsitReqWithUrl:(NSString *)url param:(NSDictionary *)param;

- (void)test;

- (void)getRequestWithUrl:(NSString *)url param:(NSDictionary *)param response:(void (^)(NSDictionary *result,NSError *error))response;

- (void)getDataRequestWithUrl:(NSString *)url param:(NSDictionary *)param response:(void (^)(NSData *result,NSError *error))response;

//标准POST请求
- (void)postRequestWithUrl:(NSString *)url param:(NSDictionary *)param response:(void (^)(NSDictionary *result,NSError *error))response;

/**
 表单请求 多个文件上传

 @param url 上传地址
 @param param 上传参数
 @param fieldArray 文件列表 key为name,filename,filedata,mime
 @param response 上传结果
 */
- (void)postRequestWithUrl:(NSString *)url
                 formParam:(NSDictionary *)param
                 formField:(NSArray <NSDictionary *> *)fieldArray
                  response:(void (^)(NSDictionary *result,NSError *error))response;

@end
