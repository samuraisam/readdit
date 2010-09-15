//
//  RootViewController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"

@class RDBrowserController, RDSubredditController;
@class MGSplitViewController;

@interface RDRedditsController : YMTableViewController
{
  IBOutlet RDBrowserController *detailViewController;
  IBOutlet RDSubredditController *redditViewController;
  IBOutlet MGSplitViewController *splitController;
  BOOL performingInitialSync, firstSyncCompleted;
  NSArray *reddits;
  NSArray *builtins, *builtins2;
  NSString *username;
  NSArray *subscribedSubredditIds;
  BOOL searchMode, gotInitialSearchResults;
  RDRedditsController *redditsSearchController;
  NSString *next;
  UIView *nextPageFooterView;
  UIButton *nextButton;
  UIActivityIndicatorView *nextLoadingIndicator;
  BOOL loadingMore, subscribing;
}

@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, retain) IBOutlet MGSplitViewController *splitController;
@property (nonatomic, retain) IBOutlet RDBrowserController *detailViewController;
@property (nonatomic, retain) IBOutlet RDSubredditController *redditViewController;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) RDRedditsController *redditsSearchController;

- (IBAction)search:(id)s;

@end
