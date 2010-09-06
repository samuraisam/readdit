//
//  NSString+URLEncoding.m
//  CraigsFish
//
//  Created by Samuel Sutch on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSString+DKDeferred.h"


@implementation NSString (URLEncoding)

- (NSString *)encodedURLString {
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(
   kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
	return result;
}

- (NSString *)encodedURLParameterString {
  NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(
   kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/=,!$&'()*+;[]@#?"), kCFStringEncodingUTF8);
	return result;
}

@end