//
//  RDTextInputCell.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDTextInputCell.h"


@implementation RDTextInputCell

@synthesize textField, delegate;

//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
//        // Initialization code
//    }
//    return self;
//}
//
//
//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

- (BOOL) textFieldShouldReturn:(UITextField *)field
{
  if (delegate && [delegate respondsToSelector:@selector(nextFieldFromInputCell:)]) {
    [delegate performSelector:@selector(nextFieldFromInputCell:) withObject:self];
  }
  return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)field
{
}



@end
