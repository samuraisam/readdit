//
//  RDItemCell.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDItemCell.h"
#import <QuartzCore/QuartzCore.h>


@implementation RDItemCell

@synthesize upvoteLabel, commentLabel, infoLabel, titleLabel, thumbnail;
@synthesize clicked, target, userInfo;

//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
//        // Initialization code
//    }
//    return self;
//}

static UIColor *upvoteColor = nil;
static UIColor *commentColor = nil;
static UIColor *infoColor = nil;
static UIColor *titleColor = nil;
static UIColor *clickedTitleColor = nil;

+ (void)initialize
{
  if (!upvoteColor) upvoteColor = [UIColor colorWithRed:172.0/255.0 green:81.0/255.0 blue:14.0/255.0 alpha:1];
  if (!commentColor) commentColor = [UIColor colorWithWhite:.37 alpha:1.0];
  if (!infoColor) infoColor = [UIColor colorWithRed:31.0/255.0 green:50.0/255.0 blue:79.0/255.0 alpha:1.0];
  if (!titleColor) titleColor = [UIColor blackColor];
  if (!clickedTitleColor) clickedTitleColor = [UIColor colorWithRed:57.0/255.0 green:0 blue:98.0/255.0 alpha:1];
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
  if (actionSheet) return;
  actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:
                 nil destructiveButtonTitle:nil otherButtonTitles:@"Add to Pile", nil];
  [actionSheet showFromRect:self.frame inView:self.superview animated:YES];
}

- (void)actionSheet:(UIActionSheet *)as didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 0) {
    if (target) [target performSelector:@selector(addToPileCell:) withObject:self];
  }
  actionSheet = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
  [super setSelected:selected animated:animated];
  if (!selected) {
    upvoteLabel.textColor = upvoteColor;
    commentLabel.textColor = commentColor;
    infoLabel.textColor = infoColor;
    titleLabel.textColor = !clicked ? titleColor : clickedTitleColor;
    upvoteLabel.layer.shadowColor = commentLabel.layer.shadowColor = infoLabel.layer.shadowColor = titleLabel.layer.shadowColor = [UIColor clearColor].CGColor;
    upvoteLabel.layer.shadowRadius = commentLabel.layer.shadowRadius = infoLabel.layer.shadowRadius = titleLabel.layer.shadowRadius = 0;
    upvoteLabel.layer.shadowOpacity = commentLabel.layer.shadowOpacity = infoLabel.layer.shadowOpacity = titleLabel.layer.shadowOpacity = 0;
  } else {
    upvoteLabel.textColor = commentLabel.textColor = infoLabel.textColor = titleLabel.textColor = [UIColor whiteColor];
    upvoteLabel.layer.shadowColor = commentLabel.layer.shadowColor = infoLabel.layer.shadowColor = titleLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
    upvoteLabel.layer.shadowRadius = commentLabel.layer.shadowRadius = infoLabel.layer.shadowRadius = titleLabel.layer.shadowRadius = 2;
    upvoteLabel.layer.shadowOpacity = commentLabel.layer.shadowOpacity = infoLabel.layer.shadowOpacity = titleLabel.layer.shadowOpacity = .5;
  }
}

- (void)prepareForReuse
{
  if (!swipeRecognizer) {
    swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                          action:@selector(handleGesture:)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:swipeRecognizer];
  }
  self.clicked = NO;
  [super prepareForReuse];
}

- (void)setClicked:(BOOL)c
{
  if (clicked != c) {
    if (clicked && self.selected) titleLabel.textColor = [UIColor whiteColor];
    else titleLabel.textColor = c ? clickedTitleColor : titleColor;
  }
  clicked = c;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  CGRect s = titleLabel.frame;
  s.origin.x = 54;
  s.origin.y = 7;
  CGSize constraint = CGSizeMake(self.frame.size.width
                                 -67 - (thumbnail != nil ? 70 : 0), 1000);
  s.size.height = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:
                   constraint lineBreakMode:UILineBreakModeWordWrap].height;
  s.size.width = self.frame.size.width - 67 - (thumbnail != nil ? 70 : 0);
  titleLabel.frame = s;
}



@end
