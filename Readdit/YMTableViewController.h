//
//  YMTableViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 7/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMRefreshView.h"


@interface YMTableViewController : UITableViewController
{
	UIView<ActionTableViewHeader> *refreshHeaderView;
  
	BOOL checkForRefresh;
	BOOL reloading;
  BOOL useSubtitleHeader;
  
  Class actionTableViewHeaderClass;
  NSString *subtitle;
  
//	SoundEffect *psst1Sound;
//	SoundEffect *psst2Sound;
//	SoundEffect *popSound;
}

@property(assign) Class actionTableViewHeaderClass;
@property(readonly) UIView<ActionTableViewHeader> *refreshHeaderView;
@property(readonly) BOOL reloading;
@property(assign) BOOL useSubtitleHeader;

- (void)dataSourceDidFinishLoadingNewData;
- (void) showReloadAnimationAnimated:(BOOL)animated;
-(void) setHeaderTitle:(NSString*)headerTitle andSubtitle:(NSString*)headerSubtitle;

@end

//
//  UIViewController-Extended.h
//  Payday
//
//  Created by Robert on 17/12/2009.
//  Copyright 2009 Electric TopHat Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum 
{
	UIViewControllerAnimationTransitionNone = 0,
	UIViewControllerAnimationTransitionFade,
	UIViewControllerAnimationTransitionPushFromTop,
	UIViewControllerAnimationTransitionPushFromRight,
	UIViewControllerAnimationTransitionPushFromBottom,
	UIViewControllerAnimationTransitionPushFromLeft,
	UIViewControllerAnimationTransitionMoveInFromTop,
	UIViewControllerAnimationTransitionMoveInFromRight,
	UIViewControllerAnimationTransitionMoveInFromBottom,
	UIViewControllerAnimationTransitionMoveInFromLeft,
	UIViewControllerAnimationTransitionRevealFromTop,
	UIViewControllerAnimationTransitionRevealFromRight,
	UIViewControllerAnimationTransitionRevealFromBottom,
	UIViewControllerAnimationTransitionRevealFromLeft,
	
	UIViewControllerAnimationTransitionFlipFromLeft,
	UIViewControllerAnimationTransitionFlipFromRight,
	UIViewControllerAnimationTransitionCurlUp,
	UIViewControllerAnimationTransitionCurlDown,
} UIViewControllerAnimationTransition;

@interface UIViewController (UIViewController_Expanded) 

- (void)dismissModalViewControllerWithAnimatedTransition:(UIViewControllerAnimationTransition)transition;
- (void)presentModalViewController:(UIViewController*)viewController withAnimatedTransition:(UIViewControllerAnimationTransition)transition;

- (void)dismissModalViewControllerWithAnimatedTransition:(UIViewControllerAnimationTransition)transition WithDuration:(float)duration;
- (void)presentModalViewController:(UIViewController*)viewController withAnimatedTransition:(UIViewControllerAnimationTransition)transition WithDuration:(float)duration;

@end