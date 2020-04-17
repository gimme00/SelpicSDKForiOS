//
//  BaseKVCObj.m
//  HBSDrone
//
//  Created by Arvin on 2018/9/3.
//  Copyright © 2018年 钟发军. All rights reserved.
//

#import "BaseKVCObj.h"

@implementation BaseKVCObj
{
}

/**
 更新属性
 
 @param info 属性字典
 @return YES有更新 NO没更新
 */
- (BOOL)setPropertysWithDictionary:(NSDictionary *)info {
    
    /*经过测试，这个方法内部应该做会把NSNull变成nil*/
    [self setValuesForKeysWithDictionary:info];
    
    return YES;
}

#pragma mark -
/*变量为值类型，value对象会根据变量类型调用intValue,floatValue等方法，如果value对象没有这些方法，会crash.
 所以假如变量为int类型，字典的value可以是NSNumber或者NSString类型，如果是其它类型则需要添加类别方法intValue等*/
- (void)setValue:(id)value forKey:(NSString *)key {
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

- (void)setNilValueForKey:(NSString *)key {
    
}

- (id)valueForUndefinedKey:(NSString *)key {
    
    return [NSNull null];
}

@end
