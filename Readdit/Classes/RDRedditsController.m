//
//  RootViewController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RDRedditsController.h"
#import "MGSplitViewController.h"
#import "RDBrowserController.h"
#import "RDRedditClient.h"
#import "RDLoginController.h"
#import "YMRefreshView.h"
#import "RDSubredditController.h"
#import "NSObject+UIKitGenericErrorHandling.h"
#import "RDRedditCell.h"


@interface RDRedditsController (PrivateParts)

- (void)privateInit;

@end


@implementation RDRedditsController

@synthesize detailViewController, splitController, username, redditViewController, 
            searchMode, redditsSearchController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    [self privateInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder])) {
    [self privateInit];
  }
  return self;
}

- (void)privateInit
{
  self.actionTableViewHeaderClass = [YMRefreshView class];
  // TODO: multi-user support
  username = [PREF_KEY(@"username") copy];
  performingInitialSync = firstSyncCompleted = NO;
  loadingMore = subscribing = NO;
  searchMode = gotInitialSearchResults = NO;
  reddits = EMPTY_ARRAY;
  builtins = array_(array_(@"Front Page", @"/"), array_(@"All", @"/r/all/"), array_(@"Top", @"/top/"), 
                     array_(@"New", @"/new/"), array_(@"Controversial", @"/controversial/"));
  builtins2 = array_(array_(@"Saved", @"/saved/"),
                      array_(@"Friends", @"/r/friends/"), array_(@"Submitted", @"/user/$username/submitted/"),
                      array_(@"Liked", @"/user/$username/liked/"), array_(@"Disliked", @"/user/$username/disliked/"),
                      array_(@"Hidden", @"/user/$username/hidden/"));
  subscribedSubredditIds = EMPTY_ARRAY;
  
  nextLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                          UIActivityIndicatorViewStyleGray];
  nextLoadingIndicator.autoresizingMask 
  = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
  nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [nextButton addTarget:self action:@selector(loadMore:) forControlEvents:UIControlEventTouchUpInside];
  nextPageFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 52)];
  nextPageFooterView.backgroundColor = [UIColor whiteColor];
  nextPageFooterView.opaque = YES;
  nextPageFooterView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (RDRedditsController *)redditsSearchController
{
  if (!redditsSearchController) {
    redditsSearchController = [[RDRedditsController alloc] initWithStyle:UITableViewStylePlain];
    redditsSearchController.searchMode = YES;
    redditsSearchController.redditViewController = self.redditViewController;
  }
  return redditsSearchController;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
  [super viewDidLoad];
  self.clearsSelectionOnViewWillAppear = YES;
  self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  self.tableView.separatorColor = [UIColor colorWithHexString:@"a5bcca"];
  self.tableView.backgroundColor = [UIColor colorWithHexString:@"8c9ba4"];
  self.tableView.tableFooterView = nextPageFooterView;
  [nextPageFooterView addSubview:nextButton];
  if (searchMode) {
    self.navigationItem.rightBarButtonItem 
      = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
          UIBarButtonSystemItemRefresh target:self action:
          @selector(refresh:)];
  }
}

- (void)refresh:(UIBarButtonItem *)sender
{
  sender.enabled = NO;
  [[[RDRedditClient sharedClient] allSubredditsPage:nil existing:EMPTY_ARRAY]
   addBoth:callbackTS(self, _gotSubreddits:)];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)loadMore:(UIButton *)sender
{
  loadingMore = YES;
  [sender removeFromSuperview];
  [nextPageFooterView addSubview:nextLoadingIndicator];
  [nextLoadingIndicator startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [[[RDRedditClient sharedClient] allSubredditsPage:next existing:reddits] 
   addBoth:callbackTS(self, _gotSubreddits:)];
  self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)setSearchMode:(BOOL)s
{
  if (s) {
    self.actionTableViewHeaderClass = NULL;
    self.title = @"Reddits";
  }
  searchMode = s;
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  if (username && !searchMode) self.title = username;  
  if (!searchMode) self.tableView.tableFooterView = nil;
}

- (void)viewDidAppear:(BOOL)animated 
{
  [super viewDidAppear:animated];
  if (searchMode) {
    nextButton.frame = CGRectMake(4, 4, self.tableView.frame.size.width - 8, 44);
    nextLoadingIndicator.frame = CGRectMake(self.tableView.frame.size.width / 2 
                                            - nextLoadingIndicator.frame.size.width / 2, 12, 22, 22);
    if (!gotInitialSearchResults) {
      [[[RDRedditClient sharedClient] allSubredditsPage:nil existing:EMPTY_ARRAY]
       addBoth:callbackTS(self, _gotSubreddits:)];
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    return;
  }
  if (![[[RDRedditClient sharedClient] accounts] count]) {
    RDLoginController *login = [[RDLoginController alloc] initWithStyle:
                                 UITableViewStyleGrouped];
    login.splitController = self.splitController;
    login.delegate = self;
    login.title = @"Login";
    UINavigationController *nav = [[UINavigationController alloc] 
                                initWithRootViewController:login];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.splitController presentModalViewController:nav animated:YES];
  } else {
    if (username) {
      self.title = username;
      id l = PREF_KEY([username stringByAppendingString:@"redditslastupdated"]);
      if (l) {
        NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:[l intValue]];
        [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:lastUpdated];
      }
    }
    if (!performingInitialSync) {
      performingInitialSync = YES;
      [self showReloadAnimationAnimated:!firstSyncCompleted];
      [[[RDRedditClient sharedClient] cachedSubredditsForUsername:username] 
       addBoth:callbackTS(self, _gotCachedSubreddits:)];
    }
  } 
}

- (void)search:(id)s
{
  self.redditsSearchController.username = username;
  [self.navigationController pushViewController:
   self.redditsSearchController animated:YES];
}

- (void)reloadTableViewDataSource
{
  if (performingInitialSync) return;
  [[[RDRedditClient sharedClient] subredditsForUsername:username]
   addBoth:callbackTS(self, _gotSubreddits:)];
}

- (id)_gotCachedSubreddits:(id)r
{
  if ([r isKindOfClass:[NSArray class]]) {
    reddits = r;
    NSLog(@"gotCachedSubreddits: %d", [r count]);
  } else {
    NSLog(@"cachedSubreddits Miss %@", r);
  }
  [self.tableView reloadData];
  subscribedSubredditIds = [[RDRedditClient sharedClient] subscribedSubredditIdsForUsername:
                             username];
  firstSyncCompleted = YES;
  [[[RDRedditClient sharedClient] subredditsForUsername:username] 
   addBoth:callbackTS(self, _gotSubreddits:)];
  return r;
}

- (id)_gotSubreddits:(id)r
{
  [self dataSourceDidFinishLoadingNewData];
  performingInitialSync = NO;
  gotInitialSearchResults = YES;
  
  if (loadingMore) {
    [nextLoadingIndicator stopAnimating];
    [nextLoadingIndicator removeFromSuperview];
    [nextPageFooterView addSubview:nextButton];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }
  
  if ([r handleErrorAndAlert:YES]) return r;
  
  NSLog(@"gotSubreddits %d", [r count]);
  if (isDeferred(r)) return [r addBoth:callbackTS(self, _gotSubreddits:)];
  if (!searchMode) {
    NSDate *d = [NSDate date];
    PREF_SET([username stringByAppendingString:@"redditslastupdated"], 
             nsni([d timeIntervalSince1970]));
    PREF_SYNCHRONIZE;
    [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
  }
  subscribedSubredditIds = [[RDRedditClient sharedClient] subscribedSubredditIdsForUsername:
                             username];
  if (searchMode) {
    reddits = [r objectAtIndex:0];
    next = [r objectAtIndex:1];
  } else {
    reddits = r;
  }
  if (searchMode && [next isEqual:[NSNull null]]) nextButton.enabled = NO;
  if (searchMode) [nextButton setTitle:@"More" forState:UIControlStateNormal];
  if (searchMode) self.navigationItem.rightBarButtonItem.enabled = YES;
  
  [self.tableView reloadData];
  return r;
}

- (void)loginControllerLoggedIn:(id)arg
{
  username = [arg copy];
  [self.splitController dismissModalViewControllerAnimated:YES];
  performingInitialSync = YES;
  [self showReloadAnimationAnimated:YES];
  [[[RDRedditClient sharedClient] cachedSubredditsForUsername:username] 
   addBoth:callbackTS(self, _gotCachedSubreddits:)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView 
{
  if (searchMode) return 1;
  return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section < 2 && !searchMode) return 44;
  return 54;
}

- (NSInteger)tableView:(UITableView *)aTableView 
 numberOfRowsInSection:(NSInteger)section 
{
  if (searchMode) return [reddits count];
  return section == 0 ? [builtins count] : section == 1 ? [builtins2 count] : [reddits count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (searchMode) return nil;
  return section == 0 ? nil : section == 1 ? @"My Posts" : @"Subscribed";
}


- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
  static NSString *ident1 = @"RDRedditCell";
  static NSString *ident2 = @"RDRedditCellSimple";
  static NSString *ident3 = @"RDRedditCellSubscribe";
  BOOL useSimple = indexPath.section < 2 && !searchMode;
  NSString *ident = useSimple ? ident2 : searchMode ? ident3 : ident1;

  RDRedditCell *cell = (RDRedditCell *)[tableView dequeueReusableCellWithIdentifier:ident];
  if (cell == nil) {
    cell = [[[NSBundle mainBundle] loadNibNamed:ident owner:nil options:nil] objectAtIndex:0];
  }
  if (useSimple && !searchMode) {
    cell.titleLabel.text = [[(indexPath.section == 0 ? builtins : builtins2)
                            objectAtIndex:indexPath.row] objectAtIndex:0];
    cell.subtitleLabel.text = nil;
  } else if (!searchMode) {
    NSDictionary *s = [[reddits objectAtIndex:indexPath.row] objectForKey:@"data"];
    cell.titleLabel.text = [s objectForKey:@"title"];
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@ subscribers", 
                               [s objectForKey:@"url"], [s objectForKey:@"subscribers"]];
  } else {
    NSDictionary *s = [[reddits objectAtIndex:indexPath.row] objectForKey:@"data"];
    cell.titleLabel.text = [s objectForKey:@"title"];
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@ subscribers", 
                               [s objectForKey:@"url"], [s objectForKey:@"subscribers"]];
    cell.subscribed = [[subscribedSubredditIds objectAtIndex:0] containsObject:
                       [s objectForKey:@"name"]];
    cell.target = self;
    cell.subscribeAction = @selector(subscribeCell:);
    cell.userInfo = indexPath;
  }
  return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView 
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (subscribing) return nil;
  return indexPath;
}

- (void)subscribeCell:(RDRedditCell *)cell
{
  subscribing = YES;
  self.tableView.scrollEnabled = NO;
  cell.loading = YES;
  NSIndexPath *indexPath = cell.userInfo;
  NSDictionary *s = [[reddits objectAtIndex:indexPath.row] objectForKey:@"data"];
  BOOL subscribed = [[subscribedSubredditIds objectAtIndex:0] containsObject:[s objectForKey:@"name"]];
  NSString *action = (subscribed ? @"unsub" : @"sub");
  [[[RDRedditClient sharedClient] alterSubredditSubscription:[s objectForKey:@"display_name"] withID:
    [s objectForKey:@"name"] action:action username:username]
   addBoth:curryTS(self, @selector(_didSubscribeCell:action:results:), cell, action)];
}

- (id)_didSubscribeCell:(RDRedditCell *)cell action:(NSString *)action results:(id)r
{
  NSLog(@"didSubscribe %@", r);
  subscribing = NO;
  cell.loading = NO;
  self.tableView.scrollEnabled = YES;
  if ([r handleErrorAndAlert:YES]) return r;
  cell.subscribed = [action isEqual:@"sub"];
  return r;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  NSString *reddit = @"";
  if (indexPath.section < 2 && !searchMode) {
    NSArray *a = (indexPath.section == 0 ? builtins : builtins2);
    redditViewController.title = [[a objectAtIndex:indexPath.row] objectAtIndex:0];
    NSString *s = [[[a objectAtIndex:indexPath.row] objectAtIndex:1]
                   stringByReplacingOccurrencesOfString:
                   @"$username" withString:username];
    reddit = s;
  } else {
    redditViewController.title = [[[reddits objectAtIndex:indexPath.row] objectForKey:@"data"]
               objectForKey:@"display_name"];
    reddit = [[[reddits objectAtIndex:indexPath.row] objectForKey:@"data"] 
                objectForKey:@"url"];
  }
  redditViewController.items = EMPTY_ARRAY;
  redditViewController.username = username;
  redditViewController.reddit = [reddit stringByReplacingOccurrencesOfRegex:@"^/" withString:@""];
  [self.navigationController pushViewController:redditViewController animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
  NSLog(@"view did unload %@", self);
}

- (void)dealloc 
{
  NSLog(@"dealloc %@", self);
}

@end

