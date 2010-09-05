//
//  RDRedditClient.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDRedditClient.h"
#import "RegexKitLite.h"


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
  // TODO: multi-user support
  if (PREF_KEY(@"modhash")) {
    return array_(PREF_KEY(@"username"), PREF_KEY(@"modhash"), PREF_KEY(@"cookie"));
  }
  return EMPTY_ARRAY;
} 

- (DKDeferred *)loginUsername:(NSString *)username password:(NSString *)password
{
  NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:
                               [NSURL URLWithString:REDDIT_URL @"api/login"]] autorelease];
  [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  [req setHTTPMethod:@"POST"];
  [req setHTTPBody:
   [[NSString stringWithFormat:@"rem=on&passwd=%@&user=%@&api_type=json", 
     [password stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], 
     [username stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]] 
    dataUsingEncoding:NSASCIIStringEncoding]];
  DKDeferredURLConnection *c = [[[DKDeferredURLConnection alloc] initWithRequest:
                                 req pauseFor:0 decodeFunction:nil] autorelease];
  [c addBoth:curryTS(self, @selector(_didLoginUsername:results:), username)];
  return c;
}

- (id)_didLoginUsername:(NSString *)username results:(id)r
{
  if ([r isKindOfClass:[NSData class]]) {
    id d = [[[[NSString alloc] initWithData:r encoding:
              NSUTF8StringEncoding] autorelease] JSONValue];
    if ([d isKindOfClass:[NSDictionary class]] 
        && [[[d objectForKey:@"json"] objectForKey:@"data"] objectForKey:@"modhash"]) {
      // TODO: multi-user support
      PREF_SET(@"modhash", [[[d objectForKey:@"json"] objectForKey:@"data"]
                            objectForKey:@"modhash"]); // required for editing
      PREF_SET(@"username", username);
      PREF_SET(@"cookie", [[[d objectForKey:@"json"] objectForKey:@"data"]
                           objectForKey:@"cookie"]); // required for personalized pages
      PREF_SYNCHRONIZE;
      [DKDeferred setRestClient:[RDRestClient clientWithURL:REDDIT_URL]];
      [[DKDeferred rest:REDDIT_URL] setUsername:username];
      return @"success";
    }
  }
  return @"failure";
}

@end


@implementation RDRestClient

- (NSDictionary *)authorizeParams:(NSDictionary *)params
{
  if (PREF_KEY(@"modhash") && [[params allKeys] count]) {
    NSMutableDictionary *d = [[params mutableCopy] autorelease];
    [d setObject:PREF_KEY(@"modhash") forKey:@"mh"];
    return d;
  }
  return params;
}

- (void)authorizeRequest:(NSMutableURLRequest *)req
{
  if (PREF_KEY(@"cookie")) {
    [req setValue:PREF_KEY(@"cookie") forHTTPHeaderField:@"Cookie"];
  }
}

@end
