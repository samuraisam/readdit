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
<UIPopoverControllerDelegate, UISplitViewControllerDelegate, UIWebViewDelegate> 
{
  IBOutlet MGSplitViewController *splitController;
  IBOutlet UIButton *upButton, *downButton;
  IBOutlet UILabel *titleLabel, *submissionLabel, *infoLabel;
  IBOutlet UIWebView *webView;
  IBOutlet UIBarButtonItem *forwardItem, *backItem, *refreshItem, *urlItem;
  NSDictionary *item;
  NSString *username;
}

@property (nonatomic, retain) NSDictionary *item;
@property (nonatomic, retain) MGSplitViewController *splitController;
@property (nonatomic, retain) UIButton *upButton, *downButton;
@property (nonatomic, retain) UILabel *titleLabel, *submissionLabel, *infoLabel;
@property (nonatomic, retain) UIBarButtonItem *forwardItem, *backItem, *refreshItem, *urlItem;
@property (nonatomic, retain) UIWebView *webView;
@property (retain) NSString *username;

- (IBAction)upvote:(id)s;
- (IBAction)downvote:(id)s;

@end
