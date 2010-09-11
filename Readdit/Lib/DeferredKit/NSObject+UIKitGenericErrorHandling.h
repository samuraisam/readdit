//
//  NSObject+UIKitGenericErrorHandling.h
//  Readdit
//
//  Created by Samuel Sutch on 9/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (GenericErrorHandling)

- (BOOL)handleErrorAndAlert:(BOOL)shouldAlert;

@end