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
@class RDMagazineController;

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
  BOOL gotFirstPage;
  NSArray *seenItems;
  RDPileController *pileController;
  RDMagazineController *magazineController;
}

@property(nonatomic) RDMagazineController *magazineController;
@property(nonatomic) MGSplitViewController *splitController;
@property(nonatomic) RDBrowserController *browserController;
@property(nonatomic, copy) NSString *username, *reddit;
@property(assign) BOOL didLoadFromLaunch;
@property(nonatomic) NSArray *items;
@property(nonatomic) RDPileController *pileController;

- (void)configureCell:(RDItemCell *)cell forItem:(NSDictionary *)item;
- (DKDeferred *)LOAD_MORE_MOTHERFUCKER;

@end
