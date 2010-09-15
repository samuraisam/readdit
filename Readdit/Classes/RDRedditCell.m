//
//  RDRedditCell.m
//  Readdit
//
//  Created by Samuel Sutch on 9/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDRedditCell.h"


@implementation RDRedditCell

@synthesize activityIndicator, loading, titleLabel, subtitleLabel, subscribeButton, 
            subscribed, target, subscribeAction, userInfo;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setLoading:(BOOL)l
{
  if (loading != l) {
    if (l) {
      subscribeButton.hidden = YES;
      [activityIndicator startAnimating];
    } else {
      subscribeButton.hidden = NO;
      [activityIndicator stopAnimating];
    }
  }
  loading = l;
}

- (void)setSubscribed:(BOOL)s
{
  if (s != subscribed) {
    if (s) {
      [subscribeButton setBackgroundImage:
       [UIImage imageNamed:@"unsubscribebutton.png"] forState:UIControlStateNormal];
    } else {
      [subscribeButton setBackgroundImage:
       [UIImage imageNamed:@"subscribebutton.png"] forState:UIControlStateNormal];
    }
  }
  subscribed = s;
}

- (void)subscribe:(id)sender
{
  if (target && subscribeAction) {
    [target performSelector:subscribeAction withObject:self];
  }
}

- (void)dealloc 
{
  [activityIndicator release];
  [titleLabel release];
  [subtitleLabel release];
  [subscribeButton release];
  [userInfo release];
  [super dealloc];
}


@end
