//
//  RDItemCell.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDItemCell.h"


@implementation RDItemCell

@synthesize upvoteLabel, commentLabel, infoLabel, titleLabel;

//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
//        // Initialization code
//    }
//    return self;
//}


//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}


- (void)dealloc 
{
  [upvoteLabel release];
  [commentLabel release];
  [infoLabel release];
  [titleLabel release];
  [super dealloc];
}


@end
