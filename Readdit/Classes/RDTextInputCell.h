//
//  RDTextInputCell.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDTextInputCell : UITableViewCell <UITextFieldDelegate>
{
  IBOutlet UITextField *textField;
  IBOutlet id __unsafe_unretained delegate;
}

@property (nonatomic) UITextField *textField;
@property (nonatomic, unsafe_unretained) id delegate;

@end
