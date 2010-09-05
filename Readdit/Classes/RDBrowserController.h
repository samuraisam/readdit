//
//  DetailViewController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"

@interface RDBrowserController : UIViewController 
<UIPopoverControllerDelegate, UISplitViewControllerDelegate> 
{
  IBOutlet MGSplitViewController *splitController;
  UIPopoverController *popoverController;
  UIToolbar *toolbar;

  id detailItem;
  UILabel *detailDescriptionLabel;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) MGSplitViewController *splitController;
@property (nonatomic, retain) id detailItem;
@property (nonatomic, retain) IBOutlet UILabel *detailDescriptionLabel;
@property (nonatomic, retain) UIPopoverController *popoverController;

@end
