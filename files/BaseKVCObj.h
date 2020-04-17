//
//  BaseKVCObj.h
//  HBSDrone
//
//  Created by Arvin on 2018/9/3.
//  Copyright © 2018年 钟发军. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseKVCObj : NSObject

/**
 更新属性
 
 @param info 属性字典
 @return YES对象属性有变化 NO对象属性没变化
 */
- (BOOL)setPropertysWithDictionary:(NSDictionary *)info;

@end
