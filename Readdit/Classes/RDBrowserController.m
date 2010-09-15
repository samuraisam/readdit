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
#import "SHK.h"


@implementation RDBrowserController

@synthesize splitController, item, username, delegate;
@synthesize upButton, downButton, titleLabel, infoLabel, submissionLabel, webView;
@synthesize forwardItem, backItem, refreshItem, urlItem, actionItem;

- (void)setItem:(NSDictionary *)i
{
  backItem.enabled = NO;
  refreshItem.enabled = NO;
  forwardItem.enabled = NO;
  if (item) [item release];
  item = [i retain];
  NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:
                               [NSURL URLWithString:[i objectForKey:@"url"]] cachePolicy:
                               NSURLRequestReturnCacheDataElseLoad timeoutInterval:15.0] autorelease];
  if (boolv([i objectForKey:@"is_self"])) {
    [req setValue:PREF_KEY(@"cookie") forHTTPHeaderField:@"Cookie"];
  }
  
  UIWebView *wv = [[UIWebView alloc] initWithFrame:webView.frame];
  [webView removeFromSuperview];
  if (webView) [webView release];
  webView = wv;
  webView.delegate = self;
  webView.scalesPageToFit = YES;
  webView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
  backItem.target = forwardItem.target = refreshItem.target = webView;
  backItem.action = @selector(goBack);
  forwardItem.action = @selector(goForward);
  refreshItem.action = @selector(reload);
  backItem.enabled = forwardItem.enabled = refreshItem.enabled = NO;
  
  [self.view addSubview:webView];
  [webView loadRequest:req];
  
  titleLabel.text = [item objectForKey:@"title"];
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:intv([item objectForKey:@"created_utc"])];
  submissionLabel.text = [NSString stringWithFormat:@"%@ in", [NSDate stringForDisplayFromDate:date]];
  
  [submissionLabel sizeToFit];
  [redditButton setTitle:[item objectForKey:@"subreddit"] forState:UIControlStateNormal];
  [redditButton sizeToFit];
  redditButton.frame = CGRectMake(submissionLabel.frame.origin.x + submissionLabel.frame.size.width + 5, 
                                  redditButton.frame.origin.y, redditButton.frame.size.width + 20, 25);
  byLabel.frame = CGRectMake(redditButton.frame.origin.x + redditButton.frame.size.width + 5, 
                             byLabel.frame.origin.y, byLabel.frame.size.width, byLabel.frame.size.height);
  [authorButton setTitle:[item objectForKey:@"author"] forState:UIControlStateNormal];
  [authorButton sizeToFit];
  authorButton.frame = CGRectMake(byLabel.frame.origin.x + byLabel.frame.size.width + 5, 
                                  authorButton.frame.origin.y, authorButton.frame.size.width + 20, 25);
  
  [urlButton setTitle:[i objectForKey:@"url"] forState:UIControlStateNormal];
  [urlButton setEnabled:YES];
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

- (void)webViewDidStartLoad:(UIWebView *)v
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  backItem.enabled = v.canGoBack;
  forwardItem.enabled = v.canGoForward;
  refreshItem.enabled = YES;
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
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
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
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)gotoAuthor:(id)s
{
  UIActionSheet *as = [[[UIActionSheet alloc] initWithTitle:nil delegate:
                        self cancelButtonTitle:nil destructiveButtonTitle:
                        nil otherButtonTitles:@"Add Friend", @"Submissions", 
                        @"Liked", nil] autorelease];
  [as showFromRect:[s frame] inView:[s superview] animated:YES];
}

- (void)gotoReddit:(id)s
{
}

- (void)action:(id)s
{
  SHKItem *i = [SHKItem URL:[item objectForKey:@"url"] title:[item objectForKey:@"title"]];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:i];
  [actionSheet showFromBarButtonItem:actionItem animated:YES];
}

- (id)_didVoteDirection:(id)d :(id)r
{
  NSLog(@"didVote %@ %@", d, r);
  NSMutableDictionary *_ = [[item mutableCopy] autorelease];
  int E = [[_ objectForKey:@"likes"] isEqual:[NSNull null]] 
            ? -1 : intv([_ objectForKey:@"likes"]);
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
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
  HUD = nil;
  [self.navigationController setNavigationBarHidden:YES animated:NO];
  
  if (!urlButton) {
    urlButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [urlButton setBackgroundImage:
     [[UIImage imageNamed:@"urlbackground.png"] stretchableImageWithLeftCapWidth:
      100 topCapHeight:15] forState:UIControlStateNormal];
    [urlButton setTitleColor:[UIColor colorWithHexString:@"2c3640"] forState:UIControlStateNormal];
    [urlButton setFrame:CGRectMake(0, 0, 250, 31)];
    urlButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
    urlButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    urlButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [urlButton setTitle:@"Choose a Link" forState:UIControlStateNormal];
    urlButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    urlItem = [[UIBarButtonItem alloc] initWithCustomView:urlButton];
    [urlButton addTarget:self action:@selector(didTouchURL:) forControlEvents:UIControlEventTouchUpInside];
    [urlButton setEnabled:NO];
  }
  UIImage *stretchableItemBg = [[UIImage imageNamed:@"inlineitem.png"] 
                            stretchableImageWithLeftCapWidth:11 topCapHeight:15];
  [redditButton setBackgroundImage:stretchableItemBg forState:UIControlStateNormal];
  [authorButton setBackgroundImage:stretchableItemBg forState:UIControlStateNormal];
  UIBarButtonItem *sp = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                          UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease];
  self.toolbarItems = array_(backItem, forwardItem, refreshItem, urlItem, sp, actionItem);
  [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)didTouchURL:(id)s
{
  UIActionSheet *actionSheet 
    = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:
        nil destructiveButtonTitle:nil otherButtonTitles:
        @"Copy to Clipboard", @"Open in Safari", nil] autorelease];
  [actionSheet showFromBarButtonItem:urlItem animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSLog(@"buttonIndex %i", buttonIndex);
  if (buttonIndex == 0) {
    if (HUD) [HUD release];
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [HUD setLabelText:@"Copied"];
    [self.view addSubview:HUD];
    [HUD setMode:MBProgressHUDModeDeterminate];
    [HUD setProgress:1.0];
    [HUD show:YES];
    [[UIPasteboard generalPasteboard] addItems:
     array_(dict_([item objectForKey:@"url"], @"string"))];
    [HUD performSelector:@selector(hide:) withObject:@"" afterDelay:.5];
  } else if (buttonIndex == 1) {
    [[UIApplication sharedApplication] openURL:
     [NSURL URLWithString:[item objectForKey:@"url"]]];
  }
}
  
- (void) hudWasHidden
{
  [HUD removeFromSuperview];
  [HUD release];
  HUD = nil;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  CGRect f = urlButton.frame;
  f.size.width = self.navigationController.toolbar.frame.size.width - 226;
  urlButton.frame = f;
}

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
  NSLog(@"view did unload %@", self);
}


#pragma mark -
#pragma mark Memory management


- (void)dealloc 
{
  [HUD release];
  [urlButton release];
  self.actionItem = nil;
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
