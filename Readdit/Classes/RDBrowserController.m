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

@synthesize splitController, item, username, delegate;
@synthesize upButton, downButton, titleLabel, infoLabel, submissionLabel, webView;
@synthesize forwardItem, backItem, refreshItem, urlItem;

- (void)setItem:(NSDictionary *)i
{
  backItem.enabled = NO;
  refreshItem.enabled = NO;
  forwardItem.enabled = NO;
  if (item) [item release];
  if (delegate) [delegate release];
  item = [i retain];
  NSURLRequest *req = [[[NSURLRequest alloc] initWithURL:
                        [NSURL URLWithString:[i objectForKey:@"url"]]] autorelease];
  if (webView) [webView loadRequest:req];
  titleLabel.text = [item objectForKey:@"title"];
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:intv([item objectForKey:@"created_utc"])];
  submissionLabel.text = [NSString stringWithFormat:@"%@ by %@ in %@", [date stringDaysAgo], 
                          [item objectForKey:@"author"], [item objectForKey:@"subreddit"]];
  [self refreshVote];
}

- (void)refreshVote
{
  infoLabel.text = [NSString stringWithFormat:@"%@ points | %@ comments", 
                    [[item objectForKey:@"score"] description], 
                    [[item objectForKey:@"num_comments"] description]];
  UIImage *up = [UIImage imageNamed:@"up-arrow.png"];
  UIImage *down = [UIImage imageNamed:@"down-arrow.png"];
  if (![[item objectForKey:@"likes"] isEqual:[NSNull null]]) {
    if (boolv([item objectForKey:@"likes"])) up = [UIImage imageNamed:@"up-arrow-liked.png"];
    else down = [UIImage imageNamed:@"down-arrow-disliked.png"];
  }
  [downButton setImage:down forState:UIControlStateNormal];
  [upButton setImage:up forState:UIControlStateNormal];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)v
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
   addBoth:curryTS(self, @selector(_didVoteDirection::), nsni(v))];
  [downButton setEnabled:NO];
  [upButton setEnabled:NO];
}

- (void)downvote:(UIButton *)sender
{
  int v = -1 + ([[item objectForKey:@"liked"] isEqual:nsni(-1)] ? 1 : 0);
  [[[RDRedditClient sharedClient] vote:v item:
    [item objectForKey:@"name"] subreddit:
    [item objectForKey:@"subreddit"] username:username]
   addBoth:curryTS(self, @selector(_didVoteDirection::), nsni(v))];
  [downButton setEnabled:NO];
  [upButton setEnabled:NO];
}

- (id)_didVoteDirection:(id)d :(id)r
{
  NSLog(@"didVote %@ %@", d, r);
  NSMutableDictionary *_ = [[item mutableCopy] autorelease];
  int E = [[_ objectForKey:@"likes"] isEqual:[NSNull null]] ? -1 : intv([_ objectForKey:@"likes"]);
  int D = intv(d);
  id  Y = nil;
  if (D == -1 && E == -1) { // downvote with no existing vote
    Y = nsni(0);
  } else if (D == -1 && E == 0) { // downvote with existing downvote
    Y = [NSNull null];
    D = 1;
  } else if (D == -1 && E == 1) { // downvote with existing upvote
    Y = nsni(0);
    D = -2;
  } else if (D == 1 && E == -1) { // upvote with no existing vote
    Y = nsni(1);
  } else if (D == 1 && E == 1) { // upvote with existing upvote
    Y = [NSNull null];
    D = -1;
  } else if (D == 1 && E == 0) { // upvote with existing downvote
    Y = nsni(1);
    D = 2;
  }
  
  [_ setObject:Y forKey:@"likes"];
  [_ setObject:nsni(intv([_ objectForKey:@"score"]) + D) forKey:@"score"];
  
  if (delegate && [delegate respondsToSelector:@selector(didUpdateCurrentItem:)]) {
    [delegate performSelector:@selector(didUpdateCurrentItem:) withObject:_];
  }
  
  [item release];
  item = [_ retain];
  [self refreshVote];
  [downButton setEnabled:YES];
  [upButton setEnabled:YES];
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
  self.delegate = nil;
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
