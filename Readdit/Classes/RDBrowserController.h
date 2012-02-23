//
//  DetailViewController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "MBProgressHUD.h"

@interface RDBrowserController : UIViewController 
<UIPopoverControllerDelegate, UISplitViewControllerDelegate, UIWebViewDelegate,
UIActionSheetDelegate, MBProgressHUDDelegate, UITableViewDataSource, UITableViewDelegate> 
{
  IBOutlet MGSplitViewController *splitController;
  IBOutlet UIButton *upButton, *downButton;
  IBOutlet UILabel *titleLabel, *submissionLabel, *infoLabel, *byLabel;
  IBOutlet UIWebView *webView;
  IBOutlet UIBarButtonItem *forwardItem, *backItem, *refreshItem, *urlItem, *actionItem;
  IBOutlet UIButton *redditButton, *authorButton;
  UIButton *urlButton;
  UIButton *closeButton;
  NSDictionary *item;
  NSString *username;
  id delegate;
  MBProgressHUD *HUD;
  NSArray *postDetail;
  UITableView *tableView;
}

@property (nonatomic) UITableView *tableView;
@property (nonatomic) id delegate;
@property (nonatomic) NSDictionary *item;
@property (nonatomic) MGSplitViewController *splitController;
@property (nonatomic) UIButton *upButton, *downButton;
@property (nonatomic) UILabel *titleLabel, *submissionLabel, *infoLabel;
@property (nonatomic) UIBarButtonItem *forwardItem, *backItem, *refreshItem, *urlItem, *actionItem;
@property (nonatomic) UIWebView *webView;
@property (copy) NSString *username;

- (IBAction)upvote:(id)s;
- (IBAction)downvote:(id)s;
- (IBAction)gotoReddit:(id)s;
- (IBAction)gotoAuthor:(id)s;
- (IBAction)action:(id)s;
- (IBAction)gotoComments:(id)s;
- (IBAction)close:(id)s;
- (void)refreshVote;
- (void)setShowsCloseButton:(BOOL)showCloseButton;

@end
