//
//  RDRedditClient.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDRedditClient.h"


@implementation RDRedditClient

+ (id)sharedClient
{
  static id sharedClient = nil;
  if (!sharedClient) {
    sharedClient = [[[self class] alloc] init];
  }
  return sharedClient;
}

- (NSArray *)accounts
{
  if (PREF_KEY(@"cookie")) {
    return array_(PREF_KEY(@"username"), PREF_KEY(@"cookie"));
  }
  return EMPTY_ARRAY;
}

- (DKDeferred *)loginUsername:(NSString *)username password:(NSString *)password
{
  
}

@end
