//
//  ServerConfig.h
//  HY012_iOS
//
//  Created by Arvin on 2018/8/10.
//  Copyright © 2018年 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerConfig : NSObject

@property (class, readonly, strong) ServerConfig *defaultConfig;

@property (nonatomic,strong) NSString *sn;
@property (nonatomic,strong) NSString *sys_type;
@property (nonatomic,strong) NSString *lang;
@property (nonatomic,strong) NSString *token;

//每次获取可能都不一样
- (NSMutableDictionary *)configParam;

-(NSString*)createUuid;

@end
