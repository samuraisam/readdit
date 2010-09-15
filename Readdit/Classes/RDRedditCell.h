//
//  RDRedditCell.h
//  Readdit
//
//  Created by Samuel Sutch on 9/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDRedditCell : UITableViewCell 
{
  IBOutlet UILabel *titleLabel, *subtitleLabel;
  IBOutlet UIButton *subscribeButton;
  IBOutlet UIActivityIndicatorView *activityIndicator;
  BOOL loading, subscribed;
  id target;
  SEL subscribeAction;
  id userInfo;
}

@property(nonatomic, retain) UILabel *titleLabel, *subtitleLabel;
@property(nonatomic, retain) UIButton *subscribeButton;
@property(nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property(nonatomic, assign) BOOL loading, subscribed;
@property(nonatomic, assign) id target;
@property(nonatomic, retain) id userInfo;
@property(nonatomic, assign) SEL subscribeAction;

- (IBAction)subscribe:(id)sender;

@end
