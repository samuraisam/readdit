//
//  RDLoginController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDLoginController : UITableViewController 
{
  IBOutlet id delegate;
  UITextField *usernameField;
  UITextField *passwordField;
}

@property(nonatomic, retain) id delegate;

@end
