//
//  RDPileItem.h
//  Readdit
//
//  Created by Samuel Sutch on 9/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDPileItemCell : UITableViewCell 
{
  IBOutlet UIButton *button, *closeButton;
  IBOutlet UILabel *titleLabel;
  id target, userInfo;
  SEL closeAction;
}

@property(nonatomic) UIButton *button, *closeButton;
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) id target, userInfo;
@property(nonatomic, assign) SEL closeAction;

- (IBAction)close:(id)sender;
- (IBAction)go:(id)sender;

@end
