//
//  ReadditAppDelegate.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RDAppDelegate.h"
#import "RDRedditsController.h"
#import "RDBrowserController.h"
#import "MGSplitViewController.h"
#import "DKDeferredSqliteCache.h"


@implementation RDAppDelegate

@synthesize window, splitViewController, rootViewController, detailViewController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:
(NSDictionary *)launchOptions 
{
  [window addSubview:splitViewController.view];
  [window makeKeyAndVisible];
  [DKDeferred setCache:[DKDeferredSqliteCache sharedCache]];

  return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application 
{
}


- (void)applicationDidBecomeActive:(UIApplication *)application 
{
}


- (void)applicationWillTerminate:(UIApplication *)application 
{
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application 
{
}


- (void)dealloc {
  [splitViewController release];
  [window release];
  [super dealloc];
}


@end
