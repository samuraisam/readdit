//
//  NSObject+UIKitGenericErrorHandling.m
//  Readdit
//
//  Created by Samuel Sutch on 9/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSObject+UIKitGenericErrorHandling.h"
#import <UIKit/UIKit.h>


@implementation NSObject (GenericErrorHandling)

- (BOOL)handleErrorAndAlert:(BOOL)shouldAlert
{
  if ([self isKindOfClass:[NSError class]]) {
    if (shouldAlert) {
      NSString *t = [[(NSError *)self userInfo] objectForKey:NSLocalizedDescriptionKey];
      NSError *m = [[(NSError *)self userInfo] objectForKey:NSUnderlyingErrorKey];
      if (!t || ![t length]) t = @"Error";
      t = [t stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:
           [[t substringToIndex:1] uppercaseString]];
      if (!m) m = [NSError errorWithDomain:@"" code:0 userInfo:
                   dict_(@"There was an error completing your request.", 
                         NSLocalizedDescriptionKey)];
      NSString *b = [[m userInfo] objectForKey:NSLocalizedDescriptionKey];
      [[[[UIAlertView alloc] initWithTitle:t message:b delegate:nil cancelButtonTitle:
         @"Dismiss" otherButtonTitles:nil] autorelease] show];
    }
    return YES;
  }
  return NO;
}

@end
