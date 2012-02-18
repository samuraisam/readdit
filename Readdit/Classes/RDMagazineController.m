    //
//  RDMagazineController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDMagazineController.h"
#import <QuartzCore/QuartzCore.h>
#import "RDBrowserController.h"


#define degreesToRadians(x) (M_PI * x / 180.0)


@implementation RDMagazineImage

@synthesize delegate, touchAction;

- (id)initWithCoder:(NSCoder *)a
{
  if ((self = [super initWithCoder:a])) {
    UIGestureRecognizer *r = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
    [self addGestureRecognizer:r];
  }
  return self;
}

- (void)handleGesture:(id)r
{
  if (delegate && [delegate respondsToSelector:touchAction]) {
    [delegate performSelector:touchAction withObject:self];
  }
}

@end

@implementation RDMagazineColumn

@synthesize selectAction, delegate, imageViews, labelViews, smokeViews, userData;

//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdent
//{
  //if ((self = [super initWithStyle:style reuiseIdentifier:reuseIdent])) {
  //}
  //return self;
//}

//- (void)setRows:(NSArray *)ra
//{
  //if (rows) [rows release];
  //rows = [ra retain];
  //if (rowViews) [rowViews release];
  //rowViews = [NSMutableArray new];
  //for (id r in rows) {
    //UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mag-noimg.png"] autorelease];
    //[rowViews addObject:img];
  //}
//}

//- (void)layoutSubviews
//{}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder])) {
    NSMutableArray *imgs = [NSMutableArray array];
    NSMutableArray *labs = [NSMutableArray array];
    NSMutableArray *smks = [NSMutableArray array];
    for (int i = 0; i < 4; i++) {
      RDMagazineImage *imgv = (RDMagazineImage *)[self.contentView viewWithTag:i+1];
      imgv.delegate = self;
      imgv.touchAction = @selector(didTouchImage:);

      [imgs addObject:imgv];
      [labs addObject:[self.contentView viewWithTag:(i+1)*10]];
      [smks addObject:[self.contentView viewWithTag:(i+1)*100]];
    }
    smokeViews = [smks retain];
    imageViews = [imgs retain];
    labelViews = [labs retain];
  }
  return self;
}

- (void)didTouchImage:(RDMagazineImage *)img
{
  if (delegate && [delegate respondsToSelector:selectAction]) {
    [delegate performSelector:selectAction withObject:
     array_(userData, nsni([self.imageViews indexOfObject:img]))];
  }
}

- (void)dealloc
{
  [smokeViews release];
  [imageViews release];
  [labelViews release];
  [userData release];
  [super dealloc];
}

@end


@implementation RDMagazineController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

@synthesize browserController, dataSource;

- (id)init
{
  if ((self = [super init])) {
    loadingPool = [[DKDeferredPool alloc] init];
    [loadingPool setConcurrency:4];
    loadingMore = NO;
    cachePool = [[DKDeferredPool alloc] init];
    [cachePool setConcurrency:1];
  }
  return self;
}

@synthesize items, currentCell, currentIndex;

- (void)setItems:(NSArray *)itemss
{
  BOOL landscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
  int nrows = landscape ? 4 : 5;
  NSMutableArray *cols = [NSMutableArray array];
  int i, c = [itemss count];

  for (i = 0; i < c; i += nrows) {
    [cols addObject:[itemss objectsAtIndexes:
     [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, MIN(nrows, c-i))]]];
  }
  
  scrollView.contentSize = CGSizeMake([cols count] * 170, scrollView.frame.size.height);

  if (columns) [columns release];
  NSLog(@"columns rows %i columns %i %@", nrows, [cols count], 
        NSStringFromCGSize(scrollView.contentSize));
  columns = [cols retain];
}

- (void)loadView 
{
  //if (!scrollView) {
    //scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 700, 700)];
    //scrollView.delegate = self;
    //scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
  //}
  if (!tableView) {
    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,700,700) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    //tableView.layer.anchorPoint = CGPointMake(0,0);
    tableView.backgroundColor = [UIColor blackColor];
    tableView.transform = CGAffineTransformRotate(tableView.transform, degreesToRadians(270));
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.allowsSelection = NO;
  }
  self.view = tableView;
}

- (void)viewDidAppear:(BOOL)animated
{
  [tableView reloadData];
  BOOL l = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
  tableView.frame = l ? CGRectMake(0,0,1024,704) : CGRectMake(0,0,768,960);
  [super viewDidAppear:animated];
}

//- (void)scrollViewDidScroll:(UIScrollView *)sv
//{
//  NSLog(@"scrollViewDidScroll %@", sv);
//}

- (NSInteger)numberOfSectionsInTableView:(id)v { return 1; }
- (NSInteger)tableView:(id)v numberOfRowsInSection:(NSInteger)s { return [columns count]; }
- (CGFloat)tableView:(id)v heightForRowAtIndexPath:(NSIndexPath *)i { 
  BOOL l = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
  //return l ? 214 : 200;
  return 176;
}
- (UITableViewCell *)tableView:(id)v cellForRowAtIndexPath:(NSIndexPath *)path
{
  BOOL landscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
  NSString *ident = landscape ? @"RDMagazineColumnLandscape" : @"RDMagazineColumnPortrait";
  RDMagazineColumn *cell = (RDMagazineColumn *)[v dequeueReusableCellWithIdentifier:ident];
  if (!cell) {
    cell = [[[NSBundle mainBundle] loadNibNamed:ident owner:nil options:nil] objectAtIndex:0];
    cell.transform = CGAffineTransformRotate(cell.transform, degreesToRadians(270));
    //cell.frame = CGRectMake(0,0,(landscape ? 1024 : 768),(landscape ? 214 : 200));
    for (UIView *v in cell.subviews) {
      v.transform = CGAffineTransformRotate(cell.transform, degreesToRadians(270));
    }
  }
  self.currentCell = cell;
  self.currentIndex = path.row;
  int r = 0;
  for (NSDictionary *item in [columns objectAtIndex:path.row]) {
    UIImageView *imageView = [cell.imageViews objectAtIndex:r];
    UILabel *label = [cell.labelViews objectAtIndex:r];
    [[cell.smokeViews objectAtIndex:r] setHidden:NO];
    cell.userData = nsni(path.row);
    cell.delegate = self;
    cell.selectAction = @selector(didSelectObjectAtCoordinates:);
    label.hidden = imageView.hidden = NO;
    label.text = [[item objectForKey:@"data"] objectForKey:@"title"];
    NSString *thumbnailURL = [NSString stringWithFormat:
                              @"http://ws1.craigsfishapp.com/api/v1/thumbnail/from_address/?u=%@&h=175&w=175&m=fill", 
                              [[[item objectForKey:@"data"] objectForKey:@"url"] 
                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    id img = [[DKDeferred cache] objectForKeyInMemory:thumbnailURL];
    if (!img) {
      imageView.image = [UIImage imageNamed:@"mag-noimg.png"];
      id pool = [[DKDeferred cache] hasKey:thumbnailURL] ? cachePool : loadingPool;
      [pool add:[[DKDeferred loadImage:thumbnailURL cached:YES paused:YES]
           addCallback:curryTS(self, @selector(_didGetImageRow:column:results:),
                               nsni(r), nsni(path.row))] key:thumbnailURL];
    } else imageView.image = img;
    r++;
  }
  if (r < 4) {
    for (; r < 4; r++) {
      [[cell.imageViews objectAtIndex:r] setHidden:YES];
      [[cell.labelViews objectAtIndex:r] setHidden:YES];
      [[cell.smokeViews objectAtIndex:r] setHidden:YES];
      cell.userData = nil;
      cell.delegate = nil;
      cell.selectAction = NULL;
    }
  }
  return cell;
}

- (void)didSelectObjectAtCoordinates:(NSArray *)coords
{
  int c = intv([coords objectAtIndex:0]), r = intv([coords objectAtIndex:1]);
  NSDictionary *d = [[columns objectAtIndex:c] objectAtIndex:r];
  NSLog(@"d: %@", d);
  RDBrowserController *b = self.browserController;
  b.modalPresentationStyle = UIModalPresentationFullScreen;
  b.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self.navigationController presentModalViewController:b animated:YES];
  b.item = [d objectForKey:@"data"];
  b.username = nil;
  b.delegate = self;
}

- (void)closeBrowser:(id)s
{
  [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (id)_didGetImageRow:(NSNumber *)row column:(NSNumber *)col results:(id)r
{
  int ruh = intv(row), c = intv(col);
  if ([r isKindOfClass:[UIImage class]]) {
    RDMagazineColumn *cell = nil;
    if (c == self.currentIndex) cell = self.currentCell;
    else {
      NSArray *visible = [tableView indexPathsForVisibleRows];
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:c inSection:0];
      if ([visible containsObject:indexPath]) {
        int idx = [visible indexOfObject:indexPath];
        if (idx != NSNotFound && idx < [visible count])
          cell = [[tableView visibleCells] objectAtIndex:idx];
      }
    }
    if (cell) {
      UIImageView *imageView = [cell.imageViews objectAtIndex:ruh];
      imageView.image = r;
    }
  }
  return r;
}

- (NSIndexPath *)tableView:(id)v willSelectRowAtIndexPath:(NSIndexPath *)p
{
  return nil;
}

- (void)tableView:(id)v willDisplayCell:(id)c forRowAtIndexPath:(NSIndexPath *)path
{
//  NSLog(@"displaycelL?? %@", path);
  if (!loadingMore && path.row == [columns count] - 1) {
    loadingMore = YES;
//    NSLog(@"loading more???");
    [[dataSource LOAD_MORE_MOTHERFUCKER] addBoth:callbackTS(self, _doneLoadingItems:)];
  }
}

- (id)_doneLoadingItems:(id)r
{
//  NSLog(@"doneLoadingi %@", r);
  if ([r isKindOfClass:[NSArray class]]) {
    self.items = r;
  }
  loadingMore = NO;
  [tableView reloadData];
  return r;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (RDBrowserController *)browserController
{
  if (!browserController) {
    browserController = [[RDBrowserController alloc] init];
  }
  return browserController;
}


- (void)viewDidUnload
{
  [loadingPool drain];
  [cachePool drain];
  NSLog(@"viewDidUnload %@", self);
  [browserController release];
  browserController = nil;
  self.dataSource = nil;
  [super viewDidUnload];
}


- (void)dealloc 
{
  [loadingPool release];
  [tableView release];
  [columns release];
  [cachePool release];
  [super dealloc];
}


@end
