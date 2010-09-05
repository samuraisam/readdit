//
//  NSString+URLEncoding.h
//  CraigsFish
//
//  Created by Samuel Sutch on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (URLEncoding)

- (NSString *)encodedURLString;
- (NSString *)encodedURLParameterString;

@end
