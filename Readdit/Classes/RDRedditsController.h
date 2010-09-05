//
//  RootViewController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RDBrowserController;
@class MGSplitViewController;

@interface RDRedditsController : UITableViewController 
{
  RDBrowserController *detailViewController;
  IBOutlet MGSplitViewController *splitController;
}

@property (nonatomic, retain) IBOutlet MGSplitViewController *splitController;
@property (nonatomic, retain) IBOutlet RDBrowserController *detailViewController;

@end
