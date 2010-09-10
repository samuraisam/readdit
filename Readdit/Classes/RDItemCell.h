//
//  RDItemCell.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDItemCell : UITableViewCell 
{
  IBOutlet UILabel *upvoteLabel, *commentLabel, *infoLabel, *titleLabel;
}

@property(nonatomic, retain) UILabel *upvoteLabel, *commentLabel, *infoLabel, *titleLabel;

@end
