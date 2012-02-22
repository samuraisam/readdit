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
#import "RDBrowserController.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "NSObject+UIKitGenericErrorHandling.h"
#import "RDPileController.h"
#import "RDMagazineController.h"


static UIFont *titleLabelFont = nil;


@interface RDSubredditController (PrivateParts)
  
- (void)privateInit;
- (void)prefetchItemThumbnails;

@end


@implementation RDSubredditController

@synthesize username, reddit, splitController, browserController, didLoadFromLaunch, items;
@synthesize pileController;
@synthesize magazineController;

#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
  if (!titleLabelFont) titleLabelFont = [UIFont boldSystemFontOfSize:15];
}

- (id)initWithStyle:(UITableViewStyle)style 
{
  if ((self = [super initWithStyle:style])) {
    [self privateInit];
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    [self privateInit];
  } return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder])) {
    [self privateInit];
  } return self;
}

- (void)privateInit
{
  username = reddit = nil;
  items = EMPTY_ARRAY;
  gotFirstPage = NO;
  loadingMore = NO;
  didLoadCachedItems = NO;
  self.actionTableViewHeaderClass = [YMRefreshView class];
  currentItemIndexPath = nil;
  loadingPool = [[DKDeferredPool alloc] init];
  [loadingPool setConcurrency:4];
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

- (RDPileController *)pileController
{
  if (!pileController) {
    pileController = [[RDPileController alloc] initWithStyle:UITableViewStylePlain];
    pileController.username = self.username;
    pileController.browserController = self.browserController;
  }
  return pileController;
}

- (RDMagazineController *)magazineController
{
  if (!magazineController) {
    magazineController = [[RDMagazineController alloc] init];
  }
  return magazineController;
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
  self.navigationItem.rightBarButtonItem 
    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                  target:self action:@selector(showMagazine:)];
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
}

- (void)showPile:(UIBarButtonItem *)sender
{
  self.pileController.username = self.username;
  [self.navigationController pushViewController:self.pileController animated:YES];
}

- (void)showMagazine:(UIBarButtonItem *)sender
{
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:
                                            self.magazineController];
  self.magazineController.title = self.title;
  [self.splitController presentModalViewController:navController animated:YES];
  self.magazineController.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                   target:self.splitController
                                                   action:@selector(dismissModalViewControllerAnimated:)];
  navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  self.magazineController.dataSource = self;
  self.magazineController.items = items;
}

- (void)loadMore:(UIButton *)sender
{
  loadingMore = YES;
  [sender removeFromSuperview];
  [nextPageFooterView addSubview:nextLoadingIndicator];
  [nextLoadingIndicator startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [[[RDRedditClient sharedClient] subreddit:reddit page:next existing:items user:username]
   addBoth:callbackTS(self, _gotItems:)];
}

- (id)_gotCachedItems:(id)r
{
  if (isDeferred(r)) return [r addBoth:callbackTS(self, _gotCachedItems:)];
  [loadingPool drain];
  if ([r isKindOfClass:[NSArray class]]) {
    NSLog(@"got cached reddit: %i items", [r count]);
    items = [r objectAtIndex:0];
    next = (id)[NSNull null];
    seenItems = [[RDRedditClient sharedClient] seenItemsForSubreddit:reddit 
                                                  username:username];
  } else {
    NSLog(@"cached reddit miss %@", r);
  }
  [self.tableView reloadData];
  [self LOAD_MORE_MOTHERFUCKER];
  return r;
}

- (DKDeferred *)LOAD_MORE_MOTHERFUCKER
{
  return [(!gotFirstPage ? [[RDRedditClient sharedClient] subreddit:reddit forUsername:username]
           : [[RDRedditClient sharedClient] subreddit:reddit page:next existing:items user:username])
   addBoth:callbackTS(self, _gotItems:)];
}

- (id)_gotItems:(id)r
{
  if (isDeferred(r)) return [r addBoth:callbackTS(self, _gotItems:)];
  
  [self dataSourceDidFinishLoadingNewData];
  if (loadingMore) {
    [nextLoadingIndicator stopAnimating];
    [nextLoadingIndicator removeFromSuperview];
    [nextPageFooterView addSubview:nextButton];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }
  nextButton.enabled = YES;
  [loadingPool drain];
  
  if ([r handleErrorAndAlert:YES]) return r;
  
  NSLog(@"got Items %i", [r count]);
  if ([r isKindOfClass:[NSArray class]]) {
    items = [r objectAtIndex:0];
    next = [r objectAtIndex:1];
    nextButton.enabled = ![next isEqual:[NSNull null]];
    seenItems = [[RDRedditClient sharedClient] seenItemsForSubreddit:reddit 
                                                   username:username];
    [self.tableView reloadData];
    
    [self prefetchItemThumbnails];
    
    NSDate *d = [NSDate date];
    PREF_SET(([NSString stringWithFormat:@"%@%@lastupdated", username, reddit]),
             nsni([d timeIntervalSince1970]));
    PREF_SYNCHRONIZE;
    [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
    gotFirstPage = YES;
  }
  return items;
}

- (void)prefetchItemThumbnails
{
  int idx = 0;
  for (NSDictionary *i in items) {
    id thumbnailURL = [[i objectForKey:@"data"] objectForKey:@"thumbnail"];
    if (thumbnailURL && ![thumbnailURL isEqual:[NSNull null]] && [thumbnailURL length]) {
      if ([thumbnailURL hasPrefix:@"/"]) 
        thumbnailURL = [REDDIT_URL stringByAppendingString:thumbnailURL];
      if (![[DKDeferred cache] objectForKeyInMemory:thumbnailURL]) {
        [loadingPool add:[[DKDeferred loadImage:thumbnailURL cached:YES paused:YES]
                          addCallback:curryTS(self, @selector(_didGetImageIndexPath:results:),
                                              [NSIndexPath indexPathForRow:idx inSection:0])] 
                     key:thumbnailURL];
      }
    }
    idx++;
  }  
}

- (void)setItems:(NSArray *)i
{
  items = i;
  [loadingPool drain];
  [self.tableView reloadData];
}

- (void)setReddit:(NSString *)r
{
  reddit = [r copy];
  didLoadCachedItems = NO;
}

- (void)setUsername:(NSString *)u
{
  username = [u copy];
  didLoadCachedItems = NO;
}

- (void)viewDidAppear:(BOOL)animated 
{
  [super viewDidAppear:animated];
  NSLog(@"username %@ reddit %@", username, reddit);
  currentItemIndexPath = nil;
  nextButton.frame = CGRectMake(4, 4, self.tableView.frame.size.width - 8, 44);
  nextLoadingIndicator.frame = CGRectMake(self.tableView.frame.size.width / 2 
                                          - nextLoadingIndicator.frame.size.width / 2, 12, 22, 22);
  if (username && reddit) {
    id l = PREF_KEY(([NSString stringWithFormat:@"%@%@lastupdated", username, reddit]));
    if (l) {
      NSDate *d = [NSDate dateWithTimeIntervalSince1970:[l intValue]];
      [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
    }
    nextButton.enabled = NO;
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

- (void) reloadTableViewDataSource
{
  [[[RDRedditClient sharedClient] subreddit:reddit forUsername:username]
   addBoth:callbackTS(self, _gotItems:)];
}

- (void)viewWillDisappear:(BOOL)animated
{
  currentItemIndexPath = nil;
  [loadingPool drain];
  [super viewWillDisappear:animated];
}

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
  id thumbnailURL = [[[items objectAtIndex:indexPath.row] objectForKey:@"data"] objectForKey:@"thumbnail"];
  BOOL useThumbnail = thumbnailURL && ![thumbnailURL isEqual:[NSNull null]] && [thumbnailURL length];
  
  CGFloat w = tableView.frame.size.width;
  CGSize s = [t sizeWithFont:titleLabelFont constrainedToSize:
              CGSizeMake(w - 67 - (useThumbnail ? 70 : 0) , 10000) 
               lineBreakMode:UILineBreakModeWordWrap];
  CGFloat r = floor(s.height + 26 + (s.height*.15)); // woot line break FUDGE
  int macks = useThumbnail ? 79 : 54;
  return (r >= macks ? r : macks);
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{  
  static NSString *ident = @"RedditItemCell1";
  static NSString *ident2 = @"RedditItemCellPhoto1";
  
  NSDictionary *item = [[items objectAtIndex:indexPath.row] objectForKey:@"data"];
  id thumbnailURL = [item objectForKey:@"thumbnail"];
  BOOL useThumbnail = thumbnailURL && ![thumbnailURL isEqual:[NSNull null]] && [thumbnailURL length];

  RDItemCell *cell = (RDItemCell *)[tableView dequeueReusableCellWithIdentifier:
                                    (!useThumbnail ? ident : ident2)];
  if (cell == nil) {
    cell = [[[NSBundle mainBundle] loadNibNamed:
             (!useThumbnail ? @"RDItemCell" : @"RDItemCellPhoto")
              owner:nil options:nil] objectAtIndex:0];
    if (cell.thumbnail) {
      cell.thumbnail.layer.masksToBounds = YES;
      cell.thumbnail.layer.cornerRadius = 5;
    }
    cell.target = self;
    cell.addToPileAction = @selector(addToPileCell:);
  }

  [self configureCell:cell forItem:item];
  
  if (useThumbnail) {
    cell.thumbnail.image = nil;
    if ([thumbnailURL hasPrefix:@"/"])
      thumbnailURL = [REDDIT_URL stringByAppendingString:
                      [thumbnailURL stringByReplacingOccurrencesOfRegex:
                       @"^/" withString:@""]];
    id img = [[DKDeferred cache] objectForKeyInMemory:thumbnailURL];
    if (!img) {
      cell.thumbnail.image = nil;
      [loadingPool add:[[DKDeferred loadImage:thumbnailURL cached:YES paused:YES]
                        addCallback:curryTS(self, @selector(_didGetImageIndexPath:results:),
                                            indexPath)] key:thumbnailURL];
    } else {
      cell.thumbnail.image = img;
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:
(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == ([items count] - 1)) {
    if (![next isEqual:[NSNull null]]) {
      [nextButton setTitle:@"More" forState:UIControlStateNormal];
      nextButton.enabled = YES;
    } else {
      [nextButton setTitle:@"No More Available" forState:UIControlStateNormal];
      nextButton.enabled = NO;
    }
  }
}

- (id)_didGetImageIndexPath:(NSIndexPath *)indexPath results:(id)r
{
  if ([r isKindOfClass:[UIImage class]]) {
    NSArray *visible = [self.tableView indexPathsForVisibleRows];
    if ([visible containsObject:indexPath]) {
      int idx = [visible indexOfObject:indexPath];
      if (idx != NSNotFound && idx < [visible count]) {
        RDItemCell *cell = [[self.tableView visibleCells] objectAtIndex:idx];
        cell.thumbnail.image = r;
      }
    }
  }
  return nil;
}

- (void)configureCell:(RDItemCell *)cell forItem:(NSDictionary *)item
{
  cell.titleLabel.text = [item objectForKey:@"title"];
  cell.clicked = [seenItems containsObject:[item objectForKey:@"name"]];
  cell.upvoteLabel.text = [[item objectForKey:@"score"] description];
  cell.commentLabel.text = [[item objectForKey:@"num_comments"] description];
  NSDate *created = [NSDate dateWithTimeIntervalSince1970:
                     [[item objectForKey:@"created_utc"] intValue]];
  cell.infoLabel.text = [NSString stringWithFormat:@"%@ by %@", 
                         [NSDate fastStringForDisplayFromDate:created],
                         [item objectForKey:@"author"]];
  cell.userInfo = item;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  //RDBrowserController *c = (id)[(id)splitController.detailViewController topViewController];
  if (currentItemIndexPath.row == indexPath.row) return;
  id i = [[[items objectAtIndex:indexPath.row] objectForKey:@"data"] copy];
  [[RDRedditClient sharedClient] recordSeenItem:[i objectForKey:@"name"] 
                                      subreddit:reddit username:username];
  NSArray *visible = [self.tableView indexPathsForVisibleRows];
  if ([visible containsObject:indexPath]) {
    int idx = [visible indexOfObject:indexPath];
    if (idx != NSNotFound && idx < [visible count]) {
      RDItemCell *cell = [[self.tableView visibleCells] objectAtIndex:idx];
      cell.clicked = YES;
    }
  }
  browserController.item =  i;
  browserController.username = username;
  browserController.delegate = self;
  currentItemIndexPath = nil;
  currentItemIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
  NSLog(@"current index? %@", currentItemIndexPath);
}

- (void)didUpdateCurrentItem:(NSDictionary *)item
{
  if (!currentItemIndexPath) return;
  NSMutableArray *a = [NSMutableArray arrayWithArray:items];
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:
                            [a objectAtIndex:currentItemIndexPath.row]];
  [d setObject:item forKey:@"data"];
  [a replaceObjectAtIndex:currentItemIndexPath.row withObject:d];
  
  NSArray *visible = [self.tableView indexPathsForVisibleRows];
  if ([visible containsObject:currentItemIndexPath]) {
    int idx = [visible indexOfObject:currentItemIndexPath];
    if (idx != NSNotFound && idx < [visible count]) {
      RDItemCell *cell = [[self.tableView visibleCells] objectAtIndex:idx];
      [self configureCell:cell forItem:item];
    }
  }
  items = a;
}

- (void)addToPileCell:(RDItemCell *)cell
{
  NSLog(@"add To Pile %@", cell);
  [self.pileController addItem:cell.userInfo request:
   [[NSURLRequest alloc] initWithURL:
    [NSURL URLWithString:[cell.userInfo objectForKey:@"url"]]]];
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



@end

