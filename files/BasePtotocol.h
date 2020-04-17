//
//  BasePtotocol.h
//  PenMaJi
//
//  Created by Arvin on 2019/8/9.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RequestCmd;
@class ResponseCmd;

@protocol BasePtotocol <NSObject>

- (NSData *)constructDataWithCmd:(RequestCmd *)reqCmd otherInfo:(id)info;

- (NSArray <ResponseCmd *> *)receiveCmdWithData:(NSData *)data otherInfo:(id)info;

@end

