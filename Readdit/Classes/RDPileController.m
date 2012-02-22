//
//  RDPileController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDPileController.h"
#import "RDPileItemCell.h"
#import "RDBrowserController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>


@interface RDPileItemContainer : UIImageView <UIWebViewDelegate>
{
  UIWebView *webView;
  NSURLRequest *request;
  BOOL didFinish;
  NSDictionary *item;
}

@property(nonatomic) NSURLRequest *request;
@property(nonatomic) NSDictionary *item;
- (void)ohShit:(id)srsly;

@end


@implementation RDPileItemContainer

@synthesize request, item;

- (id)initWithFrame:(CGRect)rect
{
  if ((self = [super initWithFrame:rect])) {
    didFinish = NO;
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.clipsToBounds = YES;
  }
  return self;
}

- (void)setRequest:(NSURLRequest *)req
{
  request = req;
  CGRect f = CGRectMake(0, 0, 600, 225);
  if (!webView) webView = [[UIWebView alloc] initWithFrame:f];
  else webView.frame = f;
  webView.scalesPageToFit = YES;
  webView.delegate = self;
  webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [webView loadRequest:req];
}

- (void)webViewDidFinishLoad:(UIWebView *)v
{
  UIGraphicsBeginImageContext(CGSizeMake(600, 222));
  CGContextRef context = UIGraphicsGetCurrentContext();
  [v.layer renderInContext:context];
  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  self.image = img;
  UIGraphicsEndImageContext();
  didFinish = YES;
}

- (void)ohShit:(id)srsly;
{
  if(!srsly && !didFinish) return;
  webView = nil;
}


@end


@implementation RDPileController

@synthesize browserController, username;

#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style 
{
  if ((self = [super initWithStyle:style])) {
    items = [[NSMutableArray alloc] init];
    memoryWarningCount = 0;
  }
  return self;
}

- (void)addItem:(NSDictionary *)item request:(NSURLRequest *)req
{
  RDPileItemContainer *c = [[RDPileItemContainer alloc] initWithFrame:
                             CGRectMake(0, 0, 320, 320)];
  c.item = item;
  c.request = req;
  [items addObject:c];
  [self.tableView reloadData];
  self.title = [NSString stringWithFormat:@"Pile (%i)", items.count];
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad 
{
  [super viewDidLoad];
  self.clearsSelectionOnViewWillAppear = NO;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  NSLog(@"items %@", items);
  self.title = [NSString stringWithFormat:@"Pile (%i)", items.count];
  [self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
//  NSArray *tests = array_(@"http://github.com/samuraisam", @"http://ssutch.org", @"http://news.ycombinator.com", @"http://arstechnica.com",
//                          @"http://praveenmatanam.wordpress.com/2009/04/03/how-to-disable-uiwebview-from-user-scrolling/",
//                          @"http://github.com/samuraisam/SQLitePersistentObjects/blob/master/src/NSObject-SQLitePersistence.m",
//                          @"http://slashdot.org", @"http://skunkpost.com/news.sp?newsId=3196", @"http://i.imgur.com/Ih2BJ.png", 
//                          @"http://imgur.com/jacoj", @"http://i.imgur.com/aIW2e.jpg", @"http://blog.phusion.nl/2010/09/15/phusion-passenger-3-0-0-public-beta-1-is-out/",
//                          @"http://www.wired.com/rawfile/2010/09/nick-gleis/?utm_source=feedburner&utm_medium=feed&utm_campaign="
//                          "Feed:+wired/index+(Wired:+Index+3+(Top+Stories+2))&utm_content=Twitter&pid=69&viewall=true",
//                          @"http://www.youtube.com/watch?v=lPuGJM_0DwI&has_verified=1");
//  for (NSString *t in tests) {
//    [self addItem:EMPTY_DICT request:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:t]]];
//  }
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
(UIInterfaceOrientation)interfaceOrientation 
{
  return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:
(NSInteger)section 
{
  return [items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 140;
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
  static NSString *ident = @"PileItem1";

  RDPileItemCell *cell = (RDPileItemCell *)[tableView dequeueReusableCellWithIdentifier:ident];
  if (cell == nil) {
    cell = [[[NSBundle mainBundle] loadNibNamed:@"RDPileItemCell" 
                                    owner:nil options:nil] objectAtIndex:0];
    cell.target = self;
    cell.closeAction = @selector(closeItem:);
  }
  
  [[cell.button viewWithTag:101] removeFromSuperview];
  RDPileItemContainer *con = [items objectAtIndex:indexPath.row];
  con.tag = 101;
  con.frame = CGRectMake(13, 13, cell.button.frame.size.width - 26, 
                         cell.button.frame.size.height - 26);
  cell.userInfo = indexPath;
  cell.titleLabel.text = [con.item objectForKey:@"title"];
  [cell.button addSubview:con];

  return cell;
}

- (void)closeItem:(RDPileItemCell *)cell
{
  if (closing) return;
  closing = YES;
  NSIndexPath *indexPath = [cell.userInfo copy];
  NSLog(@"indexPath %@", indexPath);
  [items removeObjectAtIndex:indexPath.row];
  [self.tableView deleteRowsAtIndexPaths:array_(indexPath) 
                        withRowAnimation:UITableViewRowAnimationTop];
  [self performSelector:@selector(didClose:) withObject:indexPath afterDelay:.5];
}

- (void)didClose:(NSIndexPath *)indexPath
{
  closing = NO;
  int row = indexPath.row == 0 ? 0 : indexPath.row - 1;
  NSIndexPath *new = [NSIndexPath indexPathForRow:row inSection:0];
  NSLog(@"row %i indexPath %@", row, new);
  self.title = [NSString stringWithFormat:@"Pile (%i)", items.count];
  [self.tableView reloadData];
  if ([items count])
    [self performSelector:@selector(selectNext:) withObject:new afterDelay:.1];
}

- (void)selectNext:(NSIndexPath *)indexPath
{
  [self.tableView selectRowAtIndexPath:indexPath animated:
   YES scrollPosition:UITableViewScrollPositionNone];
  NSDictionary *item = [[items objectAtIndex:indexPath.row] item];
  self.browserController.username = self.username;
  self.browserController.item = item;
  self.browserController.delegate = nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:
(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  cell.backgroundColor = [UIColor clearColor];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:
(NSIndexPath *)indexPath 
{
  NSDictionary *item = [[items objectAtIndex:indexPath.row] item];
  self.browserController.username = self.username;
  self.browserController.item = item;
  self.browserController.delegate = nil;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
  memoryWarningCount += 1;
  [items makeObjectsPerformSelector:@selector(ohShit:) withObject:
   (memoryWarningCount > 2 ? [NSNull null] : nil)];
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
  NSLog(@"viewDidUnload %@", self);
  [items makeObjectsPerformSelector:@selector(ohShit:) withObject:[NSNull null]];
}



@end

