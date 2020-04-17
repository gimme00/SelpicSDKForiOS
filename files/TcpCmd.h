//
//  TcpCmd.h
//  PenMaJi
//
//  Created by Arvin on 2019/8/9.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,TCPCMDStatus) {
    
    CMDStatusNone = 0,
    CMDStatusIng,
    CMDStatusSuccess,
    CMDStatusFailed,
    CMDStatusOverTime,
    CMDStatusCancel
};


@interface TcpCmd : NSObject

@property (nonatomic,strong) NSData *cmdData;

@property (nonatomic,assign) TCPCMDStatus status;

@property (nonatomic,strong) NSError *error;

@property (nonatomic,strong) NSString *tag;

@end

@interface BaseCmd : TcpCmd

@property (nonatomic,assign) char start;
@property (nonatomic,assign) uint8_t cmdId;

@end

@interface RequestCmd : BaseCmd

@property (nonatomic,strong) NSDictionary *param;

@property (nonatomic,strong) NSDate *sendDate;
@property (nonatomic,assign) NSInteger maxRepeatTimes;
@property (nonatomic,assign) NSInteger alreadyRepeatTimes;
@property (nonatomic,copy) void (^response)(id,NSError *);
@property (nonatomic,copy) void (^didSend)(id,NSData *);

@end

@interface ResponseCmd : BaseCmd

@property (nonatomic,assign) int code;
@property (nonatomic,strong) NSDictionary *result;

@end
