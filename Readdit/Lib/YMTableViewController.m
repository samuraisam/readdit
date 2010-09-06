//
//  YMTableViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 7/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMTableViewController.h"


@implementation YMTableViewController

@synthesize actionTableViewHeaderClass, refreshHeaderView, reloading, useSubtitleHeader;

//- (void)loadView
//{
//  [super loadView];

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if (self.actionTableViewHeaderClass) {
    
    refreshHeaderView = [[self.actionTableViewHeaderClass alloc] initWithFrame:
                         CGRectMake(0.0f, 0.0f - self.view.bounds.size.height,
                                    self.view.frame.size.width, self.view.frame.size.height)];
    refreshHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.tableView addSubview:refreshHeaderView];
  }
  
	self.tableView.showsVerticalScrollIndicator = YES;
  
  if (self.useSubtitleHeader) {
    CGRect headerTitleSubtitleFrame = CGRectMake(0, 0, 160, 44); 
    UIView *_headerTitleSubtitleView = [[[UILabel alloc] initWithFrame:headerTitleSubtitleFrame] autorelease]; 
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor]; 
    _headerTitleSubtitleView.autoresizesSubviews = YES; 
    _headerTitleSubtitleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    CGRect titleFrame = CGRectMake(0, 2, 160, 24); 
    UILabel *titleView = [[[UILabel alloc] initWithFrame:titleFrame] autorelease]; 
    titleView.backgroundColor = [UIColor clearColor]; 
    titleView.font = [UIFont boldSystemFontOfSize:18]; 
    titleView.textAlignment = UITextAlignmentCenter; 
    titleView.textColor = [UIColor whiteColor]; 
    titleView.minimumFontSize = 13;
    titleView.lineBreakMode = UILineBreakModeTailTruncation;
    titleView.shadowColor = [UIColor darkGrayColor]; 
    titleView.shadowOffset = CGSizeMake(0, -1); 
    titleView.text = @""; 
    titleView.adjustsFontSizeToFitWidth = YES; 
    [_headerTitleSubtitleView addSubview:titleView]; 
    CGRect subtitleFrame = CGRectMake(0, 19, 160, 44-24); 
    UILabel *subtitleView = [[[UILabel alloc] initWithFrame:subtitleFrame] autorelease]; 
    subtitleView.backgroundColor = [UIColor clearColor]; 
    subtitleView.font = [UIFont boldSystemFontOfSize:13]; 
    subtitleView.textAlignment = UITextAlignmentCenter; 
    subtitleView.textColor = [UIColor colorWithWhite:.8 alpha:1]; 
    subtitleView.shadowColor = [UIColor darkGrayColor]; 
    subtitleView.shadowOffset = CGSizeMake(0, -1); 
    subtitleView.text = @""; 
    subtitleView.adjustsFontSizeToFitWidth = YES; 
    [_headerTitleSubtitleView addSubview:subtitleView]; 
    _headerTitleSubtitleView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin 
                                                 | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin); 
    self.navigationItem.titleView = _headerTitleSubtitleView;
  }
  
  
	// pre-load sounds
//	psst1Sound = [[SoundEffect alloc] initWithContentsOfFile:
//                [[NSBundle mainBundle] pathForResource:@"psst1"
//                                                ofType:@"wav"]];
//	psst2Sound  = [[SoundEffect alloc] initWithContentsOfFile:
//                 [[NSBundle mainBundle] pathForResource:@"psst2"
//                                                 ofType:@"wav"]];
//	popSound  = [[SoundEffect alloc] initWithContentsOfFile:
//               [[NSBundle mainBundle] pathForResource:@"pop"
//                                               ofType:@"wav"]];
  
}

-(void) setHeaderTitle:(NSString*)headerTitle andSubtitle:(NSString*)headerSubtitle
{ 
//  assert(self.navigationItem.titleView != nil); 
  UIView *headerTitleSubtitleView = self.navigationItem.titleView; 
  UILabel *titleView = (UILabel *)[headerTitleSubtitleView.subviews objectAtIndex:0]; 
  UILabel *subtitleView = (UILabel *)[headerTitleSubtitleView.subviews objectAtIndex:1]; 
//  assert((titleView != nil) && (subtitleView != nil) && ([titleView isKindOfClass:[UILabel class]]) 
//         && ([subtitleView isKindOfClass:[UILabel class]])); 
  titleView.text = headerSubtitle; 
  subtitleView.text = headerTitle;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  UIView *headerTitleSubtitleView = self.navigationItem.titleView; 
  UILabel *titleView = (UILabel *)[headerTitleSubtitleView.subviews objectAtIndex:0]; 
  UILabel *subtitleView = (UILabel *)[headerTitleSubtitleView.subviews objectAtIndex:1]; 
  if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
    titleView.font = [UIFont boldSystemFontOfSize:16];
    subtitleView.font = [UIFont boldSystemFontOfSize:12];
  } else {
    titleView.font = [UIFont boldSystemFontOfSize:18];
    subtitleView.font = [UIFont boldSystemFontOfSize:13];
  }
}


- (void)dealloc
{
//	[psst1Sound release];
//	[psst2Sound release];
//	[popSound release];
  if (self.actionTableViewHeaderClass)
    [refreshHeaderView release];
  [super dealloc];
}

#pragma mark State Changes

- (void) showReloadAnimationAnimated:(BOOL)animated
{
	reloading = YES;
	[refreshHeaderView toggleActivityView:YES];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
	if (animated)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		self.tableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f,
                                                   0.0f);
		[UIView commitAnimations];
	}
	else
	{
		self.tableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f,
                                                   0.0f);
	}
}

- (void) reloadTableViewDataSource
{
	NSLog(@"Please override reloadTableViewDataSource");
}

- (void)dataSourceDidFinishLoadingNewData
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	reloading = NO;
	[refreshHeaderView flipImageAnimated:NO];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.3];
	[self.tableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
	[refreshHeaderView setStatus:kPullToReloadStatus];
	[refreshHeaderView toggleActivityView:NO];
	[UIView commitAnimations];
//	[popSound play];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:
(NSInteger)section
{
  return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                           CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:CellIdentifier] autorelease];
  }
  
  // Set up the cell...
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:
(NSIndexPath *)indexPath
{
  // Navigation logic may go here.
}

#pragma mark Scrolling Overrides
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if (!reloading)
	{
		checkForRefresh = YES;  //  only check offset when dragging
	}
} 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (reloading) return;
  
	if (checkForRefresh && self.actionTableViewHeaderClass) {
		if (refreshHeaderView.isFlipped
				&& scrollView.contentOffset.y > -65.0f
				&& scrollView.contentOffset.y < 0.0f
				&& !reloading) {
			[refreshHeaderView flipImageAnimated:YES];
			[refreshHeaderView setStatus:kPullToReloadStatus];
//			[popSound play];
      
		} else if (!refreshHeaderView.isFlipped
               && scrollView.contentOffset.y < -65.0f) {
			[refreshHeaderView flipImageAnimated:YES];
			[refreshHeaderView setStatus:kReleaseToReloadStatus];
//			[psst1Sound play];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
	if (reloading) return;
  
	if (self.actionTableViewHeaderClass 
      && scrollView.contentOffset.y <= - 65.0f) {
		if([self.tableView.dataSource respondsToSelector:
				@selector(reloadTableViewDataSource)]){
			[self showReloadAnimationAnimated:YES];
//			[psst2Sound play];
			[self reloadTableViewDataSource];
		}
	}
	checkForRefresh = NO;
}

@end


//
//  UIViewController-Extended.m
//  Payday
//
//  Created by Robert on 17/12/2009.
//  Copyright 2009 Electric TopHat Ltd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@implementation UIViewController (UIViewController_Expanded)

- (void)dismissModalViewControllerWithAnimatedTransition:(UIViewControllerAnimationTransition)transition
{
	[self dismissModalViewControllerWithAnimatedTransition:transition WithDuration:0.40f];
}

- (void)presentModalViewController:(UIViewController*)viewController withAnimatedTransition:(UIViewControllerAnimationTransition)transition
{
	[self presentModalViewController:viewController withAnimatedTransition:transition WithDuration:0.40f];
}

- (void)dismissModalViewControllerWithAnimatedTransition:(UIViewControllerAnimationTransition)transition WithDuration:(float)duration
{	
	if ( transition >= UIViewControllerAnimationTransitionFlipFromLeft )
	{
		UIViewAnimationTransition trans = UIViewAnimationTransitionNone;
		switch (transition) 
		{
			case UIViewControllerAnimationTransitionFlipFromLeft:
				trans = UIViewAnimationTransitionFlipFromLeft;
				break;
			case UIViewControllerAnimationTransitionFlipFromRight:
				trans = UIViewAnimationTransitionFlipFromRight;
				break;
			case UIViewControllerAnimationTransitionCurlUp:
				trans = UIViewAnimationTransitionCurlUp;
				break;
			case UIViewControllerAnimationTransitionCurlDown:
				trans = UIViewAnimationTransitionCurlDown;
				break;
			default:
				break;
		}
		
		UIWindow * window = [[self view] window]; 
		
		[[self view] setClipsToBounds:NO];
    
		UIView * sview = [[self view] superview];
    
		[UIView beginAnimations: @"AnimatedTransition_DismissModal" context: nil];
		[UIView setAnimationTransition:trans forView:window cache:YES];
		[UIView setAnimationDuration:duration];
		[[self view] removeFromSuperview];
		[UIView commitAnimations];
    
		[sview addSubview:[self view]];
		[self dismissModalViewControllerAnimated:NO];
	}
	else if ( transition >= UIViewControllerAnimationTransitionFade )
	{
		NSString * trans = nil;
		NSString * dir   = nil;
		switch (transition) 
		{
			case UIViewControllerAnimationTransitionFade:
				trans = kCATransitionFade;
				break;
			case UIViewControllerAnimationTransitionPushFromTop:
				trans = kCATransitionPush;
				dir   = kCATransitionFromTop;
				break;
			case UIViewControllerAnimationTransitionPushFromRight:
				trans = kCATransitionPush;
				dir   = kCATransitionFromRight;
				break;
			case UIViewControllerAnimationTransitionPushFromBottom:
				trans = kCATransitionPush;
				dir   = kCATransitionFromBottom;
				break;
			case UIViewControllerAnimationTransitionPushFromLeft:
				trans = kCATransitionPush;
				dir   = kCATransitionFromLeft;
				break;
			case UIViewControllerAnimationTransitionMoveInFromTop:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromTop;
				break;
			case UIViewControllerAnimationTransitionMoveInFromRight:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromRight;
				break;
			case UIViewControllerAnimationTransitionMoveInFromBottom:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromBottom;
				break;
			case UIViewControllerAnimationTransitionMoveInFromLeft:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromLeft;
				break;
			case UIViewControllerAnimationTransitionRevealFromTop:
				trans = kCATransitionReveal;
				dir   = kCATransitionFromTop;
				break;
			case UIViewControllerAnimationTransitionRevealFromRight:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromRight;
				break;
			case UIViewControllerAnimationTransitionRevealFromBottom:
				trans = kCATransitionReveal;
				dir   = kCATransitionFromBottom;
				break;
			case UIViewControllerAnimationTransitionRevealFromLeft:
				trans = kCATransitionReveal;
				dir   = kCATransitionFromLeft;
				break;
			default:
				break;
		}
		
		UIWindow * window = [[self view] window];
		
		[[self.parentViewController view] setClipsToBounds:NO];
    
		// Set up the animation
		CATransition *animation = [CATransition animation];
		[animation setType:trans];
		[animation setSubtype:dir];
		
		// Set the duration and timing function of the transtion -- duration is passed in as a parameter, use ease in/ease out as the timing function
		[animation setDuration:duration];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
		[[window layer] addAnimation:animation forKey:@"AnimateTransition"];
		
		[self dismissModalViewControllerAnimated:NO];
	}
	else
	{
		[self dismissModalViewControllerAnimated:NO];
	}
  
}

- (void)presentModalViewController:(UIViewController*)viewController withAnimatedTransition:(UIViewControllerAnimationTransition)transition WithDuration:(float)duration
{
	if ( transition >= UIViewControllerAnimationTransitionFlipFromLeft )
	{
		UIViewAnimationTransition trans = UIViewAnimationTransitionNone;
		switch (transition) {
			case UIViewControllerAnimationTransitionFlipFromLeft:
				trans = UIViewAnimationTransitionFlipFromLeft;
				break;
			case UIViewControllerAnimationTransitionFlipFromRight:
				trans = UIViewAnimationTransitionFlipFromRight;
				break;
			case UIViewControllerAnimationTransitionCurlUp:
				trans = UIViewAnimationTransitionCurlUp;
				break;
			case UIViewControllerAnimationTransitionCurlDown:
				trans = UIViewAnimationTransitionCurlDown;
				break;
			default:
				break;
		}
		
		UIWindow * window = [[self view] window]; 
		UIView * sview = [[self view] superview];
		
		[[viewController view] setClipsToBounds:NO];
    
		[UIView beginAnimations: @"AnimatedTransition_PresentModal" context: viewController];
		[UIView setAnimationTransition:trans forView:window cache:YES];
		[UIView setAnimationDuration:duration];
		
		//[[viewController view] removeFromSuperview];
		[sview addSubview:[viewController view]];
		
		[UIView commitAnimations];
		
		[self presentModalViewController:viewController animated:NO];
	}
	else if ( transition >= UIViewControllerAnimationTransitionFade )
	{
		NSString * trans = nil;
		NSString * dir   = nil;
		switch (transition) 
		{
			case UIViewControllerAnimationTransitionFade:
				trans = kCATransitionFade;
				break;
			case UIViewControllerAnimationTransitionPushFromTop:
				trans = kCATransitionPush;
				dir   = kCATransitionFromTop;
				break;
			case UIViewControllerAnimationTransitionPushFromRight:
				trans = kCATransitionPush;
				dir   = kCATransitionFromRight;
				break;
			case UIViewControllerAnimationTransitionPushFromBottom:
				trans = kCATransitionPush;
				dir   = kCATransitionFromBottom;
				break;
			case UIViewControllerAnimationTransitionPushFromLeft:
				trans = kCATransitionPush;
				dir   = kCATransitionFromLeft;
				break;
			case UIViewControllerAnimationTransitionMoveInFromTop:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromTop;
				break;
			case UIViewControllerAnimationTransitionMoveInFromRight:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromRight;
				break;
			case UIViewControllerAnimationTransitionMoveInFromBottom:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromBottom;
				break;
			case UIViewControllerAnimationTransitionMoveInFromLeft:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromLeft;
				break;
			case UIViewControllerAnimationTransitionRevealFromTop:
				trans = kCATransitionReveal;
				dir   = kCATransitionFromTop;
				break;
			case UIViewControllerAnimationTransitionRevealFromRight:
				trans = kCATransitionMoveIn;
				dir   = kCATransitionFromRight;
				break;
			case UIViewControllerAnimationTransitionRevealFromBottom:
				trans = kCATransitionReveal;
				dir   = kCATransitionFromBottom;
				break;
			case UIViewControllerAnimationTransitionRevealFromLeft:
				trans = kCATransitionReveal;
				dir   = kCATransitionFromLeft;
				break;
			default:
				break;
		}
		
		UIWindow * window = [[self view] window];
    
		[[viewController view] setClipsToBounds:NO];
		
		// Set up the animation
		CATransition *animation = [CATransition animation];
		[animation setType:trans];
		[animation setSubtype:dir];
    
		// Set the duration and timing function of the transtion -- duration is passed in as a parameter, use ease in/ease out as the timing function
		[animation setDuration:duration];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		
		[[window layer] addAnimation:animation forKey:@"AnimateTransition"];
		
		[self presentModalViewController:viewController animated:NO];
	}
	else 
	{
		[self presentModalViewController:viewController animated:NO];
	}
}

@end