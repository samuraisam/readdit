//
//  RDPileItem.m
//  Readdit
//
//  Created by Samuel Sutch on 9/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDPileItemCell.h"

static UIImage *selectedBackgroundImage = nil;
static UIImage *backgroundImage = nil;

@implementation RDPileItemCell

@synthesize button, closeButton, titleLabel, userInfo, target, closeAction;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
  NSLog(@"init with style");
  if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  NSLog(@"init with coder");
  if ((self = [super initWithCoder:aDecoder])) {
    [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
  }
  return self;
}

+ (void)initialize
{
  if (!selectedBackgroundImage) selectedBackgroundImage = [[[UIImage imageNamed:@"selectedpileitem.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] retain];
  if (!backgroundImage) backgroundImage = [[[UIImage imageNamed:@"pileitem.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] retain];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
  closeButton.hidden = !selected;
  [button setBackgroundImage:(selected ? selectedBackgroundImage : backgroundImage) forState:UIControlStateNormal];
  [super setSelected:selected animated:animated];
}

- (void)go:(id)sender
{
  //if (target) [target performSelector:selectAction withObject:self];
}

- (void)close:(id)sender
{
  if (target) [target performSelector:closeAction withObject:self];
}

- (void)dealloc 
{
  [target release];
  [userInfo release];
  [titleLabel release];
  [closeButton release];
  [button release];
  [super dealloc];
}


@end
