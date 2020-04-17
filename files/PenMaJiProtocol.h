//
//  PenMaJiProtocol.h
//  PenMaJi
//
//  Created by Arvin on 2019/8/9.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BasePtotocol.h"

extern uint16_t ModBusCRC16(uint8_t *cmd, int len);

@interface PenMaJiProtocol : NSObject <BasePtotocol>


@end
