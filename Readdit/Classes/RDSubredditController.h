//
//  YMSubredditController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"


@interface RDSubredditController : YMTableViewController 
{
  NSString *username, *reddit;
  NSArray *items;
  BOOL didLoadCachedItems;
}

@property(nonatomic, retain) NSString *username, *reddit;

@end
