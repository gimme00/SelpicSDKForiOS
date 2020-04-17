//
//  NSObject_property.h
//  HY012_iOS
//
//  Created by Arvin on 2018/8/10.
//  Copyright © 2018年 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (property)

- (NSMutableDictionary *)get_propertyInfo;

- (NSString *)propertyType:(NSString *)propertyName;

- (BOOL)isExistProperty:(NSString *)property;

+ (NSMutableDictionary *)dictionaryParse:(NSDictionary *)dic;

+ (NSMutableArray *)arrayParse:(NSArray *)array;

@end
