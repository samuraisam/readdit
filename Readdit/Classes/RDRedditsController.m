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


@interface RDRedditsController (PrivateParts)

- (void)privateInit;

@end


@implementation RDRedditsController

@synthesize detailViewController, splitController, username, redditViewController;

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
  reddits = [EMPTY_ARRAY retain];
  builtins = [array_(array_(@"Front Page", @"/"), array_(@"All", @"/r/all/"), array_(@"Top", @"/top/"), 
                     array_(@"New", @"/new/"), array_(@"Controversial", @"/controversial/")) retain];
  builtins2 = [array_(array_(@"Saved", @"/saved/"),
                      array_(@"Friends", @"/r/friends/"), array_(@"Submitted", @"/user/$username/submitted/"),
                      array_(@"Liked", @"/user/$username/liked/"), array_(@"Disliked", @"/user/$username/disliked/"),
                      array_(@"Hidden", @"/user/$username/hidden/")) retain];
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
  [super viewDidLoad];
  self.clearsSelectionOnViewWillAppear = YES;
  self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  //[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated 
{
  [super viewDidAppear:animated];
  if (![[[RDRedditClient sharedClient] accounts] count]) {
    RDLoginController *login = [[[RDLoginController alloc] initWithStyle:
                                 UITableViewStyleGrouped] autorelease];
    login.splitController = self.splitController;
    login.delegate = self;
    login.title = @"Login";
    UINavigationController *nav = [[[UINavigationController alloc] 
                                initWithRootViewController:login] autorelease];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.splitController presentModalViewController:nav animated:YES];
  } else {
    if (username) {
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

- (void)reloadTableViewDataSource
{
  if (performingInitialSync) return;
}

- (id)_gotCachedSubreddits:(id)r
{
  if ([r isKindOfClass:[NSArray class]]) {
    if (reddits) [reddits release];
    reddits = [r retain];
    NSLog(@"gotCachedSubreddits: %d", [r count]);
  } else {
    NSLog(@"cachedSubreddits Miss %@", r);
  }
  [self.tableView reloadData];
  firstSyncCompleted = YES;
  [[[RDRedditClient sharedClient] subredditsForUsername:username] 
   addBoth:callbackTS(self, _gotSubreddits:)];
  return r;
}

- (id)_gotSubreddits:(id)r
{
  [self dataSourceDidFinishLoadingNewData];
  performingInitialSync = NO;
  [self.tableView reloadData];
  
  if ([r handleErrorAndAlert:YES]) return r;
  
  NSLog(@"gotSubreddits %d", [r count]);
  if (isDeferred(r)) return [r addBoth:callbackTS(self, _gotSubreddits:)];
  NSDate *d = [NSDate date];
  PREF_SET([username stringByAppendingString:@"redditslastupdated"], nsni([d timeIntervalSince1970]));
  PREF_SYNCHRONIZE;
  [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
  if (reddits) [reddits release];
  reddits = [r retain];
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
  return 3;
}


- (NSInteger)tableView:(UITableView *)aTableView 
 numberOfRowsInSection:(NSInteger)section 
{
  return section == 0 ? [builtins count] : section == 1 ? [builtins2 count] : [reddits count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return section == 0 ? nil : section == 1 ? @"My Posts" : @"Subscribed";
}


- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
  static NSString *ident = @"SubredditCell1";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:ident] autorelease];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  if (indexPath.section < 2) {
    cell.textLabel.text = [[(indexPath.section == 0 ? builtins : builtins2)
                            objectAtIndex:indexPath.row] objectAtIndex:0];
    cell.detailTextLabel.text = nil;
  } else {
    NSDictionary *s = [[reddits objectAtIndex:indexPath.row] objectForKey:@"data"];
    cell.textLabel.text = [s objectForKey:@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ subscribers", 
                               [s objectForKey:@"url"], [s objectForKey:@"subscribers"]];
  }
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  NSString *reddit = @"";
  if (indexPath.section < 2) {
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
  [reddits release];
  [username release];
  [builtins release];
  [reddits release];
  [redditViewController release];
  [detailViewController release];
  [super dealloc];
}

@end

