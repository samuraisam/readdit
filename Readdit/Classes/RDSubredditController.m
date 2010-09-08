//
//  YMSubredditController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDSubredditController.h"
#import "YMRefreshView.h"
#import "RDRedditClient.h"
#import "RDItemCell.h"
#import "NSDate+Helper.h"
#import "RDBrowserController.h"
#import <CoreGraphics/CoreGraphics.h>


@implementation RDSubredditController

@synthesize username, reddit, splitController;

#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style 
{
  if ((self = [super initWithStyle:style])) {
    username = reddit = nil;
    items = [EMPTY_ARRAY retain];
    didLoadCachedItems = NO;
    self.actionTableViewHeaderClass = [YMRefreshView class];
  }
  return self;
}

#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/


- (void)viewWillAppear:(BOOL)animated 
{
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  self.tableView.separatorColor = [UIColor colorWithHexString:@"8c9ba4"];
  self.tableView.backgroundColor = [UIColor colorWithHexString:@"8c9ba4"];
  [super viewWillAppear:animated];
}

- (id)_gotCachedItems:(id)r
{
  if (isDeferred(r)) return [r addBoth:callbackTS(self, _gotCachedItems:)];
  if ([r isKindOfClass:[NSArray class]]) {
    NSLog(@"got cached reddit: %i items", [r count]);
    if (items) [items release];
    items = [r retain];
  } else {
    NSLog(@"cached reddit miss %@", r);
  }
  [self.tableView reloadData];
  [[[RDRedditClient sharedClient] subreddit:reddit forUsername:username]
   addBoth:callbackTS(self, _gotItems:)];
  return r;
}

- (id)_gotItems:(id)r
{
  if (isDeferred(r)) return [r addBoth:callbackTS(self, _gotItems:)];
  NSLog(@"got Items %i", [r count]);
  if ([r isKindOfClass:[NSArray class]]) {
    if (items) [items release];
    items = [r retain];
    NSDate *d = [NSDate date];
    PREF_SET(([NSString stringWithFormat:@"%@%@lastupdated", username, reddit]), nsni([d timeIntervalSince1970]));
    PREF_SYNCHRONIZE;
    [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
    [self dataSourceDidFinishLoadingNewData];
    [self.tableView reloadData];
  }
  return r;
}


- (void)viewDidAppear:(BOOL)animated 
{
  [super viewDidAppear:animated];
  NSLog(@"username %@ reddit %@", username, reddit);
  if (username && reddit) {
    id l = PREF_KEY(([NSString stringWithFormat:@"%@%@lastupdated", username, reddit]));
    if (l) {
      NSDate *d = [NSDate dateWithTimeIntervalSince1970:[l intValue]];
      [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
    }
    if (!didLoadCachedItems) {
      [[[RDRedditClient sharedClient] cachedSubreddit:reddit forUsername:username]
       addBoth:callbackTS(self, _gotCachedItems:)];
    } else {
      [[[RDRedditClient sharedClient] subreddit:reddit forUsername:username]
       addBoth:callbackTS(self, _gotItems:)];
    }
    [self showReloadAnimationAnimated:YES];
  }
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


- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  return [items count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *t = [[[items objectAtIndex:indexPath.row] objectForKey:@"data"] objectForKey:@"title"];
  CGFloat w = tableView.frame.size.width;
  CGSize s = [t sizeWithFont:[UIFont boldSystemFontOfSize:15] constrainedToSize:
              CGSizeMake(w - 67 , 10000) lineBreakMode:UILineBreakModeWordWrap];
  CGFloat r = floor(s.height + 26 + (s.height*.15)); // woot line break FUDGE
  return (r >= 54 ? r : 54);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{  
  static NSString *ident = @"RedditItemCell1";

  RDItemCell *cell = (RDItemCell *)[tableView dequeueReusableCellWithIdentifier:ident];
  if (cell == nil) {
    cell = [[[NSBundle mainBundle] loadNibNamed:@"RDItemCell" owner:nil 
                                        options:nil] objectAtIndex:0];
  }
  
  NSDictionary *item = [[items objectAtIndex:indexPath.row] objectForKey:@"data"];
  cell.titleLabel.text = [item objectForKey:@"title"];
  cell.upvoteLabel.text = [[item objectForKey:@"score"] description];
  cell.commentLabel.text = [[item objectForKey:@"num_comments"] description];
  NSDate *created = [NSDate dateWithTimeIntervalSince1970:
                     [[item objectForKey:@"created_utc"] intValue]];
  cell.infoLabel.text = [NSString stringWithFormat:@"%@ by %@", 
                         [created stringDaysAgo], [item objectForKey:@"author"]];
  
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  RDBrowserController *c = (id)[(id)splitController.detailViewController topViewController];
  c.item = [[items objectAtIndex:indexPath.row] objectForKey:@"data"];
  c.username = username;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
}


- (void)dealloc 
{
  [items release];
  [splitController release];
  [username release];
  [reddit release];
  [super dealloc];
}


@end

