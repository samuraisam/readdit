//
//  DetailViewController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RDBrowserController.h"
#import "RDRedditsController.h"
#import "NSDate+Helper.h"
#import "RDRedditClient.h"


@implementation RDBrowserController

@synthesize splitController, item, username;
@synthesize upButton, downButton, titleLabel, infoLabel, submissionLabel, webView;
@synthesize forwardItem, backItem, refreshItem, urlItem;

- (void)setItem:(NSDictionary *)i
{
  backItem.enabled = NO;
  refreshItem.enabled = NO;
  forwardItem.enabled = NO;
  if (item) [item release];
  item = [i retain];
  NSURLRequest *req = [[[NSURLRequest alloc] initWithURL:
                        [NSURL URLWithString:[i objectForKey:@"url"]]] autorelease];
  if (webView) [webView loadRequest:req];
  titleLabel.text = [item objectForKey:@"title"];
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:intv([item objectForKey:@"created_utc"])];
  submissionLabel.text = [NSString stringWithFormat:@"%@ by %@ in %@", [date stringDaysAgo], 
                          [item objectForKey:@"author"], [item objectForKey:@"subreddit"]];
  infoLabel.text = [NSString stringWithFormat:@"%@ points | %@ comments", 
                    [[item objectForKey:@"score"] description], 
                    [[item objectForKey:@"num_comments"] description]];
  UIImage *up = [UIImage imageNamed:@"up-arrow.png"];
  UIImage *down = [UIImage imageNamed:@"down-arrow.png"];
  if (![[i objectForKey:@"likes"] isEqual:[NSNull null]]) {
    if (boolv([i objectForKey:@"likes"])) up = [UIImage imageNamed:@"up-arrow-liked.png"];
    else down = [UIImage imageNamed:@"down-arrow-disliked.png"];
  }
  [downButton setImage:down forState:UIControlStateNormal];
  [upButton setImage:up forState:UIControlStateNormal];
}

- (void)webViewDidFinishLoad:(UIWebView *)v
{
  backItem.enabled = v.canGoBack;
  forwardItem.enabled = v.canGoForward;
  refreshItem.enabled = YES;
}

- (void)upvote:(UIButton *)sender
{
  int v = 1 + ([[item objectForKey:@"liked"] isEqual:nsni(-1)] ? -1 : 0);
  [[[RDRedditClient sharedClient] vote:v item:
   [item objectForKey:@"name"] subreddit:
    [item objectForKey:@"subreddit"] username:username] 
   addBoth:callbackTS(self, _didVote:)];
}

- (void)downvote:(UIButton *)sender
{
  int v = -1 + ([[item objectForKey:@"liked"] isEqual:nsni(-1)] ? 1 : 0);
  [[[RDRedditClient sharedClient] vote:v item:
    [item objectForKey:@"name"] subreddit:
    [item objectForKey:@"subreddit"] username:username]
   addBoth:callbackTS(self, _didVote:)];
}

- (id)_didVote:(id)r
{
  NSLog(@"didVote %@", [[[NSString alloc] initWithData:r encoding:
                         NSUTF8StringEncoding] autorelease]);
  return r;
}

#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc 
     willHideViewController:(UIViewController *)aViewController 
          withBarButtonItem:(UIBarButtonItem*)barButtonItem 
       forPopoverController: (UIPopoverController*)pc 
{}

- (void)splitViewController: (UISplitViewController*)svc 
     willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem 
{}


#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
  [super viewDidLoad];
  [self.navigationController setNavigationBarHidden:YES animated:NO];
  self.toolbarItems = array_(backItem, forwardItem, refreshItem);
  [self.navigationController setToolbarHidden:NO animated:NO];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (void)viewDidUnload 
{
}


#pragma mark -
#pragma mark Memory management


- (void)dealloc 
{
  self.splitController = nil;
  self.upButton = nil; 
  self.downButton = nil; 
  self.titleLabel = nil; 
  self.infoLabel = nil; 
  self.submissionLabel = nil; 
  self.webView = nil;
  self.forwardItem = nil; 
  self.backItem = nil; 
  self.refreshItem = nil; 
  self.urlItem = nil;
  self.item = nil;
  [super dealloc];
}

@end
