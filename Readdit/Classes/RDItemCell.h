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
}

@property(nonatomic) UILabel *upvoteLabel, *commentLabel, *infoLabel, *titleLabel;
@property(nonatomic) UIImageView *thumbnail;
@property(nonatomic, assign) BOOL clicked;
@property(nonatomic) id target, userInfo;

@end
