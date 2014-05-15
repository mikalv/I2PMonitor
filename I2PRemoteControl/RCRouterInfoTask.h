//
//  RCRouterBasicInfoTask
//  I2PRemoteControl
//
//  Created by miximka on 13/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCTask.h"

@class RCRouterInfo;

typedef void(^RCRouterInfoTaskCompletionHandler)(RCRouterInfo *routerInfo, NSError *error);

//=========================================================================
@interface RCRouterInfoTask : RCTask
//=========================================================================

@property (nonatomic, readonly) RCRouterInfo *routerInfo;
@property (nonatomic, copy) RCRouterInfoTaskCompletionHandler completionHandler;

//=========================================================================
@end
//=========================================================================