//
//  RCMainViewController.m
//  I2PRemoteControl
//
//  Created by miximka on 18/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCMainViewController.h"
#import "RCNetworkStatusViewController.h"
#import "RCRouter.h"
#import "RCRouterInfo.h"
#import "RCSessionConfig.h"
#import "FBKVOController.h"

//=========================================================================

@interface RCMainViewController ()
@property (nonatomic) RCNetworkStatusViewController *networkViewController;
@property (nonatomic) FBKVOController *kvoController;
@property (nonatomic) NSTimer *uiUpdateTimer;
@end

//=========================================================================
@implementation RCMainViewController
//=========================================================================

- (void)switchToControllerView:(RCViewController *)controller
{
    NSView *contentView = [self contentView];
    
    //Remove previous view
    for (NSView *each in contentView.subviews)
    {
        [each removeFromSuperview];
    }
    
    NSView *view = controller.view;
    [view setFrame:NSMakeRect(0, contentView.bounds.size.height - view.frame.size.height, view.frame.size.width, view.frame.size.height)];
    
    [contentView addSubview:view];
}

//=========================================================================

- (void)updateHost
{
    RCRouter *router = (RCRouter *)self.representedObject;
    
    NSString *str = router.sessionConfig.host;
    [self.hostTextField setStringValue:GetValueOrDefaulIfNil(str)];
}

//=========================================================================

- (void)updateVersion
{
    RCRouter *router = (RCRouter *)self.representedObject;
    
    NSString *str = router.routerInfo.routerVersion;
    [self.versionTextField setStringValue:GetValueOrDefaulIfNil(str)];
}

//=========================================================================

- (void)restartUiUpdateTimer
{
    //Invalidate previous timer,
    RCInvalidateTimer(self.uiUpdateTimer);
    
    //Start periodically update menu entries
    self.uiUpdateTimer = [NSTimer timerWithTimeInterval:1.0
                                                 target:self
                                               selector:@selector(uiUpdateTimerFired:)
                                               userInfo:nil
                                                repeats:YES];
    
    //Add timer manually with NSRunLoopCommonModes to update UI even when menu is opened
    [[NSRunLoop currentRunLoop] addTimer:self.uiUpdateTimer
                                 forMode:NSRunLoopCommonModes];
}

//=========================================================================

- (NSString *)uptimeStringForInterval:(NSTimeInterval)interval
{
    NSString *str = @"";
    
	if (interval < TIME_INTERVAL_MINUTE)
	{
        int secs = interval;
        str = [NSString stringWithFormat:@"%i %@", secs, MyLocalStr(@"kSecondsShortAbbr")];
	}
	else if (interval >= TIME_INTERVAL_MINUTE && interval < TIME_INTERVAL_HOUR)
	{
        int mins = interval / TIME_INTERVAL_MINUTE;
        str = [NSString stringWithFormat:@"%i %@", mins, MyLocalStr(@"kMinutesShortAbbr")];
	}
	else if (interval >= TIME_INTERVAL_HOUR && interval < TIME_INTERVAL_DAY)
	{
        int hours = interval / TIME_INTERVAL_HOUR;
        str = [NSString stringWithFormat:@"%i %@", hours, MyLocalStr(@"kHoursShortAbbr")];
	}
	else
	{
        int days = interval / TIME_INTERVAL_DAY;
        str = [NSString stringWithFormat:@"%i %@", days, MyLocalStr(@"kDaysShortAbbr")];
	}
    
	return str;
}

//=========================================================================

- (void)updateUptime
{
    RCRouter *router = (RCRouter *)self.representedObject;
    
    NSString *str = nil;
    NSTimeInterval uptime = router.routerInfo.estimatedRouterUptime;
    if (uptime > 0)
    {
        str = [self uptimeStringForInterval:uptime];
    }
    [self.uptimeTextField setStringValue:GetValueOrDefaulIfNil(str)];
}

//=========================================================================

- (void)updateGUI
{
    [self updateHost];
    [self updateVersion];
    [self updateUptime];
}

//=========================================================================

- (void)windowWillShow
{
    DDLogInfo(@"Start updating");
    [self restartUiUpdateTimer];
    
    //Immediately trigger router info update
    [(RCRouter *)self.representedObject updateRouterInfo];
}

//=========================================================================

- (void)windowWillClose
{
    DDLogInfo(@"Stop updating");
    RCInvalidateTimer(self.uiUpdateTimer);
}

//=========================================================================
#pragma mark Overridden Methods
//=========================================================================

- (void)awakeFromNib
{
    RCNetworkStatusViewController *networkController = [[RCNetworkStatusViewController alloc] initWithNibName:@"NetworkStatus" bundle:nil];
    self.networkViewController = networkController;
    
    [self switchToControllerView:networkController];
}

//=========================================================================

- (void)setRepresentedObject:(id)object
{
    [super setRepresentedObject:object];
    assert([object isKindOfClass:[RCRouter class]]);

    RCRouter *router = (RCRouter *)object;
    
    //Register for KVO notifications
    FBKVOController *kvoController = [[FBKVOController alloc] initWithObserver:self];
    self.kvoController = kvoController;
    
    __weak RCMainViewController *blockSelf = self;
    [self.kvoController observe:router.routerInfo
                        keyPath:NSStringFromSelector(@selector(routerVersion))
                        options:0
                          block:^(id observer, id object, NSDictionary *change) {
                              
                              [blockSelf updateVersion];
                              
                          }];
    
    [self.kvoController observe:router.routerInfo
                        keyPath:NSStringFromSelector(@selector(routerUptime))
                        options:0
                          block:^(id observer, id object, NSDictionary *change) {
                              
                              [blockSelf updateUptime];
                              
                          }];
    
    [self updateGUI];
}

//=========================================================================
#pragma mark NSTimer callback
//=========================================================================

- (void)uiUpdateTimerFired:(NSTimer *)timer
{
    [self updateUptime];
}

//=========================================================================
@end
//=========================================================================
