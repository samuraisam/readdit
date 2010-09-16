//
//  RDItemCell.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDItemCell : UITableViewCell <UIActionSheetDelegate>
{
  IBOutlet UILabel *upvoteLabel, *commentLabel, *infoLabel, *titleLabel;
  IBOutlet UIImageView *thumbnail;
  BOOL clicked;
  UISwipeGestureRecognizer *swipeRecognizer;
  UIActionSheet *actionSheet;
  id target, userInfo;
  SEL addToPileAction;
}

@property(nonatomic, retain) UILabel *upvoteLabel, *commentLabel, *infoLabel, *titleLabel;
@property(nonatomic, retain) UIImageView *thumbnail;
@property(nonatomic, assign) BOOL clicked;
@property(nonatomic, retain) id target, userInfo;
@property(nonatomic, assign) SEL addToPileAction;

@end
