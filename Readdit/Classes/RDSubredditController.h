//
//  YMSubredditController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"
#import "MGSplitViewController.h"

@class RDItemCell, RDBrowserController, RDPileController;

@interface RDSubredditController : YMTableViewController 
{
  IBOutlet MGSplitViewController *splitController;
  IBOutlet RDBrowserController *browserController;
  NSString *username, *reddit;
  NSArray *items;
  BOOL didLoadCachedItems;
  NSIndexPath *currentItemIndexPath;
  BOOL didLoadFromLaunch;
  id<DKKeyedPool> loadingPool;
  NSString *next;
  UIView *nextPageFooterView;
  UIButton *nextButton;
  UIActivityIndicatorView *nextLoadingIndicator;
  BOOL loadingMore;
  NSArray *seenItems;
  RDPileController *pileController;
}

@property(nonatomic, retain) MGSplitViewController *splitController;
@property(nonatomic, retain) RDBrowserController *browserController;
@property(copy) NSString *username, *reddit;
@property(assign) BOOL didLoadFromLaunch;
@property(nonatomic, retain) NSArray *items;
@property(nonatomic, retain) RDPileController *pileController;

- (void)configureCell:(RDItemCell *)cell forItem:(NSDictionary *)item;

@end
