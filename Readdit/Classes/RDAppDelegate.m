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
#import "RDRedditClient.h"


@implementation RDAppDelegate

@synthesize window, splitViewController, rootViewController, detailViewController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:
(NSDictionary *)launchOptions 
{
  [splitViewController setShowsMasterInPortrait:YES];
  [window addSubview:splitViewController.view];
  [window makeKeyAndVisible];
  [DKDeferred setCache:[DKDeferredSqliteCache sharedCache]];
  [[DKDeferred cache] setMemoryCacheMaximum:100];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *_cacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"URLCache"]; 
  NSLog(@"urlCache %@", _cacheDir);
  [NSURLCache setSharedURLCache:[[NSURLCache alloc] initWithMemoryCapacity:
                        512*1024 diskCapacity:10*1024*1024 diskPath:_cacheDir]];

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
  [[RDRedditClient sharedClient] writeSeenItemCache];
  [DKDeferred cache].forceImmediateCaching = YES;
  [[DKDeferred cache] purgeMemoryCache];
  [DKDeferred cache].forceImmediateCaching = NO;
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application 
{
  NSLog(@"application did receive memory warning");
}




@end
