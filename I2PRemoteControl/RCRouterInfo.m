//
//  RCRouterInfo.m
//  I2PRemoteControl
//
//  Created by miximka on 13/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCRouterInfo.h"
#import "RCRouterApi.h"

//=========================================================================

@interface RCRouterInfo ()
@property (nonatomic) NSDate *estimatedStartupDate;
@end

//=========================================================================
@implementation RCRouterInfo
//=========================================================================

- (void)updateWithResponseDictionary:(NSDictionary *)response
{
    self.routerStatus = [response objectForKey:PARAM_KEY_ROUTER_STATUS];
    self.routerUptime = [[response objectForKey:PARAM_KEY_ROUTER_UPTIME] longValue];

    NSTimeInterval uptimeInSec = self.routerUptime / 1000;
    self.estimatedStartupDate = [[NSDate date] dateByAddingTimeInterval:-uptimeInSec];

    self.routerVersion = [response objectForKey:PARAM_KEY_ROUTER_VERSION];
}

//=========================================================================

- (NSTimeInterval)estimatedRouterUptime
{
    NSTimeInterval estimatedUptime = [[NSDate date] timeIntervalSinceDate:self.estimatedStartupDate];
    return estimatedUptime;
}

//=========================================================================

- (NSString *)description
{
    NSString *descr = [NSString stringWithFormat:@"Router status: %@, uptime: %lu, version: %@", self.routerStatus, self.routerUptime, self.routerVersion];
    return descr;
}

//=========================================================================
@end
//=========================================================================