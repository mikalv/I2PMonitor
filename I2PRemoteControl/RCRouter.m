//
//  RCRouter.m
//  I2PRemoteControl
//
//  Created by miximka on 12/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCRouter.h"
#import "RCRouterProxy.h"
#import "RCSessionConfig.h"
#import "RCRouterTaskManager.h"
#import "RCRouterEchoTask.h"
#import "RCRouterInfoTask.h"

//=========================================================================

#define CLIENT_API_VERSION 1
#define DEFAULT_PASSWORD @"itoopie"

NSString * const RCRouterDidUpdateRouterInfoNotification = @"RCRouterDidUpdateRouterInfoNotification";

typedef NS_ENUM(NSUInteger, RCPeriodicTaskType)
{
    kUpdateRouterInfoType,
};

//=========================================================================

@interface RCRouter ()
@property (nonatomic) RCRouterProxy *proxy;
@property (nonatomic) RCRouterTaskManager *taskManager;
@property (nonatomic) RCRouterInfoTask *routerInfoTask;
@end

//=========================================================================
@implementation RCRouter
//=========================================================================

- (instancetype)initWithSessionConfig:(RCSessionConfig *)sessionConfig
{
    self = [super init];
    if (self)
    {
        _sessionStatus = kIdle;
        _sessionConfig = sessionConfig;
    }
    return self;
}

//=========================================================================

- (RCRouterInfo *)routerInfo
{
    return self.routerInfoTask.routerInfo;
}

//=========================================================================

- (void)startSessionWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (self.sessionStatus != kIdle)
        return;
    
    NSString *urlStr = [NSString stringWithFormat:@"https://%@:%lu", self.sessionConfig.host, self.sessionConfig.port];
    NSURL *url = [NSURL URLWithString:urlStr];

    DDLogInfo(@"Will start session with URL: %@", urlStr);

    //Create proxy object
    _proxy = [[RCRouterProxy alloc] initWithRouterURL:url];
    
    //Update session status
    self.sessionStatus = kAuthenticating;
    
    __weak id blockSelf = self;
    [self.proxy authenticate:CLIENT_API_VERSION
                    password:DEFAULT_PASSWORD
                     success:^(long serverAPI, NSString *token) {
                         
                         [blockSelf sessionDidStart];
                         completionHandler(YES, nil);
                         
                     } failure:^(NSError *error) {
                         
                         DDLogInfo(@"Failed to start session: %@", error);
                         completionHandler(NO, error);
                         
                     }];
}

//=========================================================================

- (void)stopSession
{
}

//=========================================================================

- (void)notifyDidUpdateRouterInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RCRouterDidUpdateRouterInfoNotification object:self];
}

//=========================================================================

- (void)sessionDidStart
{
    DDLogInfo(@"Session did start");
    
    //Update session status
    self.sessionStatus = kAuthenticated;
    
    //Create task manager
    self.taskManager = [[RCRouterTaskManager alloc] initWithRouterProxy:self.proxy];
    
    //Schedule router info update
    RCRouterInfoTask *infoTask = [[RCRouterInfoTask alloc] initWithIdentifier:@"RouterInfo"];
    
    __weak RCRouter *blockSelf = self;
    [infoTask setCompletionHandler:^(RCRouterInfo *routerInfo, NSError *error){
        
        if (!error)
        {
            [blockSelf notifyDidUpdateRouterInfo];
        }
        
    }];
    self.routerInfoTask = infoTask;
    
    [self updateRouterInfo];
    
    //Schedule periodic tasks
    [self addPeriodicTasks];
}

//=========================================================================

- (void)updateRouterInfo
{
    [self.taskManager addTask:self.routerInfoTask];
}

//=========================================================================

- (void)addPeriodicTasks
{
//    RCRouterEchoTask *echoTask = [[RCRouterEchoTask alloc] initWithIdentifier:@"Echo"];
//    echoTask.frequency = 1;
//    [self.taskManager addTask:echoTask];
}

//=========================================================================
@end
//=========================================================================
