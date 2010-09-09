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

@class RDItemCell;

@interface RDSubredditController : YMTableViewController 
{
  MGSplitViewController *splitController;
  NSString *username, *reddit;
  NSArray *items;
  BOOL didLoadCachedItems;
  NSIndexPath *currentItemIndexPath;
}

@property(nonatomic, assign) MGSplitViewController *splitController;
@property(nonatomic, retain) NSString *username, *reddit;

- (void)configureCell:(RDItemCell *)cell forItem:(NSDictionary *)item;

@end
