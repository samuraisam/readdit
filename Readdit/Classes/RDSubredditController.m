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


static UIFont *titleLabelFont = nil;


@interface RDSubredditController (PrivateParts)
  
- (void)privateInit;
- (void)prefetchItemThumbnails;

@end


@implementation RDSubredditController

@synthesize username, reddit, splitController, browserController, didLoadFromLaunch, items;

#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
  if (!titleLabelFont) titleLabelFont = [[UIFont boldSystemFontOfSize:15] retain];
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
  items = [EMPTY_ARRAY retain];
  didLoadCachedItems = NO;
  self.actionTableViewHeaderClass = [YMRefreshView class];
  currentItemIndexPath = nil;
  loadingPool = [[DKDeferredPool alloc] init];
  [loadingPool setConcurrency:1];
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
  [loadingPool drain];
  if ([r isKindOfClass:[NSArray class]]) {
    NSLog(@"got cached reddit: %i items", [r count]);
    if (items) [items release];
    items = [r retain];
    [self prefetchItemThumbnails];
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
  
  [self dataSourceDidFinishLoadingNewData];
  [loadingPool drain];
  [self.tableView reloadData];
  
  if ([r handleErrorAndAlert:YES]) return r;
  
  NSLog(@"got Items %i", [r count]);
  if ([r isKindOfClass:[NSArray class]]) {
    if (items) [items release];
    items = [r retain];
    
    [self prefetchItemThumbnails];
    
    NSDate *d = [NSDate date];
    PREF_SET(([NSString stringWithFormat:@"%@%@lastupdated", username, reddit]),
             nsni([d timeIntervalSince1970]));
    PREF_SYNCHRONIZE;
    [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
  }
  return r;
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
  if (items) [items release];
  items = [i retain];
  [loadingPool drain];
  [self.tableView reloadData];
}

- (void)setReddit:(NSString *)r
{
  if (reddit) [reddit release];
  reddit = [r copy];
  didLoadCachedItems = NO;
}

- (void)setUsername:(NSString *)u
{
  if (username) [username release];
  username = [u copy];
  didLoadCachedItems = NO;
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

// Customize the appearance of table view cells.
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
  cell.upvoteLabel.text = [[item objectForKey:@"score"] description];
  cell.commentLabel.text = [[item objectForKey:@"num_comments"] description];
  NSDate *created = [NSDate dateWithTimeIntervalSince1970:
                     [[item objectForKey:@"created_utc"] intValue]];
  cell.infoLabel.text = [NSString stringWithFormat:@"%@ by %@", 
                         [NSDate fastStringForDisplayFromDate:created],
                         [item objectForKey:@"author"]];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  //RDBrowserController *c = (id)[(id)splitController.detailViewController topViewController];
  if (currentItemIndexPath.row == indexPath.row) return;
  id i = [[[items objectAtIndex:indexPath.row] objectForKey:@"data"] copy];
  browserController.item =  i;
  browserController.username = username;
  browserController.delegate = self;
  currentItemIndexPath = nil;
  currentItemIndexPath = [[NSIndexPath indexPathForRow:indexPath.row inSection:0] retain];
  NSLog(@"current index? %@", currentItemIndexPath);
  [i release];
}

- (void)didUpdateCurrentItem:(NSDictionary *)item
{
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
  [items release];
  items = [a retain];
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
  [browserController release];
  [items release];
  [splitController release];
  [username release];
  [reddit release];
  [super dealloc];
}


@end

