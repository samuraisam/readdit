//
//  YMRefreshView.h
//  Yammer
//
//  Created by Samuel Sutch on 7/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kReleaseToReloadStatus 0
#define kPullToReloadStatus 1
#define kLoadingStatus 2

@protocol ActionTableViewHeader

- (void)flipImageAnimated:(BOOL)animated;
- (void)toggleActivityView:(BOOL)isON;
- (void)setStatus:(int)status;

@property BOOL isFlipped;

@end


@interface YMRefreshView : UIView <ActionTableViewHeader> {
  
	UILabel *lastUpdatedLabel;
	UILabel *statusLabel;
	UIImageView *arrowImage;
	UIActivityIndicatorView *activityView;
  
	BOOL isFlipped;
  
	NSDate *lastUpdatedDate;
}

@property (nonatomic, retain) NSDate *lastUpdatedDate;


@end
