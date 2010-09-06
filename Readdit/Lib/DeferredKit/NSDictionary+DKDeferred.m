//
//  NSDictionary+DKDeferred.m
//  CraigsFish
//
//  Created by Samuel Sutch on 7/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+DKDeferred.h"
#import "NSString+DKDeferred.h"


@implementation NSDictionary (DeferredAdditions)

- (NSString *)parameterString
{
  NSMutableString *params = [NSMutableString string];
  if ([[self allKeys] count]) {
//    [params setString:@"?"];
    for (NSString *k in [self allKeys]) {
      id v = [self valueForKey:k];
      NSArray *va;
      if ([v isKindOfClass:[NSString class]]) {
        va = array_(v);
      } else if ([v isKindOfClass:[NSArray class]]) {
        va = v;
      }
      for (id s in va) {
        [params appendFormat:@"%@=%@&", [k encodedURLParameterString], 
         [s encodedURLParameterString]];
      }
    }
    if ([params length] > 1)
      [params replaceCharactersInRange:
       NSMakeRange([params length] - 1, 1) withString:@""];
  }
  NSLog(@"parameterString %@", params);
  return [NSString stringWithString:params];
}

@end
