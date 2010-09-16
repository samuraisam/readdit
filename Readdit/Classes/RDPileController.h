//
//  RDPileController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class RDBrowserController;

@interface RDPileController : UITableViewController
{
  NSMutableArray *items;
  int memoryWarningCount;
  RDBrowserController *browserController;
  NSString *username;
  BOOL closing;
}

@property(nonatomic, copy) NSString *username;
@property(nonatomic, retain) RDBrowserController *browserController;
- (void)addItem:(NSDictionary *)item request:(NSURLRequest *)req;

@end
