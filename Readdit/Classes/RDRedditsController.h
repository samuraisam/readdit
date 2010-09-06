//
//  RootViewController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"

@class RDBrowserController;
@class MGSplitViewController;

@interface RDRedditsController : YMTableViewController
{
  RDBrowserController *detailViewController;
  IBOutlet MGSplitViewController *splitController;
  BOOL performingInitialSync, firstSyncCompleted;
  NSArray *reddits;
  NSArray *builtins, *builtins2;
  NSString *username;
}

@property (nonatomic, retain) IBOutlet MGSplitViewController *splitController;
@property (nonatomic, retain) IBOutlet RDBrowserController *detailViewController;
@property (nonatomic, retain) NSString *username;

@end
