//
//  ServerConfig.m
//  HY012_iOS
//
//  Created by Arvin on 2018/8/10.
//  Copyright © 2018年 Arvin. All rights reserved.
//

#import "ServerConfig.h"
#import <UIKit/UIKit.h>
#import "NSObject_property.h"

@implementation ServerConfig
{
}

+ (ServerConfig *)defaultConfig {
    static ServerConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (!config) {
            config = [[ServerConfig alloc] init];
        }
    });
    
    return config;
}

- (id)init {
    
    if (self = [super init]) {
        
        _sys_type = @"2";
        _lang = @"en";
//        _sn = @"BCC78ECB";//@"TESTSELPIC";
    }
    
    return self;
}

- (NSMutableDictionary *)configParam {
    
    NSMutableDictionary *propertyInfo = [self get_propertyInfo];
    
    return propertyInfo;
}

-(NSString*)createUuid
{
    char data[20];
    for (int x=0;x<20;data[x++] = (char)('A' + (arc4random_uniform(26))));
    
    return [[NSString alloc] initWithBytes:data length:20 encoding:NSUTF8StringEncoding];
}
@end
