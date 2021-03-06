//
//  RCAppDelegate.m
//  I2PMonitor
//
//  Created by miximka on 11/05/14.
//  Copyright (c) 2014 miximka. All rights reserved.
//

#import "RCAppDelegate.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "RCLogFormatter.h"
#import "RCRouter.h"
#import "RCRouterInfo.h"
#import "RCPreferencesWindowController.h"
#import "RCRouterManager.h"
#import "RCStatusBarView.h"
#import "RCNetworkViewController.h"
#import "RCAttachedWindow.h"
#import "RCMainWindowController.h"
#import "RCMainViewController.h"
#import "NSFileManager+SupportDirectory.h"

//=========================================================================

#ifdef DEBUG
int const ddLogLevel = LOG_LEVEL_DEBUG;
#else
int const ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface RCAppDelegate () <RCStatusBarViewDelegate, RCMainWindowControllerDelegate>
@property (nonatomic) NSStatusItem *statusBarItem;
@property (nonatomic) RCRouterManager *routerManager;
@property (nonatomic) RCPreferencesWindowController *prefsWindowController;
@property (nonatomic) BOOL isFirstStart;
@property (nonatomic) RCMainWindowController *mainWindowController;
@end

//=========================================================================
@implementation RCAppDelegate
//=========================================================================

- (void)dealloc
{
    [self unregisterFromNotifications];
}

//=========================================================================

- (BOOL)isRunningUnitTests
{
	return NSClassFromString(@"XCTestRun") != nil;
}

//=========================================================================

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routerDidUpdateRouterInfo:)
                                                 name:RCRouterDidUpdateRouterInfoNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managerDidSetRouter:)
                                                 name:RCManagerDidSetRouterNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidResignKey:)
                                                 name:NSWindowDidResignKeyNotification
                                               object:nil];
}

//=========================================================================

- (void)unregisterFromNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//=========================================================================

- (void)initializeLogging
{
    RCLogFormatter *logFormatter = [[RCLogFormatter alloc] init];
    
    [[DDASLLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    [[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; //24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [fileLogger setLogFormatter:logFormatter];
    [DDLog addLogger:fileLogger];
    
    //Log application version
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    DDLogInfo(@"===");
    DDLogInfo(@"App version: %@ (%@)", [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBundleVersion"]);
}

//=========================================================================

- (void)addStatusBarItem
{
    //Create status bar item
	NSStatusItem *item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [item setMenu:self.menu];
    
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];
    RCStatusBarView *statusBarView = [[RCStatusBarView alloc] initWithFrame:NSMakeRect(0, 1, thickness, thickness)];
    [statusBarView setDelegate:self];
    [statusBarView setStatusItem:item];
    [statusBarView setImage:[NSImage imageNamed:@"StatusBarIcon_Inactive"]];
    
    [item setView:statusBarView];
    [item setHighlightMode:YES];
    
    self.statusBarItem = item;
}

//=========================================================================

- (RCStatusBarView *)statusBarItemView
{
    return (RCStatusBarView *)self.statusBarItem.view;
}

//=========================================================================

- (NSPoint)bottomLeftCornerOfStatusBarItemView
{
    NSWindow *statusBarItemWindow = [[self statusBarItemView] window];

    NSRect statusBarRect = statusBarItemWindow.frame;

    NSPoint point;
    point.x = statusBarRect.origin.x;
    point.y = statusBarRect.origin.y - statusBarRect.size.height;
    
    return point;
}

//=========================================================================

- (void)showArrow
{
    NSWindow *statusBarItemWindow = [[self statusBarItemView] window];
    
    NSRect statusBarRect = statusBarItemWindow.frame;
    NSRect aRect = self.arrowPanel.frame;
    aRect.origin.x = statusBarRect.origin.x + statusBarRect.size.width / 2.f - aRect.size.width / 2.f;
    aRect.origin.y = statusBarRect.origin.y - aRect.size.height - statusBarRect.size.height;

    [self.arrowPanel setFrame:aRect display:YES];
    [self.arrowPanel makeKeyAndOrderFront:self];
}

//=========================================================================

- (void)hideArrow
{
    [self.arrowPanel close];
    self.arrowPanel = nil;
}

//=========================================================================

- (void)updateStatusBarIcon
{
    //Update status bar icon
    RCStatusBarIconType iconType = RCIconTypeInactive;
    if (self.routerManager.activeRouter.active)
    {
        iconType = RCIconTypeActive;
    }
    [[self statusBarItemView] setIconType:iconType];
}

//=========================================================================

- (IBAction)shutdown:(id)sender
{
    DDLogInfo(@"Shutdown");
}

//=========================================================================

- (IBAction)restart:(id)sender
{
    DDLogInfo(@"Restart");
}

//=========================================================================

- (IBAction)openAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:self];
}

//=========================================================================

- (IBAction)openAcknowledgments:(id)sender
{
    NSString *acknowledgmentsFile = [[NSBundle mainBundle] pathForResource:@"Acknowledgments" ofType:@"rtf"];
    [[NSWorkspace sharedWorkspace] openFile:acknowledgmentsFile];
}

//=========================================================================

- (IBAction)openPreferences:(id)sender
{
	if (!self.prefsWindowController)
	{
		RCPreferencesWindowController *ctrl = [[RCPreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
        [ctrl setRouterManager:self.routerManager];
        self.prefsWindowController = ctrl;
	}
	
	[self.prefsWindowController showWindow:self];
}

//=========================================================================

- (void)showMainWindow
{
    [self hideArrow];
    
    NSPoint point = [self statusBarItemView].window.frame.origin;
    [self.mainWindowController showWindowAtPoint:point];
}

//=========================================================================

- (void)dismissMainWindow
{
    [[self statusBarItemView] setHighlighted:NO];
    [self.mainWindowController.window close];
}

//=========================================================================

- (void)initializeApplicationSupportDir
{
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURLIfNotExists:[[NSFileManager defaultManager] applicationSupportDir]
                                                              error:&error];
    
    if (!success)
    {
        DDLogError(@"Can't create application support directory: %@", error);
    }
}

//=========================================================================
#pragma mark NSApplicationDelegate
//=========================================================================

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([self isRunningUnitTests])
        return;

    [self initializeLogging];

    //Create application support directory, if it does not exists yet
    [self initializeApplicationSupportDir];
    
    //Add status bar item
    [self addStatusBarItem];
    
    BOOL isFirstStart = [RCPrefs isFirstStart];
    if (isFirstStart)
    {
        [RCPrefs setIsFirstStart:NO];
        [RCPrefs synchronize];
        
        //Show window with the pointing arrow to the login item
        [self showArrow];
    }

    //Initialize router manager
    RCRouterManager *routerManager = [[RCRouterManager alloc] init];
    self.routerManager = routerManager;

    //Initialize main window controller
    RCAttachedWindow *window = [[RCAttachedWindow alloc] initWithContentRect:NSMakeRect(100, 100, 100, 100) styleMask:0 backing:NSBackingStoreBuffered defer:YES];
    RCMainWindowController *windowController = [[RCMainWindowController alloc] initWithWindow:window];
    [windowController setDelegate:self];
    self.mainWindowController = windowController;

    [self registerForNotifications];

    //Start last used router
    [self.routerManager startDefaultRouter];
}

//=========================================================================
#pragma mark Notifications
//=========================================================================

- (void)routerDidUpdateRouterInfo:(NSNotification *)notification
{
    [self updateStatusBarIcon];
}

//=========================================================================

- (void)managerDidSetRouter:(NSNotification *)notification
{
    //Update status bar
    [self updateStatusBarIcon];

    //Update view controller
    [self.mainWindowController.mainViewController setRepresentedObject:self.routerManager.activeRouter];
}

//=========================================================================

- (void)windowDidResignKey:(NSNotification *)notification
{
    NSWindow *object = notification.object;
    
    if (object == self.mainWindowController.window)
    {
        //Close window
        [self dismissMainWindow];
    }
}

//=========================================================================
#pragma mark RCStatusBarViewDelegate
//=========================================================================

- (void)statusBarViewDidChangeHighlighted:(RCStatusBarView *)view
{
    if (view.highlighted)
    {
        [self showMainWindow];
    }
    else
    {
        [self dismissMainWindow];
    }
}

//=========================================================================
#pragma mark RCMainWindowControllerDelegate
//=========================================================================

- (void)mainWindowControllerShouldDismissWindow:(RCMainWindowController *)controller
{
    [self dismissMainWindow];
}

//=========================================================================
@end
//=========================================================================

